Config = {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Controles
-- ─────────────────────────────────────────────────────────────────────────────
Config.MenuKey         = 29        -- Tecla B (INPUT_SPECIAL_ABILITY_SECONDARY)
Config.MenuCommand     = 'bodyguard' -- /bodyguard en chat
Config.DismissCommand  = 'dismiss'   -- /dismiss para despedir a todos
Config.AdminCommand    = 'bgadmin'   -- /bgadmin para abrir panel de admin

-- ─────────────────────────────────────────────────────────────────────────────
-- Administradores
-- ─────────────────────────────────────────────────────────────────────────────
-- Lista de identificadores de admins. Cualquier identifier que coincida
-- le da acceso admin completo (panel de permisos + uso del mod).
-- Puedes usar: license, license2, discord, fivem, steam, xbl, live, ip
Config.Admins = {
    -- Tú
    'license:0e5b538e71a8cf167b68c74b9fa623d54a2d7ec9',
    'discord:435868388594548737',
    'fivem:1716096',
    -- Tu amigo
    'license:ee6510b2529dec97406683f656bff2bcc3417bb2',
    'discord:505210050516746241',
    'fivem:18087537',
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Acceso por Defecto
-- ─────────────────────────────────────────────────────────────────────────────
-- true  = TODOS pueden usar guardaespaldas. Admins pueden revocar a individuos.
-- false = NADIE puede usarlo por defecto. Admins deben dar permiso individual.
Config.DefaultAccess = true

-- ─────────────────────────────────────────────────────────────────────────────
-- Límites
-- ─────────────────────────────────────────────────────────────────────────────
Config.MaxBodyguards   = 7          -- Máximo de peds en un grupo GTA V
Config.SpawnDistance   = 3.0        -- Distancia de spawn respecto al jugador
Config.VehicleSpawnDist = 8.0      -- Distancia de spawn de vehículos

-- ─────────────────────────────────────────────────────────────────────────────
-- Limpieza Automática Fuera de Uso (Vehículos y NPCs Anti-Saturación)
-- ─────────────────────────────────────────────────────────────────────────────
Config.AutoCleanupUnusedVehicles   = true   -- true = Eliminar automáticamente vehículos fuera de uso
Config.VehicleCleanupMinutes       = 5      -- Minutos sin uso antes de eliminar automáticamente (5 min)
Config.VehicleCleanupRadius        = 1000.0 -- Radio en metros (1 km) a la redonda del jugador para limpiar vehículos
Config.AutoCleanupUnusedNPCs       = true   -- true = Eliminar automáticamente NPCs rezagados/abandonados
Config.NPCCleanupMinutes           = 5      -- Minutos rezagados a gran distancia antes de eliminar automáticamente (5 min)
Config.NPCAbandonedDistance        = 120.0  -- Distancia en metros para considerar a un NPC como rezagado/abandonado

-- ─────────────────────────────────────────────────────────────────────────────
-- Tiers de Guardaespaldas
-- ─────────────────────────────────────────────────────────────────────────────
Config.BodyguardTiers = {
    {
        id          = 'tier1',
        label       = 'Guardaespaldas Novato',
        description = 'Armado con pistola. Protección básica.',
        health      = 400,
        armor       = 0,
        weapon      = 'WEAPON_PISTOL',
        model       = 's_m_m_security_01',
        accuracy    = 40,
    },
    {
        id          = 'tier2',
        label       = 'Guardaespaldas Veterano',
        description = 'SMG y chaleco. Experiencia en combate.',
        health      = 650,
        armor       = 50,
        weapon      = 'WEAPON_SMG',
        model       = 's_m_y_blackops_01',
        accuracy    = 55,
    },
    {
        id          = 'tier3',
        label       = 'Guardaespaldas Élite',
        description = 'Rifle de asalto y armadura completa. Letal.',
        health      = 1000,
        armor       = 100,
        weapon      = 'WEAPON_CARBINERIFLE',
        model       = 's_m_y_swat_01',
        accuracy    = 70,
    },
    {
        id          = 'tier4',
        label       = 'Guardaespaldas Leyenda',
        description = 'Ametralladora pesada. Prácticamente un tanque.',
        health      = 2000,
        armor       = 200,
        weapon      = 'WEAPON_MG',
        model       = 's_m_y_marine_01',
        accuracy    = 85,
    },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Guardaespaldas Personalizados
-- ─────────────────────────────────────────────────────────────────────────────
Config.CustomBodyguards = {
    {
        id          = 'custom1',
        label       = 'Agente Custom 1',
        description = 'Guardaespaldas personalizado #1',
        health      = 100,
        armor       = 0,
        weapon      = 'WEAPON_PISTOL',
        model       = 'ig_andreas',
        accuracy    = 50,
    },
    {
        id          = 'custom2',
        label       = 'Agente Custom 2',
        description = 'Guardaespaldas personalizado #2',
        health      = 100,
        armor       = 0,
        weapon      = 'WEAPON_PISTOL',
        model       = 'ig_andreas',
        accuracy    = 50,
    },
    {
        id          = 'custom3',
        label       = 'Agente Custom 3',
        description = 'Guardaespaldas personalizado #3',
        health      = 100,
        armor       = 0,
        weapon      = 'WEAPON_PISTOL',
        model       = 'ig_andreas',
        accuracy    = 50,
    },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Vehículos de Escolta (Predefinidos)
-- ─────────────────────────────────────────────────────────────────────────────
Config.EscortVehicles = {
    {
        id          = 'schafter',
        label       = 'Schafter',
        description = 'Sedán blindado rápido.',
        model       = 'schafter2',
        driverModel = 's_m_m_security_01',
        driverWeapon = 'WEAPON_PISTOL',
    },
    {
        id          = 'dubsta',
        label       = 'Dubsta',
        description = 'SUV resistente para terreno difícil.',
        model       = 'dubsta',
        driverModel = 's_m_y_blackops_01',
        driverWeapon = 'WEAPON_SMG',
    },
    {
        id          = 'baller',
        label       = 'Baller',
        description = 'SUV de lujo con blindaje.',
        model       = 'baller5',
        driverModel = 's_m_y_swat_01',
        driverWeapon = 'WEAPON_CARBINERIFLE',
    },
    {
        id          = 'insurgent',
        label       = 'Insurgent',
        description = 'Vehículo militar blindado. Imparable.',
        model       = 'insurgent',
        driverModel = 's_m_y_marine_01',
        driverWeapon = 'WEAPON_MG',
    },
    {
        id          = 'turbosdirtywhore',
        label       = 'Polaris RZR Turbo S',
        description = 'RZR Turbo S Dirty Whore todoterreno.',
        model       = 'turbosdirtywhore',
        driverModel = 's_m_m_security_01',
        driverWeapon = 'WEAPON_CARBINERIFLE',
    },
    {
        id          = 'swuey22rs',
        label       = 'Can-Am Maverick X RS',
        description = '2022 Maverick X RS Turbo de alto rendimiento.',
        model       = 'swuey22rs',
        driverModel = 's_m_m_security_01',
        driverWeapon = 'WEAPON_CARBINERIFLE',
    },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Vehículos de Escolta (Custom)
-- ─────────────────────────────────────────────────────────────────────────────
Config.CustomVehicles = {
    {
        id          = 'vcustom1',
        label       = 'Vehículo Custom 1',
        description = 'Vehículo personalizado #1',
        model       = 'baller5',
        driverModel = 's_m_m_security_01',
        driverWeapon = 'WEAPON_PISTOL',
    },
    {
        id          = 'vcustom2',
        label       = 'Vehículo Custom 2',
        description = 'Vehículo personalizado #2',
        model       = 'baller5',
        driverModel = 's_m_m_security_01',
        driverWeapon = 'WEAPON_PISTOL',
    },
    {
        id          = 'vcustom3',
        label       = 'Vehículo Custom 3',
        description = 'Vehículo personalizado #3',
        model       = 'baller5',
        driverModel = 's_m_m_security_01',
        driverWeapon = 'WEAPON_PISTOL',
    },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Blips de Guardaespaldas
-- ─────────────────────────────────────────────────────────────────────────────
Config.BlipSprite  = 271
Config.BlipColor   = 3
Config.BlipScale   = 0.7
Config.BlipLabel   = 'Guardaespaldas'

-- ─────────────────────────────────────────────────────────────────────────────
-- Blips de Vehículos de Escolta
-- ─────────────────────────────────────────────────────────────────────────────
Config.VehicleBlipSprite = 225
Config.VehicleBlipColor  = 38
Config.VehicleBlipScale  = 0.75

-- ─────────────────────────────────────────────────────────────────────────────
-- Textos / Localización
-- ─────────────────────────────────────────────────────────────────────────────
Config.Locales = {
    menuTitle        = 'GUARDAESPALDAS',
    buySuccess       = '~g~Contratado:~w~ %s',
    maxReached       = '~r~Máximo de guardaespaldas alcanzado~w~ (%d/%d)',
    dismissed        = '~y~Todos los guardaespaldas han sido despedidos.',
    wantedRemoved    = '~g~Nivel de búsqueda eliminado.',
    wantedNone       = '~y~No tienes nivel de búsqueda.',
    vehicleBought    = '~g~Vehículo de escolta desplegado:~w~ %s',
    noPermission     = '~r~No tienes permiso para usar guardaespaldas.',
    notAdmin         = '~r~No eres administrador.',
}
