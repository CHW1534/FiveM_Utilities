local ESX = nil
local spawnedPeds = {}
local spawnedBlips = {}
local isUIOpen = false

-- ESX Initialization
CreateThread(function()
    if Config.UseESX then
        while ESX == nil do
            TriggerEvent(Config.ESXExport, function(obj) ESX = obj end)
            if ESX == nil then
                pcall(function() ESX = exports['es_extended']:getSharedObject() end)
            end
            Wait(100)
        end
    end
end)

-- Helper: Helper function for 3D Text rendering
local function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 140)
    ClearDrawOrigin()
end

-- Function to spawn an NPC ped
local function SpawnPedAtCoords(modelName, coords, scenario, animDict, animName)
    local modelHash = GetHashKey(modelName)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(10)
    end

    local ped = CreatePed(4, modelHash, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
    SetEntityHeading(ped, coords.w)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    if scenario and scenario ~= '' then
        TaskStartScenarioInPlace(ped, scenario, 0, true)
    elseif animDict and animName then
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Wait(10)
        end
        TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
    end

    SetModelAsNoLongerNeeded(modelHash)
    table.insert(spawnedPeds, ped)
    return ped
end

-- Create Blip helper
local function CreateBlipAtCoords(coords, sprite, color, scale, text)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, scale or 0.8)
    SetBlipColour(blip, color or 3)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(text)
    EndTextCommandSetBlipName(blip)
    table.insert(spawnedBlips, blip)
    return blip
end

-- Initialize NPCs and Blips
CreateThread(function()
    Wait(500)
    -- Main NPC
    if Config.MainNPC then
        SpawnPedAtCoords(Config.MainNPC.model, Config.MainNPC.coords, Config.MainNPC.scenario, Config.MainNPC.animDict, Config.MainNPC.animName)
        if Config.MainNPC.blip and Config.MainNPC.blip.enabled then
            CreateBlipAtCoords(Config.MainNPC.coords, Config.MainNPC.blip.sprite, Config.MainNPC.blip.color, Config.MainNPC.blip.scale, Config.MainNPC.blip.text)
        end
    end

    -- Base NPCs for Teams
    for _, team in ipairs(Config.Teams) do
        if team.baseNPC then
            local ped = SpawnPedAtCoords(team.baseNPC.model, team.baseNPC.coords, team.baseNPC.scenario)
            
            -- Asignar el NPC al grupo de la facción
            local groupName = 'TEAM_' .. string.upper(team.id)
            local groupHash = GetHashKey(groupName)
            AddRelationshipGroup(groupName)
            SetPedRelationshipGroupHash(ped, groupHash)
            
            -- Asegurar que los miembros del mismo equipo sean compañeros (0)
            SetRelationshipBetweenGroups(0, groupHash, groupHash)
            SetCanAttackFriendly(ped, false, false)
            
            -- Atributos para ignorar provocaciones y fuego amigo
            SetPedCombatAttributes(ped, 5, true) -- No huir si están desarmados
            SetPedCombatAttributes(ped, 46, true) -- Siempre pelear con enemigos
            
            -- Hacer que el guardia odie a los otros equipos
            for _, otherTeam in ipairs(Config.Teams) do
                if otherTeam.id ~= team.id and otherTeam.id ~= 'civil' then
                    local otherGroupName = 'TEAM_' .. string.upper(otherTeam.id)
                    local otherGroupHash = GetHashKey(otherGroupName)
                    AddRelationshipGroup(otherGroupName)
                    SetRelationshipBetweenGroups(5, groupHash, otherGroupHash)
                    SetRelationshipBetweenGroups(5, otherGroupHash, groupHash)
                end
            end

            if team.baseNPC.blip and team.baseNPC.blip.enabled then
                CreateBlipAtCoords(team.baseNPC.coords, team.baseNPC.blip.sprite, team.baseNPC.blip.color, team.baseNPC.blip.scale, team.baseNPC.blip.text)
            end
        end
    end
end)

local currentTeamId = 'civil'

