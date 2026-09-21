-- ─────────────────────────────────────────────────────────────────────────────
-- respawn_menu / server/admin_panel.lua
-- Panel de administración de permisos de respawn.
-- Persiste los jugadores con permiso en data/respawn_perms.json
-- ─────────────────────────────────────────────────────────────────────────────

local permittedPlayers = {}   -- { [identifier] = { name, identifier, addedBy, addedAt } }

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers de archivo JSON
-- ─────────────────────────────────────────────────────────────────────────────
local DATA_FILE = 'data/respawn_perms.json'

local function SavePermsFile()
    local list = {}
    for id, data in pairs(permittedPlayers) do
        table.insert(list, data)
    end
    -- Serializar a JSON manual (sin dependencias externas)
    local function jsonStr(s)
        return '"' .. tostring(s):gsub('"', '\\"'):gsub('\n', '\\n') .. '"'
    end
    local lines = { '[' }
    for i, entry in ipairs(list) do
        local comma = i < #list and ',' or ''
        table.insert(lines, string.format(
            '  {"identifier":%s,"name":%s,"addedBy":%s,"addedAt":%s}%s',
            jsonStr(entry.identifier),
            jsonStr(entry.name),
            jsonStr(entry.addedBy),
            jsonStr(entry.addedAt),
            comma
        ))
    end
    table.insert(lines, ']')
    SaveResourceFile(GetCurrentResourceName(), DATA_FILE, table.concat(lines, '\n'), -1)
end

