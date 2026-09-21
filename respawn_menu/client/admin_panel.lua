-- ─────────────────────────────────────────────────────────────────────────────
-- respawn_menu / client/admin_panel.lua
-- Maneja apertura/cierre del panel de admin y sus NUI callbacks
-- ─────────────────────────────────────────────────────────────────────────────

local adminPanelOpen = false

-- ── Abrir panel (recibido desde servidor) ─────────────────────────
RegisterNetEvent('respawn_menu:client:openAdminPanel', function(data)
    adminPanelOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openAdminPanel',
        online    = data.online,
        persisted = data.persisted,
    })
end)

-- ── Refrescar datos del panel (sin cerrar/abrir) ───────────────────
RegisterNetEvent('respawn_menu:client:refreshAdminPanel', function(data)
    if not adminPanelOpen then return end
    SendNUIMessage({
        action    = 'refreshAdminPanel',
        online    = data.online,
        persisted = data.persisted,
    })
end)

-- ── Notificación genérica ──────────────────────────────────────────
RegisterNetEvent('respawn_menu:client:notify', function(msg)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(msg)
    DrawNotification(false, true)
end)

-- ── NUI: Cerrar panel ──────────────────────────────────────────────
RegisterNUICallback('closeAdminPanel', function(data, cb)
    adminPanelOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeAdminPanel' })
    cb('ok')
end)

-- ── NUI: Otorgar permiso a jugador online ─────────────────────────
RegisterNUICallback('grantPerm', function(data, cb)
    if data and data.serverId then
        TriggerServerEvent('respawn_menu:server:grantPerm', data.serverId)
    end
    cb('ok')
end)

-- ── NUI: Agregar por identifier manual (offline) ──────────────────
RegisterNUICallback('grantPermById', function(data, cb)
    if data and data.identifier then
        TriggerServerEvent('respawn_menu:server:grantPermById', data.identifier, data.name)
    end
    cb('ok')
end)

-- ── NUI: Revocar permiso ──────────────────────────────────────────
RegisterNUICallback('revokePerm', function(data, cb)
    if data and data.identifier then
        TriggerServerEvent('respawn_menu:server:revokePerm', data.identifier)
    end
    cb('ok')
end)

-- ── Comando y KeyMapping: F6 o /respawnpanel para abrir panel ───────
RegisterCommand('respawnpanel', function()
    if not adminPanelOpen then
        TriggerServerEvent('respawn_menu:server:openAdminPanel')
    else
        adminPanelOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'closeAdminPanel' })
    end
end, false)

RegisterKeyMapping('respawnpanel', 'Abrir Panel de Respawn (Admin)', 'keyboard', 'F6')