-- Open NUI UI
local function OpenTeamUI()
    if isUIOpen then return end
    isUIOpen = true
    SetNuiFocus(true, true)

    local currentJob = currentTeamId
    if ESX and ESX.GetPlayerData and ESX.GetPlayerData().job then
        currentJob = ESX.GetPlayerData().job.name
    end

    SendNUIMessage({
        action = 'openUI',
        teams = Config.Teams,
        locales = Config.Locales,
        currentJob = currentJob,
        currentTeamId = currentTeamId,
        bodyguardTiers = Config.BodyguardTiers
    })
end

RegisterNetEvent('team_selector:client:openUI', function()
    OpenTeamUI()
end)

-- Command and Keybind moved to menu.lua

-- Close NUI UI
local function CloseTeamUI()
    isUIOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeUI' })
end

RegisterNUICallback('closeUI', function(data, cb)
    CloseTeamUI()
    cb('ok')
end)

RegisterNUICallback('selectTeam', function(data, cb)
    if data and data.teamId then
        local doTeleport = data.teleport
        if doTeleport == nil then doTeleport = true end -- Default to true if not provided
        TriggerServerEvent('team_selector:server:selectTeam', data.teamId, doTeleport)
    end
    CloseTeamUI()
    cb('ok')
end)

RegisterNUICallback('spawnBodyguard', function(data, cb)
    if data and data.tier then
        TriggerServerEvent('bodyguard:server:purchase', data.tier)
    end
    cb('ok')
end)

RegisterNUICallback('dismissBodyguards', function(data, cb)
    DismissAll()
    cb('ok')
end)

-- Distance & Key press loop
CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        -- Check distance to Main NPC
        if Config.MainNPC then
            local mainCoords = vector3(Config.MainNPC.coords.x, Config.MainNPC.coords.y, Config.MainNPC.coords.z)
            local dist = #(playerCoords - mainCoords)

            if dist < Config.MainNPC.drawDistance then
                sleep = 0
                if dist < Config.MainNPC.interactDistance then
                    DrawText3D(mainCoords.x, mainCoords.y, mainCoords.z + 1.0, Config.Locales.pressE)
                    if IsControlJustReleased(0, 38) then -- Key E
                        OpenTeamUI()
                    end
                end
            end
        end

        -- Check distance to Secondary Base NPCs
        for _, team in ipairs(Config.Teams) do
            if team.baseNPC then
                local baseCoords = vector3(team.baseNPC.coords.x, team.baseNPC.coords.y, team.baseNPC.coords.z)
                local dist = #(playerCoords - baseCoords)

                if dist < 10.0 then
                    sleep = 0
                    if dist < 2.5 then
                        DrawText3D(baseCoords.x, baseCoords.y, baseCoords.z + 1.0, Config.Locales.changeTeamNPC)
                        if IsControlJustReleased(0, 38) then -- Key E
                            OpenTeamUI()
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- Client Event: Team Selected (Teleport & Notify)
RegisterNetEvent('team_selector:client:teamSelected', function(teamData, doTeleport)
    local playerPed = PlayerPedId()

    if doTeleport then
        -- Do screen fade out/in for smooth teleport
        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do Wait(10) end

        -- Set Position & Heading
        SetEntityCoords(playerPed, teamData.spawnCoords.x, teamData.spawnCoords.y, teamData.spawnCoords.z, false, false, false, false)
        SetEntityHeading(playerPed, teamData.spawnCoords.w)
        Wait(200)
    end

    -- Update current team state
    currentTeamId = teamData.id

    -- Update Minimap Team HUD Badge
    SendNUIMessage({
        action = 'updateTeamHUD',
        visible = showTeamHUD,
        teamName = (teamData.id ~= 'civil' and teamData.name) or nil,
        color = teamData.color or '#9ca3af',
        colorGlow = teamData.colorGlow or 'rgba(156, 163, 175, 0.6)'
    })

    -- Strip blacklisted weapons from ped
    if Config.BlacklistItems then
        for _, itemName in ipairs(Config.BlacklistItems) do
            if string.sub(string.upper(itemName), 1, 7) == 'WEAPON_' then
                RemoveWeaponFromPed(playerPed, GetHashKey(itemName))
            end
        end
    end

    -- Set up Relationship Group to ensure different teams can shoot each other
    local groupName = 'TEAM_' .. string.upper(currentTeamId)
    local groupHash = GetHashKey(groupName)
    AddRelationshipGroup(groupName)
    SetPedRelationshipGroupHash(playerPed, groupHash)

    -- Make them hate other teams dynamically based on Config
    for _, otherTeam in ipairs(Config.Teams) do
        if otherTeam.id ~= currentTeamId and otherTeam.id ~= 'civil' then
            local otherGroupName = 'TEAM_' .. string.upper(otherTeam.id)
            local otherGroupHash = GetHashKey(otherGroupName)
            AddRelationshipGroup(otherGroupName)
            SetRelationshipBetweenGroups(5, groupHash, otherGroupHash)
            SetRelationshipBetweenGroups(5, otherGroupHash, groupHash)
        end
    end

    -- Allow friendly fire globally just in case
    NetworkSetFriendlyFireOption(true)
    SetCanAttackFriendly(playerPed, true, false)

    if doTeleport then
        DoScreenFadeIn(500)
    end

    -- Display Notification
    if teamData.id == 'civil' then
        if ESX and ESX.ShowNotification then
            ESX.ShowNotification(Config.Locales.civilSelectedNotify)
        else
            SetNotificationTextEntry('STRING')
            AddTextComponentString(Config.Locales.civilSelectedNotify)
            DrawNotification(false, true)
        end
    else
        local msg = string.format(Config.Locales.teamSelectedNotify, teamData.name)
        if ESX and ESX.ShowNotification then
            ESX.ShowNotification(msg)
        else
            SetNotificationTextEntry('STRING')
            AddTextComponentString(msg)
            DrawNotification(false, true)
        end
    end
end)

