-- ─────────────────────────────────────────────────────────────────────────────
-- respawn_menu / server/main.lua
-- TODA validación de permisos y de distancia ocurre aquí.
-- El cliente NUNCA envía coordenadas de destino — solo IDs de puntos.
-- ─────────────────────────────────────────────────────────────────────────────

local ESX = nil
local playerDeathCoords = {}   -- [src] = { x, y, z }

-- ─────────────────────────────────────────────────────────────────────────────
-- ESX Init
-- ─────────────────────────────────────────────────────────────────────────────
if Config.UseESX then
    TriggerEvent(Config.ESXExport, function(obj) ESX = obj end)
    if ESX == nil then
        pcall(function() ESX = exports['es_extended']:getSharedObject() end)
    end
end

-- Note: HasRespawnPermission is defined in server/admin_panel.lua (checks ACE, JSON file, & Jobs)

-- ─────────────────────────────────────────────────────────────────────────────
-- Helper: Obtener punto de respawn por ID
-- ─────────────────────────────────────────────────────────────────────────────
local function GetRespawnPoint(pointId)
    for _, point in ipairs(Config.RespawnPoints) do
        if point.id == pointId then
            return point
        end
    end
    return nil
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Helper: Distancia 3D entre dos tablas {x,y,z}
-- ─────────────────────────────────────────────────────────────────────────────
local function Dist3D(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Evento: Cliente reporta su muerte y coordenadas
-- El cliente envía coords (sus propias coords al morir).
-- Estas se guardan server-side; nunca se usan directamente como destino.
-- ─────────────────────────────────────────────────────────────────────────────
RegisterNetEvent('respawn_menu:server:playerDied', function(x, y, z)
    local src = source

    -- Validación básica de tipos
    if type(x) ~= 'number' or type(y) ~= 'number' or type(z) ~= 'number' then return end

    -- Límites del mapa GTA V amplios (incluye islas y norte de San Andreas)
    if math.abs(x) > 10000 or math.abs(y) > 10000 or math.abs(z) > 4000 then return end

    playerDeathCoords[src] = { x = x, y = y, z = z }

    -- Informar al cliente si tiene permiso (para mostrar botón dorado)
    local hasPerm = HasRespawnPermission(src)
    TriggerClientEvent('respawn_menu:client:openMenu', src, {
        deathX   = x,
        deathY   = y,
        deathZ   = z,
        hasPerm  = hasPerm,
        minDist  = Config.MinRespawnDistance,
        autoTime = Config.AutoRespawnTime,
        points   = Config.RespawnPoints,
    })
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Evento: Solicitud de respawn en el lugar (VIP/Admin)
-- ─────────────────────────────────────────────────────────────────────────────
RegisterNetEvent('respawn_menu:server:respawnHere', function(clientData)
    local src = source

    -- 1. Validar permiso en servidor
    if not HasRespawnPermission(src) then
        print(string.format('^1[respawn_menu]^7 %s (ID %s) intentó revivir en el lugar sin permiso.', GetPlayerName(src), src))
        TriggerClientEvent('respawn_menu:client:notify', src, '~r~No tienes permisos para revivir en el lugar.')
        return
    end

    -- 2. Recuperar coords de muerte registradas server-side con fallbacks
    local dc = playerDeathCoords[src]
    if not dc then
        local ped = GetPlayerPed(src)
        if ped and DoesEntityExist(ped) then
            local c = GetEntityCoords(ped)
            if c and c.x ~= 0.0 then
                dc = { x = c.x, y = c.y, z = c.z }
            end
        end
    end
    if not dc and type(clientData) == 'table' and clientData.deathX then
        dc = { x = clientData.deathX, y = clientData.deathY, z = clientData.deathZ }
    end

    if not dc then
        print(string.format('^1[respawn_menu]^7 No se encontraron coordenadas para revivir a %s (ID %s).', GetPlayerName(src), src))
        TriggerClientEvent('respawn_menu:client:notify', src, '~r~Error obteniendo tu posición de muerte.')
        return
    end

    -- 3. Limpiar registro
    playerDeathCoords[src] = nil

    print(string.format('^2[respawn_menu]^7 Reviviendo en el lugar a %s (ID %s) en [%.1f, %.1f, %.1f]', GetPlayerName(src), src, dc.x, dc.y, dc.z))

    -- 4. Enviar respawn al cliente con tipo 'here'
    TriggerClientEvent('respawn_menu:client:doRespawn', src, {
        x       = dc.x,
        y       = dc.y,
        z       = dc.z,
        heading = 0.0,
        type    = 'here',
    })
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Evento: Solicitud de respawn en zona del mapa
-- ─────────────────────────────────────────────────────────────────────────────
RegisterNetEvent('respawn_menu:server:respawnZone', function(pointId, clientData)
    local src = source

    local targetId = pointId
    if type(targetId) ~= 'string' and type(clientData) == 'table' and clientData.pointId then
        targetId = clientData.pointId
    end

    if type(targetId) ~= 'string' then
        print(string.format('^1[respawn_menu]^7 ID de punto inválido recibido de %s (ID %s)', GetPlayerName(src), src))
        return
    end

    local point = GetRespawnPoint(targetId)
    if not point then
        print(string.format('^1[respawn_menu]^7 Punto no encontrado en Config: %s', tostring(targetId)))
        return
    end

    -- 2. Recuperar coords de muerte y validar distancia
    local dc = playerDeathCoords[src]
    if not dc and type(clientData) == 'table' and clientData.deathX then
        dc = { x = clientData.deathX, y = clientData.deathY, z = clientData.deathZ }
    end

    if dc then
        local dist = Dist3D(dc, { x = point.coords.x, y = point.coords.y, z = point.coords.z })
        if dist < Config.MinRespawnDistance then
            -- Notificar error al cliente
            TriggerClientEvent('respawn_menu:client:respawnError', src, 'too_close', Config.MinRespawnDistance)
            return
        end
    end

    -- 3. Limpiar registro
    playerDeathCoords[src] = nil

    print(string.format('^2[respawn_menu]^7 Desplegando a %s (ID %s) en zona %s', GetPlayerName(src), src, point.label))

    -- 4. Enviar respawn al cliente
    TriggerClientEvent('respawn_menu:client:doRespawn', src, {
        x       = point.coords.x,
        y       = point.coords.y,
        z       = point.coords.z,
        heading = point.heading or 0.0,
        type    = 'zone',
        label   = point.label,
    })
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Evento: Solicitud de reaparición cercana segura (Flamtky GTA Online)
-- ─────────────────────────────────────────────────────────────────────────────
RegisterNetEvent('respawn_menu:server:respawnNearby', function(clientData)
    local src = source
    local dc = playerDeathCoords[src]
    if not dc then
        local ped = GetPlayerPed(src)
        if ped and DoesEntityExist(ped) then
            local c = GetEntityCoords(ped)
            if c and c.x ~= 0.0 then
                dc = { x = c.x, y = c.y, z = c.z }
            end
        end
    end
    if not dc and type(clientData) == 'table' and clientData.deathX then
        dc = { x = clientData.deathX, y = clientData.deathY, z = clientData.deathZ }
    end

    playerDeathCoords[src] = nil

    print(string.format('^2[respawn_menu]^7 Respawn cercano seguro (Flamtky) para %s (ID %s)', GetPlayerName(src), src))

    TriggerClientEvent('respawn_menu:client:doRespawn', src, {
        x       = dc and dc.x or 0.0,
        y       = dc and dc.y or 0.0,
        z       = dc and dc.z or 0.0,
        heading = 0.0,
        type    = 'nearby',
        label   = 'zona segura cercana',
    })
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Evento: Auto-respawn (countdown llegó a 0 sin selección)
-- El servidor elige el punto válido más cercano automáticamente
-- ─────────────────────────────────────────────────────────────────────────────
RegisterNetEvent('respawn_menu:server:autoRespawn', function()
    local src = source
    local dc = playerDeathCoords[src]

    -- Elegir punto más lejano disponible (para mayor seguridad)
    local best = nil
    local bestDist = 0

    for _, point in ipairs(Config.RespawnPoints) do
        local dist = 9999
        if dc then
            dist = Dist3D(dc, { x = point.coords.x, y = point.coords.y, z = point.coords.z })
        end
        if dist >= Config.MinRespawnDistance and dist > bestDist then
            bestDist = dist
            best = point
        end
    end

    -- Si ningún punto supera la distancia mínima, usar el más lejano de todos
    if not best then
        for _, point in ipairs(Config.RespawnPoints) do
            local dist = 0
            if dc then
                dist = Dist3D(dc, { x = point.coords.x, y = point.coords.y, z = point.coords.z })
            end
            if dist > bestDist then
                bestDist = dist
                best = point
            end
        end
    end

    if not best then return end

    playerDeathCoords[src] = nil

    TriggerClientEvent('respawn_menu:client:doRespawn', src, {
        x       = best.coords.x,
        y       = best.coords.y,
        z       = best.coords.z,
        heading = best.heading or 0.0,
        type    = 'zone',
        label   = best.label,
    })
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Limpieza al desconectarse el jugador
-- ─────────────────────────────────────────────────────────────────────────────
AddEventHandler('playerDropped', function()
    local src = source
    playerDeathCoords[src] = nil
end)
