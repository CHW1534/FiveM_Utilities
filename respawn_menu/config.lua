Config = {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Framework
-- ─────────────────────────────────────────────────────────────────────────────
Config.UseESX = true
Config.ESXExport = 'esx:getSharedObject'

-- ─────────────────────────────────────────────────────────────────────────────
-- Permisos
-- ─────────────────────────────────────────────────────────────────────────────
-- Agrega en server.cfg:
--   add_ace group.admin respawn.here allow
--   add_ace group.moderator respawn.here allow
-- O por jugador específico:
--   add_principal identifier.license:XXXX group.admin
Config.PermissionAce = 'respawn.here'

-- ALTERNATIVA: Usar ESX Job en lugar de ACE.
-- Si prefieres, cambia Config.UseACE a false y define los jobs permitidos.
Config.UseACE = true
Config.AllowedJobs = { -- Solo aplica si Config.UseACE = false
    { job = 'police',   minGrade = 3 },
    { job = 'ambulance', minGrade = 2 },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Mecánicas de Respawn
-- ─────────────────────────────────────────────────────────────────────────────
Config.MinRespawnDistance = 150.0     -- Unidades GTA mínimas desde punto de muerte
Config.AutoRespawnTime    = 30        -- Segundos para auto-respawn (0 = desactivado)
Config.IFramesDuration    = 5         -- Segundos de invulnerabilidad al revivir en el lugar
Config.HologramWarning    = 2.0       -- Segundos del aviso previo al spawn VIP (holograma)
Config.DeathDetectInterval = 250      -- ms entre checks de estado del ped (polling)
Config.RespawnFadeTime    = 500       -- ms de fade out/in al respawnear

-- ─────────────────────────────────────────────────────────────────────────────
-- Puntos de Respawn en el Mapa
-- ─────────────────────────────────────────────────────────────────────────────
-- Coordenadas GTA V. El sistema filtra en tiempo real cuáles están
-- dentro del radio de exclusión según donde murió el jugador.
Config.RespawnPoints = {
    {
        id     = 'airfield',
        label  = 'Aeródromo del Desierto',
        coords = { x = 1748.0, y = 3273.0, z = 41.1 },
        heading = 320.0
    },
    {
        id     = 'north_dock',
        label  = 'Muelle Norte',
        coords = { x = -815.0, y = 5971.0, z = 17.3 },
        heading = 180.0
    },
    {
        id     = 'military_base',
        label  = 'Perímetro Militar',
        coords = { x = -2009.0, y = 3132.0, z = 32.8 },
        heading = 90.0
    },
    {
        id     = 'east_highway',
        label  = 'Autopista Este',
        coords = { x = 2545.0, y = -322.0, z = 92.9 },
        heading = 270.0
    },
    {
        id     = 'south_port',
        label  = 'Puerto Sur',
        coords = { x = -708.0, y = -1444.0, z = 5.0 },
        heading = 0.0
    },
    {
        id     = 'vinewood_hills',
        label  = 'Colinas Vinewood',
        coords = { x = -1274.0, y = 530.0, z = 71.0 },
        heading = 180.0
    },
    {
        id     = 'grand_senora',
        label  = 'Gran Senora',
        coords = { x = 960.0, y = 3766.0, z = 32.5 },
        heading = 210.0
    },
    {
        id     = 'chumash',
        label  = 'Playa Chumash',
        coords = { x = -3174.0, y = 1088.0, z = 20.6 },
        heading = 90.0
    },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Mapa GTA V — Normalización de coordenadas a pantalla
-- ─────────────────────────────────────────────────────────────────────────────
-- Límites del mapa GTA V usados para mapear coords a posición % en la imagen
Config.MapBounds = {
    minX = -4096.0,
    maxX =  4096.0,
    minY = -4096.0,
    maxY =  4096.0,
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Textos / Localización
-- ─────────────────────────────────────────────────────────────────────────────
Config.Locales = {
    title           = 'HAS CAÍDO',
    subtitle        = 'Elige un punto de despliegue',
    countdown       = 'Respawn automático en',
    btnRespawnHere  = 'REVIVIR EN EL LUGAR',
    btnDeploy       = 'DESPLEGAR EN ZONA',
    btnDeployWait   = 'SELECCIONA UN PUNTO',
    lockedTooltip   = 'Requiere rango táctico avanzado',
    tooClose        = 'Zona en conflicto. Selecciona a más de %dm.',
    iFramesMsg      = '~b~Campo de fuerza activo~w~ — Invulnerable por %d segundos.',
    respawnHereMsg  = 'Reviviendo en posición de combate...',
    deployMsg       = 'Desplegando en %s...',
    hologramWarning = '⚠ DESPLIEGUE HOSTIL INMINENTE ⚠',
    noPointSelected = 'Selecciona un punto de despliegue en el mapa.',
}