-- Thread to force vulnerability and disable admin God Mode in combat teams
CreateThread(function()
    while true do
        if currentTeamId ~= 'civil' then
            local ped = PlayerPedId()
            local pid = PlayerId()
            
            -- Force vulnerability
            SetEntityInvincible(ped, false)
            SetPlayerInvincible(pid, false)
            SetEntityProofs(ped, false, false, false, false, false, false, false, false)
            
            -- Wait(0) ensures this overrides other admin scripts trying to set invincibility
            Wait(0)
        else
            Wait(1000)
        end
    end
end)

-- Cleanup on Resource Stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    for _, blip in ipairs(spawnedBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    for _, blip in pairs(teamBlips or {}) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Team Map Blips Sync
-- ─────────────────────────────────────────────────────────────────────────────
local teamBlips = {}
local showTeammatesOnMap = true

RegisterNetEvent('team_selector:client:toggleBlips', function()
    showTeammatesOnMap = not showTeammatesOnMap
    if showTeammatesOnMap then
        SetNotificationTextEntry('STRING')
        AddTextComponentString('~g~Radar de compañeros activado.')
        DrawNotification(false, true)
    else
        SetNotificationTextEntry('STRING')
        AddTextComponentString('~r~Radar de compañeros desactivado.')
        DrawNotification(false, true)
        
        -- Clean up existing blips immediately
        for k, blip in pairs(teamBlips) do
            if DoesBlipExist(blip) then RemoveBlip(blip) end
        end
        teamBlips = {}
    end
end)

RegisterNetEvent('team_selector:client:syncBlips', function(syncData)
    -- If we are in 'civil', or have toggled off the radar, remove all team blips
    if currentTeamId == 'civil' or not showTeammatesOnMap then
        for k, blip in pairs(teamBlips) do
            if DoesBlipExist(blip) then RemoveBlip(blip) end
        end
        teamBlips = {}
        return
    end

    local mySrc = GetPlayerServerId(PlayerId())
    local activeBlips = {}

    for src, data in pairs(syncData) do
        local srcNum = tonumber(src) or src
        -- Only show players in our same team, excluding ourselves
        if srcNum ~= mySrc and data.team == currentTeamId then
            activeBlips[srcNum] = true

            if not teamBlips[srcNum] then
                -- Determine team color
                local bColor = 0 -- White default
                if data.team == 'pochas' then bColor = 3 -- Blue
                elseif data.team == 'yomas' then bColor = 1 -- Red
                elseif data.team == 'gn' then bColor = 2 -- Green
                elseif data.team == 'ancla' then bColor = 27 -- Purple
                end

                -- Create new blip
                local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
                SetBlipSprite(blip, 119) -- Ally/Friend icon (Circle with a star/cross)
                SetBlipColour(blip, bColor)
                SetBlipScale(blip, 0.85)
                SetBlipAsShortRange(blip, true)
                SetBlipCategory(blip, 7) -- Player category
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString("Compañero (" .. string.upper(data.team) .. ")")
                EndTextCommandSetBlipName(blip)
                teamBlips[srcNum] = blip
            else
                -- Update existing blip coords
                SetBlipCoords(teamBlips[srcNum], data.coords.x, data.coords.y, data.coords.z)
            end
        end
    end

    -- Clean up disconnected or team-switched players
    for srcNum, blip in pairs(teamBlips) do
        if not activeBlips[srcNum] then
            if DoesBlipExist(blip) then RemoveBlip(blip) end
            teamBlips[srcNum] = nil
        end
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Minimap Team HUD & Faction Rivalry Counter Client Logic
-- ─────────────────────────────────────────────────────────────────────────────
local showTeamHUD = true
local showRivalryHUD = true
local cachedRivalryScores = {}

-- Initial sync request on player spawn
CreateThread(function()
    Wait(2000)
    TriggerServerEvent('team_selector:server:syncRivalryOnJoin')
    -- Default initial team HUD update
    SendNUIMessage({
        action = 'updateTeamHUD',
        visible = showTeamHUD,
        teamName = nil,
        color = '#9ca3af',
        colorGlow = 'rgba(156, 163, 175, 0.6)'
    })
end)

-- Receive Rivalry score update from server
RegisterNetEvent('team_selector:client:updateRivalry', function(scores)
    cachedRivalryScores = scores or {}
    SendNUIMessage({
        action = 'updateRivalry',
        visible = showRivalryHUD,
        scores = cachedRivalryScores
    })
end)

-- Toggle Minimap Team HUD command
RegisterCommand('teamhud', function()
    showTeamHUD = not showTeamHUD
    local targetTeamObj = nil
    for _, t in ipairs(Config.Teams) do
        if t.id == currentTeamId then targetTeamObj = t end
    end
    SendNUIMessage({
        action = 'updateTeamHUD',
        visible = showTeamHUD,
        teamName = (targetTeamObj and targetTeamObj.id ~= 'civil' and targetTeamObj.name) or nil,
        color = targetTeamObj and targetTeamObj.color or '#9ca3af',
        colorGlow = targetTeamObj and targetTeamObj.colorGlow or 'rgba(156, 163, 175, 0.6)'
    })
    SetNotificationTextEntry('STRING')
    AddTextComponentString(showTeamHUD and '~g~Placa de bando en minimapa activada.' or '~r~Placa de bando en minimapa desactivada.')
    DrawNotification(false, true)
end, false)

-- Toggle Rivalry Scoreboard HUD command
RegisterCommand('rivalry', function()
    showRivalryHUD = not showRivalryHUD
    SendNUIMessage({
        action = 'updateRivalry',
        visible = showRivalryHUD,
        scores = cachedRivalryScores
    })
    SetNotificationTextEntry('STRING')
    AddTextComponentString(showRivalryHUD and '~g~Contador de rivalidad activado.' or '~r~Contador de rivalidad desactivado.')
    DrawNotification(false, true)
end, false)

RegisterCommand('scores', function()
    ExecuteCommand('rivalry')
end, false)

-- Track player kills for Faction Rivalry Counter
AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' then
        local victim = args[1]
        local attacker = args[2]
        local isFatal = (args[6] == 1)

        -- If player is the attacker and victim is a player who died
        if isFatal and attacker == PlayerPedId() and victim ~= PlayerPedId() and IsPedAPlayer(victim) then
            local victimPlayerId = NetworkGetPlayerIndexFromPed(victim)
            if victimPlayerId and victimPlayerId ~= -1 then
                local victimServerId = GetPlayerServerId(victimPlayerId)
                local killerServerId = GetPlayerServerId(PlayerId())
                TriggerServerEvent('team_selector:server:registerKill', killerServerId, victimServerId)
            end
        end
    end
end)
