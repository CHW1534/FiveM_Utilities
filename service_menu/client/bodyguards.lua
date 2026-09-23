-- ═══════════════════════════════════════════════════════════════════════════════
-- BodyGuard — Client Main
-- Spawn, AI, grupos, blips, vehículos de escolta, cleanup
-- ═══════════════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────────────────────
-- State
-- ─────────────────────────────────────────────────────────────────────────────
local spawnedGuards        = {}    -- { { ped = handle, blip = handle, tier = string } }
local spawnedVehicles      = {}    -- { { vehicle = handle, driver = handle, blip = handle, lastUsed = timestamp } }
local trackedConvoyVehicles= {}    -- { { vehicle = handle, lastUsed = timestamp } }
local playerGroup          = nil
local pendingPurchase      = nil   -- { type = 'guard'|'vehicle'|'wanted', data = table }

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

local function loadModel(hash)
    if HasModelLoaded(hash) then return true end
    RequestModel(hash)
    local timeout = 50
    while not HasModelLoaded(hash) and timeout > 0 do
        Wait(100)
        timeout = timeout - 1
    end
    return HasModelLoaded(hash)
end

local function getSpawnPosition(offset)
    local ped     = PlayerPedId()
    local coords  = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local count   = #spawnedGuards
    local angle   = heading + 90 + (count * 45)
    local aRad    = math.rad(angle)
    local x = coords.x + (offset * math.cos(aRad))
    local y = coords.y + (offset * math.sin(aRad))
    local z = coords.z
    return vector3(x, y, z), heading + 180.0
end

local function notify(msg)
    SetNotificationTextEntry('STRING')
    AddTextComponentSubstringPlayerName(msg)
    DrawNotification(false, true)
end

