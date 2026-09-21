-- ═══════════════════════════════════════════════════════════════════════════════
-- BodyGuard — Server Main
-- Sistema de permisos por identificador (sin ACE), panel admin
-- ═══════════════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────────────────────
-- State
-- ─────────────────────────────────────────────────────────────────────────────

-- Permisos otorgados por admins: { [license] = { type = 'permanent'|'session'|'partial', tiers = {...} } }
local grantedPermissions = {}

-- Cache de admins conectados: { [serverId] = true }
local adminCache = {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helper: Obtener todos los identificadores de un jugador
-- ─────────────────────────────────────────────────────────────────────────────
local function getPlayerIdentifiers(src)
    local ids = {}
    local numIds = GetNumPlayerIdentifiers(src)
    for i = 0, numIds - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id then
            table.insert(ids, id)
        end
    end
    return ids
end

--- Obtener la license principal de un jugador (para usarla como key)
local function getPlayerLicense(src)
    local numIds = GetNumPlayerIdentifiers(src)
    for i = 0, numIds - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and string.find(id, 'license:') and not string.find(id, 'license2:') then
            return id
        end
    end
    -- Fallback a cualquier identifier
    return GetPlayerIdentifier(src, 0) or ('unknown:' .. src)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Helper: Verificar si un jugador es admin
-- ─────────────────────────────────────────────────────────────────────────────
local function isAdmin(src)
    -- Check cache primero
    if adminCache[src] ~= nil then
        return adminCache[src]
    end

    local ids = getPlayerIdentifiers(src)
    for _, playerId in ipairs(ids) do
        for _, adminId in ipairs(Config.Admins) do
            if playerId == adminId then
                adminCache[src] = true
                return true
            end
        end
    end
    adminCache[src] = false
    return false
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Helper: Verificar si un jugador tiene permiso para usar guardaespaldas
-- ─────────────────────────────────────────────────────────────────────────────
local function hasPermission(src, itemId)
    -- Admins siempre tienen acceso completo
    if isAdmin(src) then return true end

    local license = getPlayerLicense(src)

    -- Verificar permisos otorgados por admin
    local perm = grantedPermissions[license]
    if perm then
        if perm.type == 'permanent' or perm.type == 'session' then
            return true
        elseif perm.type == 'partial' and perm.tiers then
            -- Solo puede usar los tiers específicos
            for _, allowedTier in ipairs(perm.tiers) do
                if allowedTier == itemId then return true end
            end
            return false
        end
        -- revoked
        if perm.type == 'revoked' then return false end
    end

    -- Default access
    return Config.DefaultAccess
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Limpiar cache al desconectarse
-- ─────────────────────────────────────────────────────────────────────────────
AddEventHandler('playerDropped', function()
    local src = source
    adminCache[src] = nil

    -- Limpiar permisos de sesión
    local license = getPlayerLicense(src)
    if grantedPermissions[license] and grantedPermissions[license].type == 'session' then
        grantedPermissions[license] = nil
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Evento: Intentar obtener un guardaespaldas/vehículo/servicio
-- ─────────────────────────────────────────────────────────────────────────────
RegisterNetEvent('bodyguard:server:purchase', function(itemId)
    local src = source

    if not hasPermission(src, itemId) then
        TriggerClientEvent('bodyguard:client:purchaseResult', src, false)
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 0, 0},
            args = {'BodyGuard', 'No tienes permiso. Pide a un admin que te lo active.'}
        })
        return
    end

    -- Validar que el item existe
    if not validateItem(itemId) then
        TriggerClientEvent('bodyguard:client:purchaseResult', src, false)
        return
    end

    TriggerClientEvent('bodyguard:client:purchaseResult', src, true)
end)