local function LoadPermsFile()
    local raw = LoadResourceFile(GetCurrentResourceName(), DATA_FILE)
    if not raw or raw == '' then return end
    local ok, data = pcall(function() return json.decode(raw) end)
    if ok and type(data) == 'table' then
        for _, entry in ipairs(data) do
            if entry.identifier then
                permittedPlayers[entry.identifier] = {
                    identifier = entry.identifier,
                    name       = entry.name or entry.identifier,
                    addedBy    = entry.addedBy or 'System',
                    addedAt    = entry.addedAt or os.date('%Y-%m-%d %H:%M'),
                }
            end
        end
    else
        for identifier, name, addedBy, addedAt in raw:gmatch(
            '"identifier"%s*:%s*"([^"]+)"%s*,%s*"name"%s*:%s*"([^"]*)"%s*,%s*"addedBy"%s*:%s*"([^"]*)"%s*,%s*"addedAt"%s*:%s*"([^"]*)"'
        ) do
            permittedPlayers[identifier] = {
                identifier = identifier,
                name       = name,
                addedBy    = addedBy,
                addedAt    = addedAt,
            }
        end
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Cargar perms al iniciar el recurso
-- ─────────────────────────────────────────────────────────────────────────────
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    LoadPermsFile()
    print('^2[respawn_menu]^7 Panel de admin cargado. Permisos persistidos: ' .. tostring(#permittedPlayers))
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Helper: ¿tiene permisos el jugador?
-- (Combina ACE + lista persistente)
-- ─────────────────────────────────────────────────────────────────────────────
function HasRespawnPermission(src)
    -- 1. ACE check: respawn.here, o cualquier admin del servidor (command, admin, respawn.admin)
    if IsPlayerAceAllowed(src, Config.PermissionAce)
       or IsPlayerAceAllowed(src, 'command')
       or IsPlayerAceAllowed(src, 'admin')
       or IsPlayerAceAllowed(src, 'respawn.admin') then
        return true
    end

    -- 2. Chequear lista persistente por identifier
    local identifiers = GetPlayerIdentifiers(src)
    for _, id in ipairs(identifiers) do
        if permittedPlayers[id] then
            return true
        end
    end

    -- 3. ESX Job fallback
    if not Config.UseACE and ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            local job = xPlayer.getJob()
            for _, allowed in ipairs(Config.AllowedJobs) do
                if job.name == allowed.job and job.grade >= allowed.minGrade then
                    return true
                end
            end
        end
    end
    return false
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Helper: ¿es admin quien hace la petición?
-- ─────────────────────────────────────────────────────────────────────────────
local function IsAdmin(src)
    return IsPlayerAceAllowed(src, 'command') or IsPlayerAceAllowed(src, 'respawn.admin')
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Helper: obtener identifier principal de un jugador (license > fivem > discord)
-- ─────────────────────────────────────────────────────────────────────────────
local function GetPrimaryIdentifier(src)
    local identifiers = GetPlayerIdentifiers(src)
    local priority = { 'license:', 'fivem:', 'discord:' }
    for _, prefix in ipairs(priority) do
        for _, id in ipairs(identifiers) do
            if id:sub(1, #prefix) == prefix then
                return id
            end
        end
    end
    return identifiers[1] or 'unknown'
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Helper: construir lista de jugadores online para el panel
-- ─────────────────────────────────────────────────────────────────────────────
local function GetOnlinePlayers()
    local result = {}
    for _, playerId in ipairs(GetPlayers()) do
        local id = GetPrimaryIdentifier(tonumber(playerId))
        table.insert(result, {
            serverId    = tonumber(playerId),
            name        = GetPlayerName(tonumber(playerId)),
            identifier  = id,
            hasPerm     = permittedPlayers[id] ~= nil or IsPlayerAceAllowed(tonumber(playerId), Config.PermissionAce),
        })
    end
    return result
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Evento: Abrir panel (solo admins)
-- ─────────────────────────────────────────────────────────────────────────────
RegisterNetEvent('respawn_menu:server:openAdminPanel', function()
    local src = source
    if not IsAdmin(src) then
        TriggerClientEvent('respawn_menu:client:notify', src, '~r~No tienes permisos de administrador.')
        return
    end

    -- Construir lista de permisos persistidos
    local persistedList = {}
    for _, entry in pairs(permittedPlayers) do
        table.insert(persistedList, entry)
    end

    TriggerClientEvent('respawn_menu:client:openAdminPanel', src, {
        online    = GetOnlinePlayers(),
        persisted = persistedList,
    })
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Evento: Agregar permiso a un jugador online
-- ─────────────────────────────────────────────────────────────────────────────
RegisterNetEvent('respawn_menu:server:grantPerm', function(targetId)
    local src = source
    if not IsAdmin(src) then return end

    targetId = tonumber(targetId)
    if not targetId or not GetPlayerName(targetId) then
        TriggerClientEvent('respawn_menu:client:notify', src, '~r~Jugador no encontrado.')
        return
    end

    local identifier = GetPrimaryIdentifier(targetId)
    local name       = GetPlayerName(targetId)
    local adminName  = GetPlayerName(src)

    permittedPlayers[identifier] = {
        identifier = identifier,
        name       = name,
        addedBy    = adminName,
        addedAt    = os.date('%Y-%m-%d %H:%M'),
    }
    SavePermsFile()

    -- Notificar al objetivo
    TriggerClientEvent('respawn_menu:client:notify', targetId,
        '~g~Se te ha otorgado permiso de Respawn Táctico.')
    -- Notificar al admin
    TriggerClientEvent('respawn_menu:client:notify', src,
        '~g~Permiso otorgado a ~b~' .. name .. '~w~.')

    -- Refrescar panel del admin
    TriggerClientEvent('respawn_menu:client:openAdminPanel', src, {
        online    = GetOnlinePlayers(),
        persisted = GetPersistedList(),
    })

    print(string.format('^2[respawn_menu]^7 GRANT: %s (%s) → otorgado por %s', name, identifier, adminName))
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Evento: Agregar permiso por identifier (jugador offline)
-- ─────────────────────────────────────────────────────────────────────────────
RegisterNetEvent('respawn_menu:server:grantPermById', function(identifier, customName)
    local src = source
    if not IsAdmin(src) then return end

    if type(identifier) ~= 'string' or #identifier < 3 then
        TriggerClientEvent('respawn_menu:client:notify', src, '~r~Identifier inválido.')
        return
    end

    -- Sanitize
    identifier = identifier:match('^[%w%d:_%-%.]+$') and identifier or nil
    if not identifier then
        TriggerClientEvent('respawn_menu:client:notify', src, '~r~Identifier contiene caracteres no permitidos.')
        return
    end

    local adminName = GetPlayerName(src)
    permittedPlayers[identifier] = {
        identifier = identifier,
        name       = customName or identifier,
        addedBy    = adminName,
        addedAt    = os.date('%Y-%m-%d %H:%M'),
    }
    SavePermsFile()

    TriggerClientEvent('respawn_menu:client:notify', src,
        '~g~Permiso agregado: ~b~' .. (customName or identifier) .. '~w~.')
    TriggerClientEvent('respawn_menu:client:refreshAdminPanel', src, {
        online    = GetOnlinePlayers(),
        persisted = GetPersistedList(),
    })

    print(string.format('^2[respawn_menu]^7 GRANT (offline): %s → otorgado por %s', identifier, adminName))
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Evento: Revocar permiso por identifier
-- ─────────────────────────────────────────────────────────────────────────────
RegisterNetEvent('respawn_menu:server:revokePerm', function(identifier)
    local src = source
    if not IsAdmin(src) then return end

    if type(identifier) ~= 'string' then return end

    local entry = permittedPlayers[identifier]
    local name  = entry and entry.name or identifier
    permittedPlayers[identifier] = nil
    SavePermsFile()

    -- Notificar al objetivo si está online
    for _, playerId in ipairs(GetPlayers()) do
        local pid = GetPrimaryIdentifier(tonumber(playerId))
        if pid == identifier then
            TriggerClientEvent('respawn_menu:client:notify', tonumber(playerId),
                '~r~Tu permiso de Respawn Táctico ha sido revocado.')
            break
        end
    end

    TriggerClientEvent('respawn_menu:client:notify', src,
        '~r~Permiso revocado a ~b~' .. name .. '~w~.')
    TriggerClientEvent('respawn_menu:client:refreshAdminPanel', src, {
        online    = GetOnlinePlayers(),
        persisted = GetPersistedList(),
    })

    print(string.format('^2[respawn_menu]^7 REVOKE: %s (%s) → revocado por %s', name, identifier, GetPlayerName(src)))
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Helper: lista de persistidos como array
-- ─────────────────────────────────────────────────────────────────────────────
function GetPersistedList()
    local list = {}
    for _, v in pairs(permittedPlayers) do
        table.insert(list, v)
    end
    return list
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Comando de chat: /respawnpanel  (solo admins)
-- ─────────────────────────────────────────────────────────────────────────────
RegisterCommand('respawnpanel', function(src, args, raw)
    if src == 0 then print('Comando solo disponible in-game.') return end
    if not IsAdmin(src) then
        TriggerClientEvent('respawn_menu:client:notify', src, '~r~Sin permisos para abrir el panel.')
        return
    end
    TriggerEvent('respawn_menu:server:openAdminPanel', src) -- llamar como si fuera NetEvent del jugador
    -- Dispararlo correctamente:
    local persistedList = GetPersistedList()
    TriggerClientEvent('respawn_menu:client:openAdminPanel', src, {
        online    = GetOnlinePlayers(),
        persisted = persistedList,
    })
end, false)
