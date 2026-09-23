-- ─────────────────────────────────────────────────────────────────────────────
-- respawn_menu / client/main.lua  [v1.2 — BLACK SCREEN FIXED]
-- Bugs corregidos:
--   1. while not IsScreenFadedOut() sin timeout → loop infinito → negro permanente
--   2. NetworkResurrectLocalPlayer sin pcall → crash antes de FadeIn
--   3. DisplayHud(true) llamado AL MORIR en vez de AL ABRIR el menu
--   4. DisableAllControlActions(0/1/2) bloqueaba el cursor del NUI
--   5. timecycle 'death' oscurecía la pantalla y no se limpiaba si habia error
-- ─────────────────────────────────────────────────────────────────────────────

local ESX      = nil
local isDead   = false
local menuOpen = false
local isRespawning = false  -- Guard: prevents polling thread interference during respawn

-- ─────────────────────────────────────────────────────────────────────────────
-- ESX Init
-- ─────────────────────────────────────────────────────────────────────────────
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

-- ─────────────────────────────────────────────────────────────────────────────
-- Notificación
-- ─────────────────────────────────────────────────────────────────────────────
local function Notify(msg)
    if ESX and ESX.ShowNotification then
        ESX.ShowNotification(msg)
    else
        SetNotificationTextEntry('STRING')
        AddTextComponentString(msg)
        DrawNotification(false, true)
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- FIX #1 — Fade con timeout: NUNCA queda en loop infinito
-- ─────────────────────────────────────────────────────────────────────────────
local function SafeFadeOut(ms)
    DoScreenFadeOut(ms)
    local deadline = GetGameTimer() + ms + 2000
    while not IsScreenFadedOut() and GetGameTimer() < deadline do
        Wait(10)
    end
end

local function SafeFadeIn(ms)
    DoScreenFadeIn(ms)
    local deadline = GetGameTimer() + ms + 1000
    while not IsScreenFadedIn() and GetGameTimer() < deadline do
        Wait(10)
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- FIX #5 — Efecto de muerte: usa timecycle suave que NO bloquea la vista
-- (el timecycle 'death' del original dejaba la pantalla completamente negra)
-- ─────────────────────────────────────────────────────────────────────────────
local function ApplyDeathEffect()
    SetTimecycleModifier('NG_filmic01')
    SetTimecycleModifierStrength(0.6)
end

local function RemoveDeathEffect()
    ClearTimecycleModifier()
    DisplayHud(true)
    DisplayRadar(true)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- I-Frames VIP (esfera azul via DrawMarker, sin PTFX inestable)