local function countActiveGuards()
    local count = 0
    for _, g in ipairs(spawnedGuards) do
        if DoesEntityExist(g.ped) and not IsEntityDead(g.ped) then
            count = count + 1
        end
    end
    return count
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Grupo del Jugador
-- ─────────────────────────────────────────────────────────────────────────────
local playerGroup = nil
local function ensurePlayerGroup()
    local ped = PlayerPedId()
    if not playerGroup or not DoesGroupExist(playerGroup) then
        playerGroup = CreateGroup(0)
        SetPedAsGroupLeader(ped, playerGroup)
        SetGroupFormation(playerGroup, 1) -- Formación estándar alrededor del líder
        SetGroupFormationSpacing(playerGroup, 1.5, 1.5, 3.0)
        SetGroupSeparationRange(playerGroup, 9999.0)
    else
        SetPedAsGroupLeader(ped, playerGroup)
    end
    return playerGroup
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Spawn de Guardaespaldas
-- ─────────────────────────────────────────────────────────────────────────────
function SpawnBodyguard(guardConfig)
    if countActiveGuards() >= Config.MaxBodyguards then
        notify(Config.Locales.maxReached:format(countActiveGuards(), Config.MaxBodyguards))
        return false
    end

    local modelHash  = GetHashKey(guardConfig.model)
    local weaponHash = GetHashKey(guardConfig.weapon)

    if not loadModel(modelHash) then
        notify('~r~Error: Modelo no válido.')
        return false
    end

    local pos, heading = getSpawnPosition(Config.SpawnDistance)
    -- Tipo 29 = PED_TYPE_SECURITY (soldados/seguridad valientes por defecto)
    local ped = CreatePed(29, modelHash, pos.x, pos.y, pos.z, heading, true, true)
    SetModelAsNoLongerNeeded(modelHash)

    if not DoesEntityExist(ped) then
        notify('~r~Error al crear guardaespaldas.')
        return false
    end

    -- Limpiar tareas para borrar cualquier animación o huida residual
    ClearPedTasksImmediately(ped)

    -- Salud y Armadura
    SetEntityMaxHealth(ped, guardConfig.health)
    SetEntityHealth(ped, guardConfig.health)
    if guardConfig.armor and guardConfig.armor > 0 then
        SetPedArmour(ped, guardConfig.armor)
    end

    -- Arma
    GiveWeaponToPed(ped, weaponHash, 9999, false, true)
    SetCurrentPedWeapon(ped, weaponHash, true)

    -- AI de Combate (Guardaespaldas profesional - NUNCA HUYE)
    SetPedCombatAbility(ped, 2)
    SetPedCombatMovement(ped, 2)
    SetPedCombatRange(ped, 2)
    SetPedAccuracy(ped, guardConfig.accuracy or 75)

    -- Desactivar huida completamente
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 17, false) -- BF_AlwaysFlee = FALSE (Nunca huye)
    SetPedCombatAttributes(ped, 46, true)  -- BF_AlwaysFight = TRUE (Siempre combate)
    SetPedCombatAttributes(ped, 5, true)   -- BF_CanFightArmedPedsWhenNotArmed = TRUE
    SetPedCombatAttributes(ped, 0, true)   -- BF_CanUseCover = TRUE
    SetPedCombatAttributes(ped, 1, true)   -- BF_CanUseVehicles = TRUE
    SetPedCombatAttributes(ped, 2, true)   -- BF_CanDoDrivebys = TRUE
    SetPedCombatAttributes(ped, 3, true)   -- BF_CanLeaveVehicle = TRUE
    SetPedHearingRange(ped, 100.0)
    SetPedSeeingRange(ped, 100.0)

    -- Relaciones con el jugador y otros
    local playerGroupHash = GetPedRelationshipGroupHash(PlayerPedId())
    SetPedRelationshipGroupHash(ped, playerGroupHash)
    SetCanAttackFriendly(ped, false, false) -- Disable friendly fire for bodyguards
    SetEntityCanBeDamagedByRelationshipGroup(ped, false, playerGroupHash) -- No tomar daño del jugador ni de la facción
    SetPedCanBeTargetted(ped, true)
    SetPedCanBeTargettedByPlayer(ped, PlayerId(), false)

    -- Asignar al grupo del jugador
    local grp = ensurePlayerGroup()
    SetPedAsGroupMember(ped, grp)
    SetPedNeverLeavesGroup(ped, true)
    SetPedCanTeleportToGroupLeader(ped, grp, false)

    -- Invulnerabilidad al spawn (3s)
    SetEntityInvincible(ped, true)
    SetTimeout(3000, function()
        if DoesEntityExist(ped) then
            SetEntityInvincible(ped, false)
        end
    end)

    -- Blip
    local blip = AddBlipForEntity(ped)
    SetBlipSprite(blip, Config.BlipSprite)
    SetBlipColour(blip, Config.BlipColor)
    SetBlipScale(blip, Config.BlipScale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(Config.BlipLabel .. ' — ' .. guardConfig.label)
    EndTextCommandSetBlipName(blip)

    table.insert(spawnedGuards, {
        ped    = ped,
        blip   = blip,
        tier   = guardConfig.id,
        label  = guardConfig.label,
        weapon = weaponHash,
    })

    notify(Config.Locales.buySuccess:format(guardConfig.label))
    return true
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Spawn de Vehículo de Escolta
-- ─────────────────────────────────────────────────────────────────────────────
function SpawnEscortVehicle(vehConfig)
    local vehHash    = GetHashKey(vehConfig.model)
    local driverHash = GetHashKey(vehConfig.driverModel)
    local weaponHash = GetHashKey(vehConfig.driverWeapon)

    if not loadModel(vehHash) then
        notify('~r~Error: Modelo de vehículo no válido.')
        return false
    end
    if not loadModel(driverHash) then
        SetModelAsNoLongerNeeded(vehHash)
        notify('~r~Error: Modelo de chofer no válido.')
        return false
    end

    local ped      = PlayerPedId()
    local coords   = GetEntityCoords(ped)
    local heading  = GetEntityHeading(ped)
    local spawnPos = GetOffsetFromEntityInWorldCoords(ped, Config.VehicleSpawnDist, 0.0, 0.0)

    local vehicle = CreateVehicle(vehHash, spawnPos.x, spawnPos.y, spawnPos.z, heading + 90.0, true, false)
    SetModelAsNoLongerNeeded(vehHash)

    if not DoesEntityExist(vehicle) then
        notify('~r~Error al crear vehículo.')
        return false
    end

    SetVehicleModKit(vehicle, 0)
    SetVehicleOnGroundProperly(vehicle)

    local driver = CreatePedInsideVehicle(vehicle, 29, driverHash, -1, true, false)
    if not DoesEntityExist(driver) or GetVehiclePedIsIn(driver, false) ~= vehicle then
        -- Intentar asiento 0 (asiento derecho en ciertos vehículos RHD moddeados)
        driver = CreatePedInsideVehicle(vehicle, 29, driverHash, 0, true, false)
    end
    SetModelAsNoLongerNeeded(driverHash)

    if not DoesEntityExist(driver) then
        DeleteVehicle(vehicle)
        notify('~r~Error al crear chofer.')
        return false
    end

    ClearPedTasksImmediately(driver)
    GiveWeaponToPed(driver, weaponHash, 9999, false, true)
    SetPedCombatAbility(driver, 2)
    SetPedCombatMovement(driver, 2)
    SetPedAccuracy(driver, 75)
    SetPedFleeAttributes(driver, 0, false)
    SetPedCombatAttributes(driver, 17, false)
    SetPedCombatAttributes(driver, 46, true)
    SetPedCombatAttributes(driver, 2, true)

    local playerGroupHash = GetPedRelationshipGroupHash(PlayerPedId())
    SetPedRelationshipGroupHash(driver, playerGroupHash)
    SetCanAttackFriendly(driver, false, false)
    SetPedAsGroupMember(driver, ensurePlayerGroup())
    SetPedNeverLeavesGroup(driver, true)

    TaskVehicleEscort(driver, vehicle, GetVehiclePedIsIn(ped, false) ~= 0 and GetVehiclePedIsIn(ped, false) or ped, -1, 40.0, 786603, 10.0, 0, 20.0)

    local blip = AddBlipForEntity(vehicle)
    SetBlipSprite(blip, Config.VehicleBlipSprite)
    SetBlipColour(blip, Config.VehicleBlipColor)
    SetBlipScale(blip, Config.VehicleBlipScale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Escolta — ' .. vehConfig.label)
    EndTextCommandSetBlipName(blip)

    table.insert(spawnedVehicles, {
        vehicle  = vehicle,
        driver   = driver,
        blip     = blip,
        label    = vehConfig.label,
        lastUsed = GetGameTimer(),
    })

    notify(Config.Locales.vehicleBought:format(vehConfig.label))
    return true
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Wanted Level Removal
-- ─────────────────────────────────────────────────────────────────────────────
function RemoveWantedLevel()
    local pid = PlayerId()
    if GetPlayerWantedLevel(pid) <= 0 then
        notify(Config.Locales.wantedNone)
        return false
    end
    SetPlayerWantedLevel(pid, 0, false)
    SetPlayerWantedLevelNow(pid, false)
    notify(Config.Locales.wantedRemoved)
    return true
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Dismiss (Despedir a todos)
-- ─────────────────────────────────────────────────────────────────────────────
function DismissAll()
    for _, g in ipairs(spawnedGuards) do
        if DoesEntityExist(g.ped) then DeletePed(g.ped) end
        if DoesBlipExist(g.blip) then RemoveBlip(g.blip) end
    end
    spawnedGuards = {}

    for _, v in ipairs(spawnedVehicles) do
        if DoesEntityExist(v.driver) then DeletePed(v.driver) end
        if DoesEntityExist(v.vehicle) then DeleteVehicle(v.vehicle) end
        if DoesBlipExist(v.blip) then RemoveBlip(v.blip) end
    end
    spawnedVehicles = {}

    for _, cv in ipairs(trackedConvoyVehicles) do
        if DoesEntityExist(cv.vehicle) then
            SetEntityAsMissionEntity(cv.vehicle, true, true)
            DeleteVehicle(cv.vehicle)
        end
    end
    trackedConvoyVehicles = {}

    notify(Config.Locales.dismissed)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Cleanup de guardaespaldas muertos (cada 5 seg)
-- ─────────────────────────────────────────────────────────────────────────────
CreateThread(function()
    while true do
        Wait(5000)
        for i = #spawnedGuards, 1, -1 do
            local g = spawnedGuards[i]
            if not DoesEntityExist(g.ped) or IsEntityDead(g.ped) then
                if DoesEntityExist(g.ped) then DeletePed(g.ped) end
                if DoesBlipExist(g.blip) then RemoveBlip(g.blip) end
                table.remove(spawnedGuards, i)
            end
        end
        for i = #spawnedVehicles, 1, -1 do
            local v = spawnedVehicles[i]
            local vehDead = not DoesEntityExist(v.vehicle) or IsEntityDead(v.vehicle)
            local drvDead = not DoesEntityExist(v.driver)  or IsEntityDead(v.driver)
            if vehDead or drvDead then
                if DoesEntityExist(v.driver) then DeletePed(v.driver) end
                if DoesEntityExist(v.vehicle) then DeleteVehicle(v.vehicle) end
                if DoesBlipExist(v.blip) then RemoveBlip(v.blip) end
                table.remove(spawnedVehicles, i)
            end
        end
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Timer de Limpieza de Vehículos Fuera de Uso (1 km Radio: 5 Minutos Automático + Manual)
-- ─────────────────────────────────────────────────────────────────────────────
local abandonedVehiclesTracked = {} -- { [vehHandle] = timestampFirstSeenUnused }

local function isVehicleInUse(veh)
    if not DoesEntityExist(veh) then return false end
    local playerPed = PlayerPedId()

    -- 1. ¿El jugador local está adentro?
    if GetVehiclePedIsIn(playerPed, false) == veh then return true end

    -- 2. ¿Hay algún otro jugador humano dentro?
    local totalSeats = GetVehicleModelNumberOfSeats(GetEntityModel(veh))
    local maxCheck = math.max(totalSeats - 2, 8)
    for s = -1, maxCheck do
        local p = GetPedInVehicleSeat(veh, s)
        if p ~= 0 and DoesEntityExist(p) and not IsEntityDead(p) then
            if IsPedAPlayer(p) then
                return true
            end
            -- 3. ¿Es uno de nuestros guardaespaldas?
            for _, g in ipairs(spawnedGuards) do
                if g.ped == p then return true end
            end
            -- 4. ¿Es un chofer de escolta?
            for _, v in ipairs(spawnedVehicles) do
                if v.driver == p then return true end
            end
            -- 5. ¿Es un NPC en tráfico activo con motor encendido?
            if s == -1 and GetIsVehicleEngineRunning(veh) and not IsEntityDead(p) then
                return true
            end
        end
    end

    return false
end

-- Función manual para vehículos llamada desde el menú de Servicios (Radio 1 km)
function CleanupUnusedVehiclesManual()
    local playerPed = PlayerPedId()
    local pCoords   = GetEntityCoords(playerPed)
    local radius    = Config.VehicleCleanupRadius or 1000.0
    local count     = 0

    -- 1. Limpieza en el pool del cliente (todos los vehículos cargados a 1 km)
    local allVehs = GetGamePool('CVehicle')
    for _, veh in ipairs(allVehs) do
        if DoesEntityExist(veh) then
            local vCoords = GetEntityCoords(veh)
            local dist = #(pCoords - vCoords)
            if dist <= radius then
                if not isVehicleInUse(veh) then
                    -- Quitar de listas si estaba registrado
                    for i = #spawnedVehicles, 1, -1 do
                        if spawnedVehicles[i].vehicle == veh then
                            if DoesBlipExist(spawnedVehicles[i].blip) then RemoveBlip(spawnedVehicles[i].blip) end
                            table.remove(spawnedVehicles, i)
                        end
                    end
                    for i = #trackedConvoyVehicles, 1, -1 do
                        if trackedConvoyVehicles[i].vehicle == veh then
                            table.remove(trackedConvoyVehicles, i)
                        end
                    end
                    abandonedVehiclesTracked[veh] = nil

                    -- Borrado seguro del vehículo
                    SetEntityAsMissionEntity(veh, true, true)
                    local timeout = 10
                    while not NetworkHasControlOfEntity(veh) and timeout > 0 do
                        NetworkRequestControlOfEntity(veh)
                        Wait(5)
                        timeout = timeout - 1
                    end
                    DeleteVehicle(veh)
                    if DoesEntityExist(veh) then DeleteEntity(veh) end
                    count = count + 1
                end
            end
        end
    end

    -- 2. Solicitar al servidor que limpie cualquier entidad server-side restante en el radio de 1 km
    TriggerServerEvent('bodyguard:server:cleanupVehiclesRadius', pCoords, radius)

    if count > 0 then
        notify(('~g~Se eliminaron %d vehículo(s) fuera de uso en 1 km.'):format(count))
    else
        notify('~y~No se encontraron vehículos fuera de uso en 1 km.')
    end
end

-- Función manual para NPCs llamada desde el menú de Servicios
function CleanupUnusedNPCsManual()
    local count = 0
    local playerPed = PlayerPedId()
    local pCoords = GetEntityCoords(playerPed)

    for i = #spawnedGuards, 1, -1 do
        local g = spawnedGuards[i]
        local isDead = not DoesEntityExist(g.ped) or IsEntityDead(g.ped)
        local isFar = false

        if DoesEntityExist(g.ped) then
            local dist = #(pCoords - GetEntityCoords(g.ped))
            if dist > 60.0 then
                isFar = true
            end
        end

        if isDead or isFar then
            if DoesEntityExist(g.ped) then DeletePed(g.ped) end
            if DoesBlipExist(g.blip) then RemoveBlip(g.blip) end
            table.remove(spawnedGuards, i)
            count = count + 1
        end
    end

    if count > 0 then
        notify(('~g~Se eliminaron %d NPC(s) rezagados o fuera de uso.'):format(count))
    else
        notify('~y~No hay NPCs rezagados o fuera de uso.')
    end
end

-- Timer de fondo: 5 Minutos Automático (Vehículos en 1 km y NPCs Rezagados)
CreateThread(function()
    while true do
        Wait(10000) -- Evalúa cada 10 segundos
        local now = GetGameTimer()
        local playerPed = PlayerPedId()
        local pCoords = GetEntityCoords(playerPed)

        -- 1. Limpieza automática de Vehículos fuera de uso a 1 km (5 min de inactividad)
        if Config.AutoCleanupUnusedVehicles then
            local timeoutMs = (Config.VehicleCleanupMinutes or 5) * 60 * 1000
            local radius    = Config.VehicleCleanupRadius or 1000.0

            local allVehs = GetGamePool('CVehicle')
            for _, veh in ipairs(allVehs) do
                if DoesEntityExist(veh) then
                    local vCoords = GetEntityCoords(veh)
                    local dist = #(pCoords - vCoords)
                    if dist <= radius then
                        if not isVehicleInUse(veh) then
                            -- Registrar tiempo desde que se vio vacío
                            if not abandonedVehiclesTracked[veh] then
                                abandonedVehiclesTracked[veh] = now
                            elseif (now - abandonedVehiclesTracked[veh]) >= timeoutMs then
                                -- Lleva 5 minutos fuera de uso: borrar
                                for i = #spawnedVehicles, 1, -1 do
                                    if spawnedVehicles[i].vehicle == veh then
                                        if DoesBlipExist(spawnedVehicles[i].blip) then RemoveBlip(spawnedVehicles[i].blip) end
                                        table.remove(spawnedVehicles, i)
                                    end
                                end
                                for i = #trackedConvoyVehicles, 1, -1 do
                                    if trackedConvoyVehicles[i].vehicle == veh then
                                        table.remove(trackedConvoyVehicles, i)
                                    end
                                end

                                SetEntityAsMissionEntity(veh, true, true)
                                local timeout = 10
                                while not NetworkHasControlOfEntity(veh) and timeout > 0 do
                                    NetworkRequestControlOfEntity(veh)
                                    Wait(5)
                                    timeout = timeout - 1
                                end
                                DeleteVehicle(veh)
                                if DoesEntityExist(veh) then DeleteEntity(veh) end
                                abandonedVehiclesTracked[veh] = nil
                            end
                        else
                            -- Está en uso: resetear timer
                            abandonedVehiclesTracked[veh] = nil
                        end
                    else
                        abandonedVehiclesTracked[veh] = nil
                    end
                end
            end
        end

        -- 2. Limpieza automática de NPCs rezagados/abandonados (5 min a gran distancia)
        if Config.AutoCleanupUnusedNPCs then
            local npcTimeoutMs = (Config.NPCCleanupMinutes or 5) * 60 * 1000
            local maxDist = Config.NPCAbandonedDistance or 120.0

            for i = #spawnedGuards, 1, -1 do
                local g = spawnedGuards[i]
                if DoesEntityExist(g.ped) then
                    local gCoords = GetEntityCoords(g.ped)
                    local dist = #(pCoords - gCoords)

                    if dist > maxDist then
                        if not g.abandonedSince then
                            g.abandonedSince = now
                        elseif (now - g.abandonedSince) >= npcTimeoutMs then
                            DeletePed(g.ped)
                            if DoesBlipExist(g.blip) then RemoveBlip(g.blip) end
                            table.remove(spawnedGuards, i)
                        end
                    else
                        g.abandonedSince = nil
                    end
                end
            end
        end
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Helper: Asientos disponibles (Soporte Total: Cabina, Volante RHD/LHD, Torretas y Estribos)
-- ─────────────────────────────────────────────────────────────────────────────
local function getAvailableVehicleSeats(vehicle, playerPed)
    local available = {}
    if not DoesEntityExist(vehicle) then return available end

    local model = GetEntityModel(vehicle)
    local totalSeats = GetVehicleModelNumberOfSeats(model)
    local maxPass = GetVehicleMaxNumberOfPassengers(vehicle)
    -- Escanear hasta 16 para abarcar todos los asientos, torretas (gunner) y estribos exteriores
    local maxSeatIndex = math.max(totalSeats - 2, maxPass + 1, 16)

    -- Detectar en qué asiento está sentado el jugador (conductor, copiloto o torreta)
    local playerSeat = nil
    for s = -1, maxSeatIndex do
        if GetPedInVehicleSeat(vehicle, s) == playerPed then
            playerSeat = s
            break
        end
    end

    -- Recorrer todos los asientos posibles: conductor opuesto (-1 o 0), pasajeros (1, 2...), torretas (3, 4...)
    for s = -1, maxSeatIndex do
        if s ~= playerSeat and IsVehicleSeatFree(vehicle, s) then
            table.insert(available, s)
        end
    end

    return available
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Sistema de Escolta y Gestión de Vehículos (Caminar, Entrar/Bajar de Autos, Convoy)
-- ─────────────────────────────────────────────────────────────────────────────
CreateThread(function()
    while true do
        Wait(1000)
        local playerPed = PlayerPedId()
        local playerVeh = GetVehiclePedIsIn(playerPed, false)

        -- 1. Si el jugador está dentro de un vehículo (LHD, RHD o vehículo con torreta)
        if playerVeh ~= 0 then
            local availableSeats = getAvailableVehicleSeats(playerVeh, playerPed)
            local assignedSeats = {}
            local myGuardsWithoutSeat = {}

            -- Revisar qué asientos ya están siendo ocupados o reservados por guardias
            for _, g in ipairs(spawnedGuards) do
                if DoesEntityExist(g.ped) and not IsEntityDead(g.ped) then
                    local gVeh = GetVehiclePedIsIn(g.ped, false)
                    if gVeh == playerVeh then
                        -- El guardia está dentro del auto: no permitir que se baje a pie durante combate (mantenerlo en torreta/asiento)
                        SetPedCombatAttributes(g.ped, 3, false) -- BF_CanLeaveVehicle = false
                        SetPedCombatAttributes(g.ped, 2, true)  -- BF_CanDoDrivebys = true
                        SetPedCombatAttributes(g.ped, 1, true)  -- BF_CanUseVehicles = true

                        for s = -1, 16 do
                            if GetPedInVehicleSeat(playerVeh, s) == g.ped then
                                assignedSeats[s] = true
                            end
                        end
                    elseif g.assignedSeat and IsPedGettingIntoAVehicle(g.ped) then
                        assignedSeats[g.assignedSeat] = true
                    end
                end
            end

            for _, g in ipairs(spawnedGuards) do
                if DoesEntityExist(g.ped) and not IsEntityDead(g.ped) then
                    local gVeh = GetVehiclePedIsIn(g.ped, false)
                    -- Si el guardia no está en el auto del jugador
                    if gVeh ~= playerVeh then
                        -- Asignar un asiento o torreta libre único que nadie más esté usando
                        local seatToUse = nil
                        for _, s in ipairs(availableSeats) do
                            if not assignedSeats[s] then
                                seatToUse = s
                                assignedSeats[s] = true
                                break
                            end
                        end

                        if seatToUse ~= nil then
                            g.assignedSeat = seatToUse
                            -- Subir al auto del jugador al asiento o torreta correspondiente
                            if not IsPedGettingIntoAVehicle(g.ped) or gVeh ~= 0 then
                                TaskEnterVehicle(g.ped, playerVeh, -1, seatToUse, 2.0, 1, 0)
                            end
                        else
                            -- No hay asientos disponibles en el auto del jugador (auto completamente lleno)
                            table.insert(myGuardsWithoutSeat, g)
                        end
                    else
                        g.assignedSeat = nil
                    end
                end
            end

            -- Si no cupieron todos los guardias en el auto del jugador, buscar un auto cercano para seguirlo en convoy
            if #myGuardsWithoutSeat > 0 then
                local escortVeh = nil
                -- Buscar si alguno ya está de chofer en un auto secundario
                for _, g in ipairs(myGuardsWithoutSeat) do
                    local gVeh = GetVehiclePedIsIn(g.ped, false)
                    if gVeh ~= 0 and gVeh ~= playerVeh then
                        escortVeh = gVeh
                        break
                    end
                end

                -- Si ninguno tiene auto, buscar el vehículo más cercano disponible en 30 metros
                if not escortVeh then
                    local gCoords = GetEntityCoords(myGuardsWithoutSeat[1].ped)
                    local closest = GetClosestVehicle(gCoords.x, gCoords.y, gCoords.z, 30.0, 0, 71)
                    if closest ~= 0 and closest ~= playerVeh then
                        escortVeh = closest
                    end
                end

                if escortVeh and DoesEntityExist(escortVeh) then
                    -- Registrar vehículo de convoy para su control y limpieza
                    local foundConvoy = false
                    for _, cv in ipairs(trackedConvoyVehicles) do
                        if cv.vehicle == escortVeh then
                            foundConvoy = true
                            cv.lastUsed = GetGameTimer()
                            break
                        end
                    end
                    if not foundConvoy then
                        table.insert(trackedConvoyVehicles, {
                            vehicle = escortVeh,
                            lastUsed = GetGameTimer(),
                        })
                    end

                    local driver = GetPedInVehicleSeat(escortVeh, -1)
                    if driver == 0 and not IsVehicleSeatFree(escortVeh, 0) then
                        driver = GetPedInVehicleSeat(escortVeh, 0) -- Soporte RHD
                    end

                    for _, g in ipairs(myGuardsWithoutSeat) do
                        local gVeh = GetVehiclePedIsIn(g.ped, false)
                        if gVeh ~= escortVeh and not IsPedGettingIntoAVehicle(g.ped) then
                            if driver == 0 or driver == g.ped then
                                -- Subirse como chofer
                                TaskEnterVehicle(g.ped, escortVeh, -1, -1, 2.0, 1, 0)
                                driver = g.ped
                            else
                                -- Subirse como pasajero en el vehículo de escolta
                                local escortSeats = getAvailableVehicleSeats(escortVeh, driver)
                                for _, s in ipairs(escortSeats) do
                                    TaskEnterVehicle(g.ped, escortVeh, -1, s, 2.0, 1, 0)
                                    break
                                end
                            end
                        elseif gVeh == escortVeh and (GetPedInVehicleSeat(escortVeh, -1) == g.ped or GetPedInVehicleSeat(escortVeh, 0) == g.ped) then
                            -- El chofer escolta al auto del jugador
                            TaskVehicleEscort(g.ped, escortVeh, playerVeh, -1, 45.0, 786603, 12.0, 0, 20.0)
                        end
                    end
                end
            end

        -- 2. Si el jugador está caminando / a pie
        else
            for _, g in ipairs(spawnedGuards) do
                g.assignedSeat = nil
                if DoesEntityExist(g.ped) and not IsEntityDead(g.ped) then
                    -- Al bajarse el jugador, permitir bajarse del vehículo y luchar a pie
                    SetPedCombatAttributes(g.ped, 3, true) -- BF_CanLeaveVehicle = true

                    local gVeh = GetVehiclePedIsIn(g.ped, false)
                    -- Si el guardia seguía en un auto, bajarse de inmediato
                    if gVeh ~= 0 and not IsPedInCombat(g.ped) then
                        TaskLeaveVehicle(g.ped, gVeh, 0)
                    else
                        -- Escoltando a pie
                        if not IsPedInCombat(g.ped) then
                            local pCoords = GetEntityCoords(playerPed)
                            local gCoords = GetEntityCoords(g.ped)
                            local dist = #(pCoords - gCoords)

                            -- Si se quedó muy atrás (> 18m), correr hacia el jugador
                            if dist > 18.0 then
                                TaskGoToEntity(g.ped, playerPed, -1, 3.0, 2.5, 1073741824, 0)
                            end
                        end
                    end
                end
            end
        end

        -- Vehículos de escolta comprados (/bodyguard)
        for _, v in ipairs(spawnedVehicles) do
            if DoesEntityExist(v.driver) and DoesEntityExist(v.vehicle) then
                local target = playerVeh ~= 0 and playerVeh or playerPed
                TaskVehicleEscort(v.driver, v.vehicle, target, -1, 40.0, 786603, 10.0, 0, 20.0)
            end
        end
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Sistema de Combate: Ataque forzado a jugadores, npcs o vehículos atacados
-- ─────────────────────────────────────────────────────────────────────────────
CreateThread(function()
    while true do
        Wait(200)
        local ped = PlayerPedId()

        -- Sincronizar arma en mano, grupo y prevenir fuego amigo hacia el jugador
        local playerGroupHash = GetPedRelationshipGroupHash(ped)
        
        for _, g in ipairs(spawnedGuards) do
            if DoesEntityExist(g.ped) and not IsEntityDead(g.ped) then
                -- Sincronizar grupo si el jugador cambia de facción
                if GetPedRelationshipGroupHash(g.ped) ~= playerGroupHash then
                    SetPedRelationshipGroupHash(g.ped, playerGroupHash)
                end

                -- Sincronizar arma
                if IsPedArmed(ped, 7) and GetSelectedPedWeapon(g.ped) ~= g.weapon then
                    SetCurrentPedWeapon(g.ped, g.weapon, true)
                end

                -- Forzar ignorar al jugador (por si se les apunta y se vuelven hostiles)
                local currentTarget = GetPedTargetFromCombatPed(g.ped)
                if currentTarget == ped then
                    ClearPedTasks(g.ped)
                end
            end
        end

        for _, v in ipairs(spawnedVehicles) do
            if DoesEntityExist(v.driver) and not IsEntityDead(v.driver) then
                if GetPedRelationshipGroupHash(v.driver) ~= playerGroupHash then
                    SetPedRelationshipGroupHash(v.driver, playerGroupHash)
                end
                
                if GetPedTargetFromCombatPed(v.driver) == ped then
                    ClearPedTasks(v.driver)
                end
            end
        end

        local isShooting = IsPedShooting(ped)
        local isAiming = IsPlayerFreeAiming(PlayerId())
        local target = 0

        -- 1. Si el jugador está apuntando a alguien o a algo
        if isAiming or isShooting then
            local hasTarget, aimTarget = GetEntityPlayerIsFreeAimingAt(PlayerId())
            if not hasTarget then
                hasTarget, aimTarget = GetPlayerTargetEntity(PlayerId())
            end
            if hasTarget and DoesEntityExist(aimTarget) then
                target = aimTarget
            end
        end

        -- 2. Si el jugador disparó contra un vehículo o ubicación (impacto de bala)
        if target == 0 and isShooting then
            local hasImpact, impactCoord = GetPedLastWeaponImpactCoord(ped)
            if hasImpact then
                local hitVeh = GetClosestVehicle(impactCoord.x, impactCoord.y, impactCoord.z, 4.0, 0, 71)
                local pVeh = GetVehiclePedIsIn(ped, false)
                if hitVeh ~= 0 and hitVeh ~= pVeh then
                    target = hitVeh
                end
            end
        end

        -- 3. Si estás en combate cuerpo a cuerpo
        if target == 0 then
            local hasTarget, combatTarget = GetMeleeTargetForPed(ped)
            if hasTarget and combatTarget ~= 0 and IsEntityAPed(combatTarget) then
                target = combatTarget
            end
        end

        -- 4. Si el jugador recibió daño recientemente
        if target == 0 then
            local attacker = GetPedSourceOfDamage(ped)
            if attacker ~= 0 and IsEntityAPed(attacker) then
                target = attacker
            end
        end

        -- Ordenar ataque al objetivo
        if target ~= 0 and target ~= ped then
            local isMyGuard = false
            for _, g in ipairs(spawnedGuards) do
                if g.ped == target then isMyGuard = true; break end
            end

            if not isMyGuard then
                -- Objetivo: PED (Jugador o NPC enemigo)
                if IsEntityAPed(target) then
                    for _, g in ipairs(spawnedGuards) do
                        if DoesEntityExist(g.ped) and not IsEntityDead(g.ped) then
                            if GetPedTargetFromCombatPed(g.ped) ~= target then
                                TaskCombatPed(g.ped, target, 0, 16)
                            end
                        end
                    end

                -- Objetivo: VEHÍCULO
                elseif IsEntityAVehicle(target) then
                    -- Comprobar si hay ocupantes dentro del vehículo para eliminarlos
                    local numSeats = GetVehicleModelNumberOfSeats(GetEntityModel(target))
                    local occupant = 0
                    for s = -1, numSeats - 2 do
                        local p = GetPedInVehicleSeat(target, s)
                        if p ~= 0 and DoesEntityExist(p) and not IsEntityDead(p) then
                            local isGuardPed = false
                            for _, g in ipairs(spawnedGuards) do
                                if g.ped == p then isGuardPed = true; break end
                            end
                            if not isGuardPed and p ~= ped then
                                occupant = p
                                break
                            end
                        end
                    end

                    for _, g in ipairs(spawnedGuards) do
                        if DoesEntityExist(g.ped) and not IsEntityDead(g.ped) then
                            if occupant ~= 0 then
                                TaskCombatPed(g.ped, occupant, 0, 16)
                            else
                                TaskShootAtEntity(g.ped, target, 2500, 7)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Compra: Recibir resultado del servidor
-- ─────────────────────────────────────────────────────────────────────────────
RegisterNetEvent('bodyguard:client:purchaseResult', function(success)
    if not pendingPurchase then return end

    if success then
        local ptype = pendingPurchase.type
        local pdata = pendingPurchase.data

        if ptype == 'guard' then
            SpawnBodyguard(pdata)
        elseif ptype == 'vehicle' then
            SpawnEscortVehicle(pdata)
        elseif ptype == 'wanted' then
            RemoveWantedLevel()
        end
    else
        notify('~r~No se pudo completar la operación.')
    end

    pendingPurchase = nil
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Request functions para menu.lua
-- ─────────────────────────────────────────────────────────────────────────────
function RequestGuardPurchase(guardConfig)
    if countActiveGuards() >= Config.MaxBodyguards then
        notify(Config.Locales.maxReached:format(countActiveGuards(), Config.MaxBodyguards))
        return
    end
    pendingPurchase = { type = 'guard', data = guardConfig }
    TriggerServerEvent('bodyguard:server:purchase', guardConfig.id)
end

function RequestVehiclePurchase(vehConfig)
    pendingPurchase = { type = 'vehicle', data = vehConfig }
    TriggerServerEvent('bodyguard:server:purchase', vehConfig.id)
end

function RequestWantedRemoval()
    local pid = PlayerId()
    if GetPlayerWantedLevel(pid) <= 0 then
        notify(Config.Locales.wantedNone)
        return
    end
    pendingPurchase = { type = 'wanted', data = {} }
    TriggerServerEvent('bodyguard:server:purchase', 'remove_wanted')
end

function GetGuardCount()
    return countActiveGuards(), Config.MaxBodyguards
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Cleanup
-- ─────────────────────────────────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    DismissAll()
end)

RegisterCommand(Config.DismissCommand, function()
    DismissAll()
end, false)

TriggerEvent('chat:addSuggestion', '/' .. Config.DismissCommand, 'Despedir a todos los guardaespaldas y vehículos')

-- ─────────────────────────────────────────────────────────────────────────────
-- Toggle World NPCs (Traffic, Peds, Cars)
-- ─────────────────────────────────────────────────────────────────────────────
local worldNPCsDisabled = false

RegisterNetEvent('bodyguard:client:toggleWorldNPCs', function()
    worldNPCsDisabled = not worldNPCsDisabled

    if worldNPCsDisabled then
        notify('~y~Tráfico y NPCs desactivados del mundo.')
        
        -- Limpiar inmediatamente los de la zona
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        ClearAreaOfVehicles(coords.x, coords.y, coords.z, 1000.0, false, false, false, false, false)
        ClearAreaOfPeds(coords.x, coords.y, coords.z, 1000.0, 1)
        
        -- Hilo para forzar la densidad a 0
        CreateThread(function()
            while worldNPCsDisabled do
                Wait(0)
                SetVehicleDensityMultiplierThisFrame(0.0)
                SetPedDensityMultiplierThisFrame(0.0)
                SetRandomVehicleDensityMultiplierThisFrame(0.0)
                SetParkedVehicleDensityMultiplierThisFrame(0.0)
                SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)
                SetGarbageTrucks(false)
                SetRandomBoats(false)
            end
        end)
    else
        notify('~g~Tráfico y NPCs reactivados.')
        SetGarbageTrucks(true)
        SetRandomBoats(true)
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Welcome Message
-- ─────────────────────────────────────────────────────────────────────────────
local hasShownWelcome = false
AddEventHandler('playerSpawned', function()
    if not hasShownWelcome then
        hasShownWelcome = true
        Wait(5000)
        TriggerEvent('chat:addMessage', {
            color = {255, 255, 0},
            multiline = true,
            args = {"SISTEMA", "¡Bienvenido! Usa la tecla ^2B^0 o ^2/servicemenu^0 para abrir el ^3Service Menu^0. Desde ahí podrás elegir tu facción (Pocha, Yoma, GN) y reclutar guardaespaldas desde cualquier lugar."}
        })
    end
end)