function validateItem(itemId)
    if itemId == 'dynamic_guard' or itemId == 'dynamic_vehicle' then return true end
    for _, t in ipairs(Config.BodyguardTiers) do
        if t.id == itemId then return true end
    end
    for _, c in ipairs(Config.CustomBodyguards) do
        if c.id == itemId then return true end
    end
    for _, v in ipairs(Config.EscortVehicles) do
        if v.id == itemId then return true end
    end
    for _, v in ipairs(Config.CustomVehicles) do
        if v.id == itemId then return true end
    end
    if itemId == 'remove_wanted' then return true end
    return false
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Evento: Verificar si el jugador es admin
-- ─────────────────────────────────────────────────────────────────────────────
RegisterNetEvent('bodyguard:server:checkAdmin', function()
    local src = source
    TriggerClientEvent('bodyguard:client:adminResult', src, isAdmin(src))
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Evento: Obtener lista de jugadores online (para admin panel)
-- ─────────────────────────────────────────────────────────────────────────────
RegisterNetEvent('bodyguard:server:getPlayers', function()
    local src = source
    if not isAdmin(src) then return end

    local players = {}
    for _, playerId in ipairs(GetPlayers()) do
        local pid = tonumber(playerId)
        if pid then
            local license = getPlayerLicense(pid)
            local perm = grantedPermissions[license]
            local permType = 'default'
            if perm then
                permType = perm.type
            end

            table.insert(players, {
                id       = pid,
                name     = GetPlayerName(pid) or 'Desconocido',
                license  = license,
                isAdmin  = isAdmin(pid),
                permType = permType,
            })
        end
    end

    TriggerClientEvent('bodyguard:client:playerList', src, players)
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Evento: Admin cambia permiso de un jugador
-- ─────────────────────────────────────────────────────────────────────────────
RegisterNetEvent('bodyguard:server:setPermission', function(targetId, permType, tiers)
    local src = source
    if not isAdmin(src) then return end

    local target = tonumber(targetId)
    if not target then return end

    local license = getPlayerLicense(target)
    local targetName = GetPlayerName(target) or 'Desconocido'

    if permType == 'permanent' then
        grantedPermissions[license] = { type = 'permanent' }
        TriggerClientEvent('chat:addMessage', target, {
            color = {0, 255, 0},
            args = {'BodyGuard', '¡Un admin te ha dado acceso PERMANENTE a guardaespaldas!'}
        })
    elseif permType == 'session' then
        grantedPermissions[license] = { type = 'session' }
        TriggerClientEvent('chat:addMessage', target, {
            color = {0, 255, 100},
            args = {'BodyGuard', 'Un admin te ha dado acceso TEMPORAL (esta sesión) a guardaespaldas.'}
        })
    elseif permType == 'partial' then
        grantedPermissions[license] = { type = 'partial', tiers = tiers or {'tier1', 'tier2'} }
        TriggerClientEvent('chat:addMessage', target, {
            color = {255, 200, 0},
            args = {'BodyGuard', 'Un admin te ha dado acceso PARCIAL a guardaespaldas (tiers limitados).'}
        })
    elseif permType == 'revoked' then
        grantedPermissions[license] = { type = 'revoked' }
        TriggerClientEvent('chat:addMessage', target, {
            color = {255, 0, 0},
            args = {'BodyGuard', 'Tu acceso a guardaespaldas ha sido REVOCADO por un admin.'}
        })
    elseif permType == 'default' then
        grantedPermissions[license] = nil
        TriggerClientEvent('chat:addMessage', target, {
            color = {200, 200, 200},
            args = {'BodyGuard', 'Tu permiso de guardaespaldas ha sido restaurado al default.'}
        })
    end

    -- Confirmar al admin
    TriggerClientEvent('chat:addMessage', src, {
        color = {0, 255, 0},
        args = {'BodyGuard Admin', ('Permiso de %s (ID:%d) cambiado a: %s'):format(targetName, target, permType)}
    })

    -- Refresh player list para el admin
    TriggerEvent('bodyguard:server:getPlayers')
    -- Re-trigger para que el admin vea la lista actualizada
    Wait(100)
    local players = {}
    for _, playerId in ipairs(GetPlayers()) do
        local pid = tonumber(playerId)
        if pid then
            local lic = getPlayerLicense(pid)
            local perm = grantedPermissions[lic]
            local pt = 'default'
            if perm then pt = perm.type end
            table.insert(players, {
                id       = pid,
                name     = GetPlayerName(pid) or 'Desconocido',
                license  = lic,
                isAdmin  = isAdmin(pid),
                permType = pt,
            })
        end
    end
    TriggerClientEvent('bodyguard:client:playerList', src, players)
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Limpieza de Vehículos Fuera de Uso por Radio (Server-Side 1 km)
-- ─────────────────────────────────────────────────────────────────────────────
RegisterNetEvent('bodyguard:server:cleanupVehiclesRadius', function(coords, radius)
    local src = source
    local r = radius or 1000.0
    local allVehs = GetAllVehicles()
    local deleted = 0

    for _, veh in ipairs(allVehs) do
        if DoesEntityExist(veh) then
            local vCoords = GetEntityCoords(veh)
            local dist = #(coords - vCoords)
            if dist <= r then
                -- Comprobar si hay algún jugador dentro
                local hasPlayer = false
                for _, playerSrc in ipairs(GetPlayers()) do
                    local pPed = GetPlayerPed(playerSrc)
                    if DoesEntityExist(pPed) and GetVehiclePedIsIn(pPed, false) == veh then
                        hasPlayer = true
                        break
                    end
                end

                if not hasPlayer then
                    local driver = GetPedInVehicleSeat(veh, -1)
                    -- Si no tiene conductor, o el conductor está muerto, eliminar
                    if driver == 0 or not DoesEntityExist(driver) or IsEntityDead(driver) then
                        DeleteEntity(veh)
                        deleted = deleted + 1
                    end
                end
            end
        end
    end
end)
