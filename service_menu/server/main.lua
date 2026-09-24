local ESX = nil

if Config.UseESX then
    TriggerEvent(Config.ESXExport, function(obj) ESX = obj end)
    if ESX == nil then
        pcall(function() ESX = exports['es_extended']:getSharedObject() end)
    end
end

-- Helper to remove blacklisted items & weapons
local function StripBlacklistItems(xPlayer, src)
    if not Config.BlacklistItems then return end

    for _, itemName in ipairs(Config.BlacklistItems) do
        if string.sub(string.upper(itemName), 1, 7) == 'WEAPON_' then
            -- Remove weapon if player has it
            if xPlayer and xPlayer.hasWeapon and xPlayer.hasWeapon(itemName) then
                pcall(function() xPlayer.removeWeapon(itemName) end)
            end
            -- Fallback native removal for safety
            local ped = GetPlayerPed(src)
            if ped and ped ~= 0 then
                RemoveWeaponFromPed(ped, GetHashKey(itemName))
            end
        else
            -- Remove inventory item
            if xPlayer and xPlayer.getInventoryItem then
                local item = xPlayer.getInventoryItem(itemName)
                if item and item.count and item.count > 0 then
                    pcall(function() xPlayer.removeInventoryItem(itemName, item.count) end)
                end
            end
            -- Try ox_inventory if installed
            pcall(function()
                if exports.ox_inventory then
                    local count = exports.ox_inventory:GetItemCount(src, itemName)
                    if count and count > 0 then
                        exports.ox_inventory:RemoveItem(src, itemName, count)
                    end
                end
            end)
        end
    end
end

