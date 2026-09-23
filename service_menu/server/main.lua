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
