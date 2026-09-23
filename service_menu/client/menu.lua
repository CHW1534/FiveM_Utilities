-- ═══════════════════════════════════════════════════════════════════════════════
-- BodyGuard — Client Menu
-- Menú principal + Panel Admin NUI
-- ═══════════════════════════════════════════════════════════════════════════════

local menuOpen  = false
local isAdmin   = false

-- ─────────────────────────────────────────────────────────────────────────────
-- Build menu data
-- ─────────────────────────────────────────────────────────────────────────────
local function buildMenuData()
    local guards = {}
    local vehicles = {}

    for _, t in ipairs(Config.BodyguardTiers) do
        table.insert(guards, {
            id          = t.id,
            label       = t.label,
            description = t.description,
            health      = t.health,
            armor       = t.armor or 0,
            accuracy    = t.accuracy or 50,
            weapon      = t.weapon,
            category    = 'tier',
        })
    end

    for _, c in ipairs(Config.CustomBodyguards) do
        table.insert(guards, {
            id          = c.id,
            label       = c.label,
            description = c.description,
            health      = c.health,
            armor       = c.armor or 0,
            accuracy    = c.accuracy or 50,
            weapon      = c.weapon,
            category    = 'custom',
        })
    end

    for _, v in ipairs(Config.EscortVehicles) do
        table.insert(vehicles, {
            id          = v.id,
            label       = v.label,
            description = v.description,
            category    = 'preset',
        })
    end

    for _, v in ipairs(Config.CustomVehicles) do
        table.insert(vehicles, {
            id          = v.id,
            label       = v.label,
            description = v.description,
            category    = 'custom',
        })
    end

    local active, max = GetGuardCount()

    return {
        guards       = guards,
        vehicles     = vehicles,
        maxGuards    = max,
        activeGuards = active,
        isAdmin      = isAdmin,
        mapEvents    = Config.MapEvents or {},
    }
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Open / Close
-- ─────────────────────────────────────────────────────────────────────────────
local lastToggle = 0

function OpenMenu()
    if menuOpen or (GetGameTimer() - lastToggle < 300) then return end
    menuOpen = true
    lastToggle = GetGameTimer()

    local data    = buildMenuData()
    data.action   = 'openMenu'

    SendNUIMessage(data)
    SetNuiFocus(true, true)
end

function CloseMenu()
    if not menuOpen or (GetGameTimer() - lastToggle < 300) then return end
    menuOpen = false
    lastToggle = GetGameTimer()
    
    SendNUIMessage({ action = 'closeMenu' })
    SetNuiFocus(false, false)
end

function OpenAdminPanel()
    if menuOpen then return end

    -- Verificar si es admin
    TriggerServerEvent('bodyguard:server:checkAdmin')
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Server Callbacks
-- ─────────────────────────────────────────────────────────────────────────────

RegisterNUICallback('selectMapEvent', function(data, cb)
    local eventId = data.id
    print("NUI Callback selectMapEvent triggered for: " .. tostring(eventId))
    
    if Config.MapEvents then
        for _, evt in ipairs(Config.MapEvents) do
            if evt.id == eventId then
                -- Cerramos el menú primero para asegurar que no se trabe
                CloseMenu()
                
                local coords = evt.coords
                print("Teleporting to: " .. tostring(coords))
                
                -- Teleport
                local ped = PlayerPedId()
                SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
                
                TriggerEvent('chat:addMessage', {
                    color = {255, 255, 255},
                    multiline = true,
                    args = {"Sistema", "^2Te has teletransportado a: " .. evt.label}
                })
                break
            end
        end
    else
        print("Error: Config.MapEvents is nil")
    end
    cb('ok')
end)

-- Crear Blips en el mapa principal para los eventos
Citizen.CreateThread(function()
    if Config.MapEvents then
        for _, evt in ipairs(Config.MapEvents) do
            if evt.badge == 'ONLINE' then
                local blip = AddBlipForCoord(evt.coords.x, evt.coords.y, evt.coords.z)
                SetBlipSprite(blip, 315) -- Icono de coche/carrera
                SetBlipDisplay(blip, 4)
                SetBlipScale(blip, 0.8)
                SetBlipColour(blip, 3) -- Azul
                SetBlipAsShortRange(blip, true)
                
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString("Circuito: " .. evt.label)
                EndTextCommandSetBlipName(blip)
            end
        end
    end
end)

-- Resultado de check admin
RegisterNetEvent('bodyguard:client:adminResult', function(result)
    isAdmin = result
    if result then
        -- Es admin, pedir lista de jugadores y abrir panel
        TriggerServerEvent('bodyguard:server:getPlayers')
    else
        SetNotificationTextEntry('STRING')
        AddTextComponentSubstringPlayerName(Config.Locales.notAdmin)
        DrawNotification(false, true)
    end
end)