-- Server Event: Select Team
RegisterNetEvent('team_selector:server:selectTeam', function(teamId, doTeleport)
    local src = source
    local xPlayer = nil

    if ESX then
        xPlayer = ESX.GetPlayerFromId(src)
    end

    -- Find team configuration
    local targetTeam = nil
    for _, team in ipairs(Config.Teams) do
        if team.id == teamId then
            targetTeam = team
            break
        end
    end

    if not targetTeam then return end

    -- 1. Strip blacklisted items from previous team
    StripBlacklistItems(xPlayer, src)

    -- 2. Update Job & Grade
    if xPlayer then
        pcall(function()
            xPlayer.setJob(targetTeam.job, targetTeam.grade or 0)
        end)
    end

    -- 3. Give new team items & weapons
    if targetTeam.items and #targetTeam.items > 0 then
        for _, item in ipairs(targetTeam.items) do
            if item.type == 'weapon' or string.sub(string.upper(item.name), 1, 7) == 'WEAPON_' then
                if xPlayer and xPlayer.addWeapon then
                    pcall(function() xPlayer.addWeapon(item.name, 250) end)
                else
                    local ped = GetPlayerPed(src)
                    if ped and ped ~= 0 then
                        GiveWeaponToPed(ped, GetHashKey(item.name), 250, false, true)
                    end
                end
            else
                if xPlayer and xPlayer.addInventoryItem then
                    pcall(function() xPlayer.addInventoryItem(item.name, item.count or 1) end)
                end
                pcall(function()
                    if exports.ox_inventory then
                        exports.ox_inventory:AddItem(src, item.name, item.count or 1)
                    end
                end)
            end
        end
    end

    -- 4. Trigger client side teleport & notification
    TriggerClientEvent('team_selector:client:teamSelected', src, targetTeam, doTeleport)
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Team Map Blips Sync
-- ─────────────────────────────────────────────────────────────────────────────
local playerTeams = {}

RegisterNetEvent('team_selector:server:selectTeam')
AddEventHandler('team_selector:server:selectTeam', function(teamId)
    local src = source
    if teamId == 'civil' then
        playerTeams[src] = nil
    else
        playerTeams[src] = teamId
    end
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    if playerTeams[src] then
        playerTeams[src] = nil
    end
end)

CreateThread(function()
    while true do
        Wait(2000) -- Update every 2 seconds

        -- Gather all players in a team and their coords
        local syncData = {}
        local hasData = false

        for src, teamId in pairs(playerTeams) do
            local ped = GetPlayerPed(src)
            if ped and ped ~= 0 then
                local coords = GetEntityCoords(ped)
                syncData[src] = {
                    team = teamId,
                    coords = coords
                }
                hasData = true
            end
        end

        -- Only broadcast if there are people in teams
        if hasData then
            TriggerClientEvent('team_selector:client:syncBlips', -1, syncData)
        end
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Faction Rivalry Counter & Scoreboard System
-- ─────────────────────────────────────────────────────────────────────────────
local rivalryScores = {}

-- Initialize rivalry scores from Config.Teams
local function InitRivalryScores()
    for _, team in ipairs(Config.Teams) do
        if team.id ~= 'civil' then
            rivalryScores[team.id] = {
                id = team.id,
                name = team.name,
                color = team.color or '#3b82f6',
                colorGlow = team.colorGlow or 'rgba(59, 130, 246, 0.4)',
                kills = 0
            }
        end
    end
end

InitRivalryScores()

local function GetRivalryScoresFormatted()
    local list = {}
    for _, team in ipairs(Config.Teams) do
        if team.id ~= 'civil' and rivalryScores[team.id] then
            table.insert(list, rivalryScores[team.id])
        end
    end
    return list
end

-- Broadcast updated rivalry scores to all clients
local function BroadcastRivalryScores()
    TriggerClientEvent('team_selector:client:updateRivalry', -1, GetRivalryScoresFormatted())
end

-- Register Kill Event (called when a player kills an opponent)
RegisterNetEvent('team_selector:server:registerKill', function(killerSrc, victimSrc)
    local kSrc = killerSrc or source
    local vSrc = victimSrc
    local killerTeam = playerTeams[kSrc]
    local victimTeam = playerTeams[vSrc]

    if killerTeam and victimTeam and killerTeam ~= 'civil' and victimTeam ~= 'civil' and killerTeam ~= victimTeam then
        if rivalryScores[killerTeam] then
            rivalryScores[killerTeam].kills = rivalryScores[killerTeam].kills + 1
            BroadcastRivalryScores()

            -- Broadcast Kill Feed Notification in chat
            local killerName = GetPlayerName(kSrc) or 'Agente'
            local victimName = GetPlayerName(vSrc) or 'Enemigo'
            local kTeamObj = nil
            local vTeamObj = nil
            for _, t in ipairs(Config.Teams) do
                if t.id == killerTeam then kTeamObj = t end
                if t.id == victimTeam then vTeamObj = t end
            end
            local kNameStr = kTeamObj and kTeamObj.name or string.upper(killerTeam)
            local vNameStr = vTeamObj and vTeamObj.name or string.upper(victimTeam)
            local msg = string.format("⚔️ %s (%s) eliminó a %s (%s) [+1 PTS]", killerName, kNameStr, victimName, vNameStr)

            TriggerClientEvent('chat:addMessage', -1, {
                color = { 255, 200, 0 },
                multiline = true,
                args = { "RIVALIDAD", msg }
            })
        end
    end
end)

-- Admin command to reset rivalry scores
RegisterCommand('resetrivalry', function(source, args, rawCommand)
    local src = source
    local isAdmin = false
    if src == 0 then
        isAdmin = true
    else
        local identifiers = GetPlayerIdentifiers(src)
        for _, id in ipairs(identifiers) do
            for _, adminId in ipairs(Config.Admins or {}) do
                if string.lower(id) == string.lower(adminId) then
                    isAdmin = true
                    break
                end
            end
        end
    end

    if isAdmin then
        InitRivalryScores()
        BroadcastRivalryScores()
        TriggerClientEvent('chat:addMessage', -1, {
            color = { 0, 255, 120 },
            multiline = true,
            args = { "RIVALIDAD", "El marcador de rivalidad de facciones ha sido reiniciado." }
        })
    end
end, false)

-- Broadcast initial scores on player loaded
RegisterNetEvent('team_selector:server:syncRivalryOnJoin', function()
    local src = source
    TriggerClientEvent('team_selector:client:updateRivalry', src, GetRivalryScoresFormatted())
end)
