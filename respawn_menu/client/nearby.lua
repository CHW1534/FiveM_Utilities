-- ─────────────────────────────────────────────────────────────────────────────
-- respawn_menu / client/nearby.lua
-- Algoritmo de cálculo de punto de respawn seguro cercano (estilo GTA V Online)
-- Basado en Flamtky/fivem-respawn-nearby:
--   - Encuentra nodos vehiculares fuera del radio de exclusión
--   - Localiza aceras/senderos peatonales seguros (GetSafeCoordForPed)
--   - Descarta autopistas/freeways (flags == 66)
--   - Asegura altura del suelo (GetGroundZFor_3dCoord)
--   - Orienta al jugador de cara a la calle
-- ─────────────────────────────────────────────────────────────────────────────

local BATCH_SIZE = 35

local BACKUP_RESPAWN_POINTS = {
    vector3(1748.0, 3273.0, 41.1),
    vector3(-815.0, 5971.0, 17.3),
    vector3(-2009.0, 3132.0, 32.8),
    vector3(2545.0, -322.0, 92.9),
    vector3(-708.0, -1444.0, 5.0),
    vector3(-1274.0, 530.0, 71.0),
    vector3(960.0, 3766.0, 32.5),
    vector3(-3174.0, 1088.0, 20.6)
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Obtener coordenada segura en acera para peatón
-- ─────────────────────────────────────────────────────────────────────────────
local function GetSafePedCoord(x, y, z)
    local succ, footpath = GetSafeCoordForPed(x, y, z, false, 1)
    if not succ then
        succ, footpath = GetSafeCoordForPed(x, y, z, false, 16)
    end
    if not succ or not footpath then
        return false, nil
    end

    local onGround, groundZ = GetGroundZFor_3dCoord(footpath.x, footpath.y, footpath.z, 0)
    local succProp, _, flags = GetVehicleNodeProperties(x, y, z)

    -- Evitar autopistas de alta velocidad (flag 66)
    if succProp and flags == 66 then
        return false, nil
    end

    local finalZ = onGround and groundZ or footpath.z
    return true, vector3(footpath.x, footpath.y, finalZ)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Función principal: Calcular respawn seguro cercano fuera del radio
-- ─────────────────────────────────────────────────────────────────────────────
function GetSafeNearbyCoords(deathCoords, minRadius)
    local minR = minRadius or (Config.MinRespawnDistance or 150.0)
    local dx, dy, dz = deathCoords.x, deathCoords.y, deathCoords.z
    local deathV3 = vector3(dx, dy, dz)

    local offset = math.random(1, math.max(1, math.floor(minR / 8)))

    -- 1. Intentar encontrar nodo vehicular + acera peatonal fuera del radio
    for i = 1, BATCH_SIZE do
        local found, nodePos = GetNthClosestVehicleNode(dx, dy, dz, offset + (i - 1), 1, 3, 0)
        if found and nodePos then
            local dist = #(deathV3 - nodePos)
            if dist >= minR then
                local safeSucc, pedCoord = GetSafePedCoord(nodePos.x, nodePos.y, nodePos.z)
                if safeSucc and pedCoord then
                    local heading = GetHeadingFromVector_2d(pedCoord.x - nodePos.x, pedCoord.y - nodePos.y)
                    return pedCoord, heading
                end
            end
        end
    end

    -- 2. Si no se encontró acera en los primeros intentos, ampliar radio
    local expandedR = minR * 1.5
    for i = 1, 20 do
        local found, nodePos = GetNthClosestVehicleNode(dx, dy, dz, offset + i + 35, 1, 3, 0)
        if found and nodePos then
            local dist = #(deathV3 - nodePos)
            if dist >= expandedR then
                local safeSucc, pedCoord = GetSafePedCoord(nodePos.x, nodePos.y, nodePos.z)
                if safeSucc and pedCoord then
                    local heading = GetHeadingFromVector_2d(pedCoord.x - nodePos.x, pedCoord.y - nodePos.y)
                    return pedCoord, heading
                end
            end
        end
    end

    -- 3. Fallback de emergencia a puntos seguros predefinidos
    local bestPoint = BACKUP_RESPAWN_POINTS[1]
    local bestDist = 0
    for _, pt in ipairs(BACKUP_RESPAWN_POINTS) do
        local d = #(deathV3 - pt)
        if d > bestDist then
            bestDist = d
            bestPoint = pt
        end
    end

    return bestPoint, math.random(0, 360) + 0.0
end
