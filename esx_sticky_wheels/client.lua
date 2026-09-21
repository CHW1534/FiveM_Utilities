-- ============================================================================
-- Sticky Wheels / Parked Steering - Standalone & Optimized
-- Compatible with FiveM (All builds, Standalone, vMenu, ESX, QBCore)
-- ============================================================================

local activeVehicles = {}
local exiting = false

-- Classes to exclude: 8 (Motorcycles), 13 (Cycles), 14 (Boats), 15 (Helicopters), 16 (Planes), 21 (Trains)
local function isEligibleVehicle(veh)
    if veh == 0 or not DoesEntityExist(veh) then return false end
    local class = GetVehicleClass(veh)
    if class == 8 or class == 13 or class == 14 or class == 15 or class == 16 or class == 21 then
        return false
    end
    return true
end

local function clamp(v, min, max)
    if v < min then return min end
    if v > max then return max end
    return v
end

-- ----------------------------------------------------------------------------
-- State Bag Sync: detect when a vehicle has a sticky wheel angle set
-- ----------------------------------------------------------------------------
AddStateBagChangeHandler('ps_angle', nil, function(bagName, key, value)
    local veh = GetEntityFromStateBagName(bagName)
    if veh ~= 0 and DoesEntityExist(veh) then
        if value and type(value) == 'number' and math.abs(value) > 2.0 then
            activeVehicles[veh] = value
        else
            activeVehicles[veh] = nil
            SetVehicleSteerBias(veh, 0.0)
            SetVehicleSteeringAngle(veh, 0.0)
        end
    end
end)

-- ----------------------------------------------------------------------------
-- Periodic scan to index existing vehicles in pool that already have the state
-- ----------------------------------------------------------------------------
CreateThread(function()
    while true do
        local pool = GetGamePool('CVehicle')
        for i = 1, #pool do
            local veh = pool[i]
            if DoesEntityExist(veh) and isEligibleVehicle(veh) then
                local angle = Entity(veh).state.ps_angle
                if angle and type(angle) == 'number' and math.abs(angle) > 2.0 then
                    activeVehicles[veh] = angle
                elseif activeVehicles[veh] and (not angle or math.abs(angle) <= 2.0) then
                    activeVehicles[veh] = nil
                end
            end
        end
        Wait(1500)
    end
end)

-- ----------------------------------------------------------------------------
-- Render Loop: applies steering angle smoothly every frame for nearby parked cars
-- ----------------------------------------------------------------------------
CreateThread(function()
    while true do
        local waitTime = 500
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local hasNearby = false

        for veh, angle in pairs(activeVehicles) do
            if DoesEntityExist(veh) then
                local driver = GetPedInVehicleSeat(veh, -1)
                if driver == 0 then
                    local vehCoords = GetEntityCoords(veh)
                    local dist = #(playerCoords - vehCoords)

                    -- Only process vehicles within visible range (45 meters)
                    if dist < 45.0 then
                        hasNearby = true
                        SetVehicleSteeringAngle(veh, angle)
                        SetVehicleSteerBias(veh, angle / 40.0)
                    end
                else
                    -- A driver entered the vehicle: release control
                    activeVehicles[veh] = nil
                    if driver == playerPed then
                        local netId = NetworkGetNetworkIdFromEntity(veh)
                        if netId ~= 0 then
                            TriggerServerEvent('sticky_wheels:clearSteering', netId)
                        end
                    end
                end
            else
                activeVehicles[veh] = nil
            end
        end

        if hasNearby then
            Wait(0)
        else
            Wait(waitTime)
        end
    end
end)

-- ----------------------------------------------------------------------------
-- Driver Exit Detection: captures wheel angle when driver exits vehicle
-- ----------------------------------------------------------------------------
CreateThread(function()
    local lastRecordedAngle = 0.0

    while true do
        local sleep = 250
        local ped = PlayerPedId()

        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)

            if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped and isEligibleVehicle(veh) then
                sleep = 0

                -- Continuously record current wheel angle / steer input while driving
                local steerInput = -GetControlNormal(0, 59) -- Left is positive, Right is negative
                local currentAngle = GetVehicleSteeringAngle(veh)

                if math.abs(steerInput) > 0.15 then
                    lastRecordedAngle = clamp(steerInput * 38.0, -40.0, 40.0)
                elseif math.abs(currentAngle) > 3.0 then
                    lastRecordedAngle = clamp(currentAngle, -40.0, 40.0)
                else
                    lastRecordedAngle = 0.0
                end

                -- Detect exit intention (INPUT_VEH_EXIT = 75, typically F or Enter)
                local isExiting = IsControlJustPressed(0, 75) or GetIsTaskActive(ped, 160)
                if isExiting and not exiting then
                    local speed = GetEntitySpeed(veh) * 3.6 -- km/h

                    -- Only save if parked or low speed (< 25 km/h) and wheels are turned
                    if speed < 25.0 and math.abs(lastRecordedAngle) > 3.0 then
                        exiting = true
                        local savedVeh = veh
                        local targetAngle = lastRecordedAngle

                        local netId = NetworkGetNetworkIdFromEntity(savedVeh)
                        if netId == 0 then
                            NetworkRegisterEntityAsNetworked(savedVeh)
                            Wait(50)
                            netId = NetworkGetNetworkIdFromEntity(savedVeh)
                        end

                        CreateThread(function()
                            local timeout = GetGameTimer() + 3500

                            -- Hold wheels turned during exit animation
                            while GetGameTimer() < timeout do
                                if not DoesEntityExist(savedVeh) then break end

                                SetVehicleSteeringAngle(savedVeh, targetAngle)
                                SetVehicleSteerBias(savedVeh, targetAngle / 40.0)

                                if not IsPedInVehicle(PlayerPedId(), savedVeh, false) then
                                    break
                                end
                                Wait(0)
                            end

                            -- Ensure vehicle has settled after ped steps out
                            for _ = 1, 20 do
                                if DoesEntityExist(savedVeh) then
                                    SetVehicleSteeringAngle(savedVeh, targetAngle)
                                    SetVehicleSteerBias(savedVeh, targetAngle / 40.0)
                                end
                                Wait(0)
                            end

                            if DoesEntityExist(savedVeh) and GetPedInVehicleSeat(savedVeh, -1) == 0 then
                                if netId ~= 0 then
                                    TriggerServerEvent('sticky_wheels:setSteering', netId, targetAngle)
                                end
                                activeVehicles[savedVeh] = targetAngle
                            end

                            Wait(500)
                            exiting = false
                        end)
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- ----------------------------------------------------------------------------
-- Cleanup on resource stop
-- ----------------------------------------------------------------------------
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end

    for veh, _ in pairs(activeVehicles) do
        if DoesEntityExist(veh) then
            SetVehicleSteerBias(veh, 0.0)
            SetVehicleSteeringAngle(veh, 0.0)
        end
    end
end)