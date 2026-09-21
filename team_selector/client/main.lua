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
            SpawnPedAtCoords(team.baseNPC.model, team.baseNPC.coords, team.baseNPC.scenario)
            if team.baseNPC.blip and team.baseNPC.blip.enabled then
                CreateBlipAtCoords(team.baseNPC.coords, team.baseNPC.blip.sprite, team.baseNPC.blip.color, team.baseNPC.blip.scale, team.baseNPC.blip.text)
            end
        end
    end
end)

-- Open NUI UI
local function OpenTeamUI()
    if isUIOpen then return end
    isUIOpen = true
    SetNuiFocus(true, true)

    local currentJob = 'unemployed'
    if ESX and ESX.GetPlayerData and ESX.GetPlayerData().job then
        currentJob = ESX.GetPlayerData().job.name
    end

    SendNUIMessage({
        action = 'openUI',
        teams = Config.Teams,
        locales = Config.Locales,
        currentJob = currentJob
    })
end

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
        TriggerServerEvent('team_selector:server:selectTeam', data.teamId)
    end
    CloseTeamUI()
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
RegisterNetEvent('team_selector:client:teamSelected', function(teamData)
    local playerPed = PlayerPedId()

    -- Do screen fade out/in for smooth teleport
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(10) end

    -- Set Position & Heading
    SetEntityCoords(playerPed, teamData.spawnCoords.x, teamData.spawnCoords.y, teamData.spawnCoords.z, false, false, false, false)
    SetEntityHeading(playerPed, teamData.spawnCoords.w)
    Wait(200)

    DoScreenFadeIn(500)

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
end)
