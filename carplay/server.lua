local vehicleState = {}

RegisterNetEvent('carplay:server:syncVehicle', function(netId, data)
    if not netId or netId == 0 then return end

    if data == nil or not data.isPlaying then
        -- Stop or clear: keep data but mark not playing
        if data == nil then
            vehicleState[netId] = nil
        else
            vehicleState[netId] = data
            vehicleState[netId].serverTime = nil
            vehicleState[netId].startPosition = nil
        end
    else
        local existing = vehicleState[netId]
        local now = os.time()

        -- New track or resumed playback: record server timestamp and position
        if not existing or existing.id ~= data.id or not existing.isPlaying then
            data.serverTime = now
            data.startPosition = data.position or 0
        else
            -- Same track, still playing: preserve original start reference
            data.serverTime = existing.serverTime or now
            data.startPosition = existing.startPosition or (data.position or 0)
        end

        vehicleState[netId] = data
    end

    TriggerClientEvent('carplay:client:syncVehicle', -1, netId, vehicleState[netId])
end)

RegisterNetEvent('carplay:server:requestSync', function()
    local src = source
    TriggerClientEvent('carplay:client:initSync', src, vehicleState)
end)

-- Provide server time to clients for accurate sync
RegisterNetEvent('carplay:server:getTime', function()
    local src = source
    TriggerClientEvent('carplay:client:serverTime', src, os.time())
end)