-- ─────────────────────────────────────────────────────────────────────────────
local function ApplyIFrames(ped, duration)
    SetEntityInvincible(ped, true)
    CreateThread(function()
        local endTime = GetGameTimer() + (duration * 1000)
        while GetGameTimer() < endTime do
            DrawMarker(28, GetEntityCoords(ped),
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                1.8, 1.8, 1.8,
                30, 140, 255, 80,
                false, true, 2, false, nil, nil, false)
            Wait(0)
        end
        SetEntityInvincible(ped, false)
    end)
    Notify(string.format(Config.Locales.iFramesMsg, duration))
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Holograma de advertencia (respawn VIP)
-- ─────────────────────────────────────────────────────────────────────────────
local function ShowHologramWarning(coords)
    local endTime = GetGameTimer() + (Config.HologramWarning * 1000)
    CreateThread(function()
        while GetGameTimer() < endTime do
            SetTextScale(0.5, 0.5)
            SetTextFont(7)
            SetTextProportional(1)
            SetTextColour(255, 80, 80, 230)
            SetTextEntry('STRING')
            SetTextCentre(true)
            AddTextComponentString(Config.Locales.hologramWarning)
            SetDrawOrigin(coords.x, coords.y, coords.z + 2.5, 0)
            DrawText(0.0, 0.0)
            ClearDrawOrigin()
            Wait(0)
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Algoritmo de punto de respawn seguro cercano (GTA Online / Flamtky mejorado)
-- ─────────────────────────────────────────────────────────────────────────────
local function GetSafeNearbyCoords(deathCoords, minRadius)
    local minR = tonumber(minRadius) or (Config.MinRespawnDistance or 150.0)
    local maxR = minR + 250.0 -- Búsqueda entre 150m y 400m de la muerte
    local dx = deathCoords.x or 0.0
    local dy = deathCoords.y or 0.0
    local dz = deathCoords.z or 0.0
    local deathV3 = vector3(dx, dy, dz)

    local candidateNodes = {}

    -- 1. Buscar nodos viales en el rango [minR, maxR] evitando autopistas rápidas (flag 66)
    for nth = 1, 60 do
        local found, nodePos = GetNthClosestVehicleNode(dx, dy, dz, nth, 1, 3, 0)
        if found and nodePos and nodePos.x ~= 0.0 then
            local dist = #(deathV3 - nodePos)
            if dist >= minR and dist <= maxR then
                local succProp, _, flags = GetVehicleNodeProperties(nodePos.x, nodePos.y, nodePos.z)
                if not (succProp and flags == 66) then
                    table.insert(candidateNodes, { pos = nodePos, dist = dist })
                    if #candidateNodes >= 8 then
                        break
                    end
                end
            end
        end
    end

    -- 2. Si no hubo en [minR, maxR], ampliar búsqueda a cualquier nodo >= minR
    if #candidateNodes == 0 then
        for nth = 1, 80 do
            local found, nodePos = GetNthClosestVehicleNode(dx, dy, dz, nth, 1, 3, 0)
            if found and nodePos and nodePos.x ~= 0.0 then
                local dist = #(deathV3 - nodePos)
                if dist >= minR then
                    table.insert(candidateNodes, { pos = nodePos, dist = dist })
                    if #candidateNodes >= 5 then break end
                end
            end
        end
    end

    -- 3. Si se encontraron nodos viales, posicionar en acera segura
    if #candidateNodes > 0 then
        local chosen = candidateNodes[math.random(1, #candidateNodes)].pos

        -- Obtener dirección de la calle
        local succHeading, _, roadHeading = GetClosestVehicleNodeWithHeading(chosen.x, chosen.y, chosen.z, 1, 3, 0)
        if not succHeading or not roadHeading then
            roadHeading = math.random(0, 360) + 0.0
        end

        -- A. Si el navmesh peatonal nativo está cargado, usar la vereda oficial
        local succPed, pedCoord = GetSafeCoordForPed(chosen.x, chosen.y, chosen.z, false, 1)
        if not succPed then
            succPed, pedCoord = GetSafeCoordForPed(chosen.x, chosen.y, chosen.z, false, 16)
        end

        if succPed and pedCoord and pedCoord.x ~= 0.0 then
            local h = GetHeadingFromVector_2d(chosen.x - pedCoord.x, chosen.y - pedCoord.y)
            return pedCoord, h
        end

        -- B. Si el navmesh peatonal no está en memoria a esa distancia,
        -- calcular la acera lateral perpendicular a la calle (4.5m a un costado)
        local side = (math.random() < 0.5) and 90.0 or -90.0
        local rad = math.rad(roadHeading + side)
        local sidewalkPos = vector3(
            chosen.x + math.cos(rad) * 4.5,
            chosen.y + math.sin(rad) * 4.5,
            chosen.z
        )
        local finalHeading = (roadHeading + 180.0) % 360.0
        return sidewalkPos, finalHeading
    end

    -- 4. Fallback de emergencia si el jugador murió sin carreteras cerca (ej: mar abierto):
    -- Desplazar 180m en un ángulo aleatorio del punto de muerte
    local angle = math.random() * 2 * math.pi
    local fallbackPos = vector3(
        dx + math.cos(angle) * (minR + 30.0),
        dy + math.sin(angle) * (minR + 30.0),
        dz
    )
    return fallbackPos, math.random(0, 360) + 0.0
end

-- ─────────────────────────────────────────────────────────────────────────────
-- FIX #2 — Resurrect seguro del ped (Sin caídas al vacío ni glitch de spawnmanager)
-- ─────────────────────────────────────────────────────────────────────────────
local function SafeRespawnPed(x, y, z, heading)
    local ped = PlayerPedId()

    -- 1. Ocultar y congelar al ped mientras se carga el mapa para evitar caídas
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetEntityVisible(ped, false, false)
    SetEntityCollision(ped, false)

    -- 2. Posicionar en el destino y solicitar streaming de colisiones
    SetEntityCoordsNoOffset(ped, x, y, z + 0.5, false, false, false, true)
    RequestCollisionAtCoord(x, y, z)
    SetFocusPosAndVel(x, y, z, 0.0, 0.0, 0.0)

    -- 3. Esperar activamente a que el motor cargue el suelo físico
    local startWait = GetGameTimer()
    while not HasCollisionLoadedAroundEntity(ped) and (GetGameTimer() - startWait) < 3500 do
        RequestCollisionAtCoord(x, y, z)
        Wait(10)
    end

    -- 4. Determinar la altura real del suelo (buscando verticalmente hacia abajo)
    local groundZ = z
    local foundGround = false
    for testOffset = 30.0, -15.0, -5.0 do
        local ok, gz = GetGroundZFor_3dCoord(x, y, z + testOffset, false)
        if ok and gz > 0.0 then
            groundZ = gz
            foundGround = true
            break
        end
    end
    if not foundGround then
        local ok, gz = GetGroundZFor_3dCoord(x, y, z, false)
        if ok and gz > 0.0 then groundZ = gz end
    end

    -- 5. Resurrección oficial con suelo ya cargado y a la altura precisa
    pcall(function()
        NetworkResurrectLocalPlayer(x, y, groundZ + 0.05, heading, true, true, false)
    end)
    Wait(50)

    ped = PlayerPedId()
    ClearFocus()
    SetEntityCoordsNoOffset(ped, x, y, groundZ + 0.05, false, false, false, true)
    SetEntityHeading(ped, heading)
    SetEntityVisible(ped, true, false)

    -- 6. Limpiar tareas, animaciones de muerte y ragdoll
    ClearPedTasksImmediately(ped)
    SetPedCanRagdoll(ped, false)
    Wait(50)
    SetPedCanRagdoll(ped, true)

    -- 7. Restaurar vida completa y quitar daño
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    SetPedArmour(ped, 0)
    ClearPedBloodDamage(ped)
    SetEntityInvincible(ped, false)

    -- 8. Restaurar colisión física y descongelar al ped sobre suelo sólido
    SetEntityCollision(ped, true)
    FreezeEntityPosition(ped, false)

    return ped
end

-- ─────────────────────────────────────────────────────────────────────────────
-- RESPAWN PRINCIPAL
-- ─────────────────────────────────────────────────────────────────────────────
RegisterNetEvent('respawn_menu:client:doRespawn', function(data)
    -- Cerrar menú y liberar foco NUI inmediatamente
    menuOpen = false
    isRespawning = true  -- Block polling thread during entire respawn process
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeMenu' })

    local x = data.x
    local y = data.y
    local z = data.z
    local heading = data.heading or 0.0

    -- Si es tipo 'nearby', calcular acera segura cercana
    if data.type == 'nearby' then
        local baseCoords = vector3(x or 0.0, y or 0.0, z or 0.0)
        if baseCoords.x == 0.0 then
            baseCoords = GetEntityCoords(PlayerPedId())
        end
        local succ, safeCoords, safeHeading = pcall(GetSafeNearbyCoords, baseCoords, Config.MinRespawnDistance)
        if succ and safeCoords then
            x = safeCoords.x
            y = safeCoords.y
            z = safeCoords.z
            heading = safeHeading or 0.0
            print(string.format('^2[respawn_menu]^7 Respawn cercano seguro calculado en [%.1f, %.1f, %.1f]', x, y, z))
        else
            print('^1[respawn_menu]^7 Error al calcular GetSafeNearbyCoords: ' .. tostring(safeCoords))
        end
    end

    -- Holograma VIP antes del fade
    if data.type == 'here' then
        pcall(function() ShowHologramWarning({ x = x, y = y, z = z }) end)
        Notify(Config.Locales.respawnHereMsg)
        Wait(500)
    else
        Notify(string.format(Config.Locales.deployMsg, data.label or 'zona'))
    end

    -- Fade out seguro
    SafeFadeOut(Config.RespawnFadeTime)

    -- Resucitar al ped directamente con la secuencia probada
    local ped = SafeRespawnPed(x, y, z, heading)

    -- Finalizar y reactivar controles/pantalla
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    SetPedArmour(ped, 0)
    ClearPedBloodDamage(ped)
    ClearPedTasksImmediately(ped)
    SetPedCanRagdoll(ped, false)
    Wait(50)
    SetPedCanRagdoll(ped, true)

    RemoveDeathEffect()

    -- Marcar como vivo DESPUÉS de que el ped está resucitado
    isDead = false
    isRespawning = false  -- Release the guard

    SafeFadeIn(Config.RespawnFadeTime)
    DisplayHud(true)
    DisplayRadar(true)

    TriggerEvent('playerSpawned', x, y, z)
    pcall(function() TriggerEvent('esx_ambulancejob:revive') end)

    if data.type == 'here' then
        ApplyIFrames(ped, Config.IFramesDuration)
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Abrir menú
-- FIX #3: el HUD se oculta AQUÍ (al abrir), no en el thread de detección
-- FIX #4: no se usa DisableAllControlActions que bloqueaba el cursor NUI
-- ─────────────────────────────────────────────────────────────────────────────
RegisterNetEvent('respawn_menu:client:openMenu', function(data)
    if menuOpen or isRespawning then return end
    menuOpen = true

    -- Reset NUI state in case it's stuck from a previous session
    SendNUIMessage({ action = 'closeMenu' })

    -- Asegurar que la pantalla no se quede en negro si hubo fade por muerte previa
    DoScreenFadeIn(500)
    local fadeDeadline = GetGameTimer() + 1500
    while not IsScreenFadedIn() and GetGameTimer() < fadeDeadline do
        Wait(10)
    end

    -- Ocultar HUD nativo mientras el menú está abierto
    DisplayHud(false)
    DisplayRadar(false)

    -- Efecto visual de muerte
    ApplyDeathEffect()

    -- Abrir NUI con foco de mouse
    SetNuiFocus(true, true)
    SendNUIMessage({
        action    = 'openMenu',
        deathX    = data.deathX,
        deathY    = data.deathY,
        deathZ    = data.deathZ,
        hasPerm   = data.hasPerm,
        minDist   = data.minDist,
        autoTime  = data.autoTime,
        points    = data.points,
        locales   = Config.Locales,
        mapBounds = Config.MapBounds,
    })

    -- Countdown auto-respawn
    if data.autoTime and data.autoTime > 0 then
        local remaining = data.autoTime
        CreateThread(function()
            while remaining > 0 and menuOpen do
                Wait(1000)
                remaining = remaining - 1
                if menuOpen then
                    SendNUIMessage({ action = 'updateCountdown', seconds = remaining })
                end
            end
            if menuOpen then
                TriggerServerEvent('respawn_menu:server:autoRespawn')
            end
        end)
    end

    -- Bloquear controles de juego y cámara para foco exclusivo en NUI
    CreateThread(function()
        while menuOpen do
            DisableControlAction(0, 1, true)   -- Look Left/Right
            DisableControlAction(0, 2, true)   -- Look Up/Down
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 25, true)  -- Aim
            DisableControlAction(0, 47, true)  -- Weapon wheel
            DisableControlAction(0, 58, true)  -- Next weapon
            DisableControlAction(0, 37, true)  -- Select weapon
            DisableControlAction(0, 142, true) -- Melee Attack
            DisableControlAction(0, 257, true) -- Attack 2
            Wait(0)
        end
    end)
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Error desde servidor (zona muy cercana)
-- ─────────────────────────────────────────────────────────────────────────────
RegisterNetEvent('respawn_menu:client:respawnError', function(reason, minDist)
    if reason == 'too_close' then
        SendNUIMessage({
            action  = 'showError',
            message = string.format(Config.Locales.tooClose,
                math.floor(minDist or Config.MinRespawnDistance))
        })
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- NUI Callbacks
-- ─────────────────────────────────────────────────────────────────────────────
RegisterNUICallback('respawnHere', function(data, cb)
    menuOpen = false
    SetNuiFocus(false, false)
    TriggerServerEvent('respawn_menu:server:respawnHere', data)
    cb('ok')
end)

RegisterNUICallback('respawnNearby', function(data, cb)
    menuOpen = false
    SetNuiFocus(false, false)
    TriggerServerEvent('respawn_menu:server:respawnNearby', data)
    cb('ok')
end)

RegisterNUICallback('respawnZone', function(data, cb)
    menuOpen = false
    SetNuiFocus(false, false)
    local pId = (type(data) == 'table' and data.pointId) or (type(data) == 'string' and data) or nil
    if pId then
        TriggerServerEvent('respawn_menu:server:respawnZone', pId, data)
    else
        print('^1[respawn_menu]^7 Error: respawnZone NUI callback recibido sin punto válido: ' .. tostring(json.encode(data)))
    end
    cb('ok')
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Desactivar auto-spawn nativo de FiveM (como en Flamtky/fivem-respawn-nearby)
-- ─────────────────────────────────────────────────────────────────────────────
CreateThread(function()
    Wait(500)
    pcall(function()
        if exports.spawnmanager then
            exports.spawnmanager:setAutoSpawn(false)
        end
    end)
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Eventos baseevents de FiveM para detección instantánea de muerte
-- ─────────────────────────────────────────────────────────────────────────────
AddEventHandler('baseevents:onPlayerDied', function(killerType, deathCoords)
    if not isDead and not isRespawning then
        isDead = true
        Wait(400)
        local coords = deathCoords or GetEntityCoords(PlayerPedId())
        TriggerServerEvent('respawn_menu:server:playerDied', coords.x, coords.y, coords.z)
    end
end)

AddEventHandler('baseevents:onPlayerKilled', function(killerId, deathData)
    if not isDead and not isRespawning then
        isDead = true
        Wait(400)
        local coords = (deathData and deathData.deathCoords) or GetEntityCoords(PlayerPedId())
        TriggerServerEvent('respawn_menu:server:playerDied', coords.x, coords.y, coords.z)
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Thread de detección de muerte complementario (polling de seguridad)
-- ─────────────────────────────────────────────────────────────────────────────
CreateThread(function()
    while true do
        Wait(Config.DeathDetectInterval)

        -- Skip ALL checks while a respawn is in progress
        if not isRespawning then
            local ped = PlayerPedId()

            -- Nueva muerte detectada
            if not isDead and IsEntityDead(ped) then
                isDead = true
                Wait(400)
                if not isRespawning then -- Re-check after wait
                    local coords = GetEntityCoords(ped)
                    TriggerServerEvent('respawn_menu:server:playerDied', coords.x, coords.y, coords.z)
                end
            end

            -- Resurrección externa (esx_ambulancejob, hospital, etc.)
            if isDead and not IsEntityDead(ped) and not menuOpen and not isRespawning then
                isDead   = false
                menuOpen = false
                RemoveDeathEffect()
                SetNuiFocus(false, false)
                SendNUIMessage({ action = 'closeMenu' })
            end
        end
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Limpieza al reiniciar el recurso
-- ─────────────────────────────────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    SetNuiFocus(false, false)
    DisplayHud(true)
    DisplayRadar(true)
    ClearTimecycleModifier()
    DoScreenFadeIn(0)   -- fade instantáneo si se reinicia mid-fade
    menuOpen = false
    isDead   = false
    isRespawning = false
end)
