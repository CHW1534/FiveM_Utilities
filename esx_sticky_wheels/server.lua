-- ============================================================================
-- Sticky Wheels / Parked Steering - Server Sync
-- ============================================================================

RegisterNetEvent('sticky_wheels:setSteering', function(netId, angle)
    if type(netId) ~= 'number' then return end
    if type(angle) ~= 'number' then return end

    local veh = NetworkGetEntityFromNetworkId(netId)
    if veh == 0 or not DoesEntityExist(veh) then return end

    local state = Entity(veh).state
    if math.abs(angle) > 2.0 then
        state:set('ps_angle', angle, true)
    else
        state:set('ps_angle', nil, true)
    end
end)

RegisterNetEvent('sticky_wheels:clearSteering', function(netId)
    if type(netId) ~= 'number' then return end

    local veh = NetworkGetEntityFromNetworkId(netId)
    if veh == 0 or not DoesEntityExist(veh) then return end

    local state = Entity(veh).state
    state:set('ps_angle', nil, true)
end)

-- Backward compatibility with older clients or events
RegisterNetEvent('parksteer:setState', function(netId, bias, active)
    if type(netId) ~= 'number' then return end

    local veh = NetworkGetEntityFromNetworkId(netId)
    if veh == 0 or not DoesEntityExist(veh) then return end

    local state = Entity(veh).state
    if active and type(bias) == 'number' and math.abs(bias) > 0.02 then
        state:set('ps_angle', bias * 38.0, true)
    else
        state:set('ps_angle', nil, true)
    end
end)