-- Recibir lista de jugadores
RegisterNetEvent('bodyguard:client:playerList', function(players)
    if not isAdmin then return end
    menuOpen = true
    SendNUIMessage({
        action  = 'openAdmin',
        players = players,
    })
    SetNuiFocus(true, true)
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- NUI Callbacks
-- ─────────────────────────────────────────────────────────────────────────────
RegisterNUICallback('closeMenu', function(data, cb)
    CloseMenu()
    cb('ok')
end)

RegisterNUICallback('openTeamSelector', function(data, cb)
    CloseMenu()
    TriggerEvent('team_selector:client:openUI')
    cb('ok')
end)

RegisterNUICallback('toggleTeammateRadar', function(data, cb)
    CloseMenu()
    TriggerEvent('team_selector:client:toggleBlips')
    cb('ok')
end)

RegisterNUICallback('buyGuard', function(data, cb)
    local itemId = data.id
    for _, t in ipairs(Config.BodyguardTiers) do
        if t.id == itemId then
            RequestGuardPurchase(t)
            cb('ok')
            return
        end
    end
    for _, c in ipairs(Config.CustomBodyguards) do
        if c.id == itemId then
            RequestGuardPurchase(c)
            cb('ok')
            return
        end
    end
    cb('not_found')
end)

RegisterNUICallback('buyVehicle', function(data, cb)
    local itemId = data.id
    for _, v in ipairs(Config.EscortVehicles) do
        if v.id == itemId then
            RequestVehiclePurchase(v)
            cb('ok')
            return
        end
    end
    for _, v in ipairs(Config.CustomVehicles) do
        if v.id == itemId then
            RequestVehiclePurchase(v)
            cb('ok')
            return
        end
    end
    cb('not_found')
end)

RegisterNUICallback('removeWanted', function(data, cb)
    RequestWantedRemoval()
    cb('ok')
end)

RegisterNUICallback('dismissAll', function(data, cb)
    DismissAll()
    local active, max = GetGuardCount()
    SendNUIMessage({
        action       = 'updateGuardCount',
        activeGuards = active,
        maxGuards    = max,
    })
    cb('ok')
end)

RegisterNUICallback('cleanupVehicles', function(data, cb)
    CloseMenu()
    CleanupUnusedVehiclesManual()
    cb('ok')
end)

RegisterNUICallback('cleanupNPCs', function(data, cb)
    CloseMenu()
    CleanupUnusedNPCsManual()
    local active, max = GetGuardCount()
    SendNUIMessage({
        action       = 'updateGuardCount',
        activeGuards = active,
        maxGuards    = max,
    })
    cb('ok')
end)

RegisterNUICallback('toggleWorldNPCs', function(data, cb)
    CloseMenu()
    TriggerEvent('bodyguard:client:toggleWorldNPCs')
    cb('ok')
end)

-- Admin: cambiar permiso de un jugador
RegisterNUICallback('setPermission', function(data, cb)
    local targetId = data.targetId
    local permType = data.permType
    local tiers    = data.tiers
    TriggerServerEvent('bodyguard:server:setPermission', targetId, permType, tiers)
    cb('ok')
end)

-- Admin: refrescar lista de jugadores
RegisterNUICallback('refreshPlayers', function(data, cb)
    TriggerServerEvent('bodyguard:server:getPlayers')
    cb('ok')
end)

-- Admin: abrir panel admin desde menú principal
RegisterNUICallback('openAdminPanel', function(data, cb)
    CloseMenu()
    Wait(150)
    OpenAdminPanel()
    cb('ok')
end)

-- Custom input from user
RegisterNUICallback('triggerCustomInput', function(data, cb)
    local type = data.type
    CloseMenu()
    Wait(100)
    
    local text = type == 'guard' and 'Modelo de ped (ej: ig_bankman)' or 'Modelo de vehiculo (ej: kuruma)'
    AddTextEntry('BG_INPUT', text)
    DisplayOnscreenKeyboard(1, "BG_INPUT", "", "", "", "", "", 30)
    
    CreateThread(function()
        while UpdateOnscreenKeyboard() == 0 do
            Wait(0)
        end
        
        if UpdateOnscreenKeyboard() == 1 then
            local result = GetOnscreenKeyboardResult()
            if result and result ~= "" then
                if type == 'guard' then
                    RequestGuardPurchase({
                        id = 'dynamic_guard',
                        label = result,
                        model = result,
                        health = 500,
                        armor = 0,
                        weapon = 'WEAPON_PISTOL',
                        accuracy = 50
                    })
                elseif type == 'vehicle' then
                    RequestVehiclePurchase({
                        id = 'dynamic_vehicle',
                        label = result,
                        model = result,
                        driverModel = 's_m_m_security_01',
                        driverWeapon = 'WEAPON_PISTOL'
                    })
                end
            end
        end
    end)
    
    cb('ok')
end)

-- Input: Comando y Tecla
-- ─────────────────────────────────────────────────────────────────────────────
CreateThread(function()
    while true do
        Wait(0)
        if IsControlJustPressed(0, Config.MenuKey or 29) then
            if menuOpen then
                CloseMenu()
            else
                OpenMenu()
            end
            Wait(250) -- Debounce
        end
    end
end)

RegisterCommand('servicemenu', function()
    if menuOpen then CloseMenu() else OpenMenu() end
end, false)



RegisterCommand(Config.AdminCommand, function()
    if menuOpen then CloseMenu() else OpenAdminPanel() end
end, false)

TriggerEvent('chat:addSuggestion', '/' .. Config.DismissCommand, 'Despedir a todos los guardaespaldas y vehículos')
TriggerEvent('chat:addSuggestion', '/servicemenu', 'Abrir el Service Menu')
TriggerEvent('chat:addSuggestion', '/' .. Config.AdminCommand, 'Panel de administración de BodyGuard (solo admins)')

-- Check admin status on resource start
CreateThread(function()
    Wait(2000) -- esperar a que el server cargue
    TriggerServerEvent('bodyguard:server:checkAdmin')
end)
