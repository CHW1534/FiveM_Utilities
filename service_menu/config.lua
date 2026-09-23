Config = {}

-- Framework Settings
Config.UseESX = true
Config.ESXExport = 'esx:getSharedObject' -- Evento o export para ESX

-- Lista de Admins (Rockstar License)
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

-- Tecla para abrir el Service Menu (29 = Tecla B)
Config.MenuKey = 29

-- NPC Principal (Lobby / Selección de Equipos)
Config.MainNPC = {
    model = 's_m_y_swat_01',
    coords = vec4(-1038.5, -2739.8, 20.1, 330.0), -- Coordenadas (X, Y, Z, Heading)
    animDict = 'amb@world_human_cop_idles@female@idle_a',
    animName = 'idle_a',
    scenario = 'WORLD_HUMAN_COP_IDLES',
    drawDistance = 10.0,
    interactDistance = 2.5,
    blip = {
        enabled = true,
        sprite = 487, -- Icono de escudo / bandera
        color = 3, -- Azul
        scale = 0.8,
        text = 'Selección de Equipos'
    }
}

-- Blacklist de objetos: Estos ítems/armas serán removidos del inventario al cambiar de equipo o volver a Civil
Config.BlacklistItems = {
    -- Armas
    'WEAPON_CARBINERIFLE',
    'WEAPON_ASSAULTRIFLE',
    'WEAPON_SPECIALCARBINE',
    'WEAPON_COMBATPISTOL',
    'WEAPON_HEAVYPISTOL',
    'WEAPON_SMG',
    'WEAPON_PUMPSHOTGUN',
    'WEAPON_STUNGUN',
    'WEAPON_ADVANCEDRIFLE',
    'WEAPON_MACHINEPISTOL',
    'WEAPON_ASSAULTSHOTGUN',
    'WEAPON_HEAVYSNIPER',
    'WEAPON_MG',
    'WEAPON_BULLPUPRIFLE',
    'WEAPON_MICROSMG',
    'WEAPON_BULLPUPSHOTGUN',
    'WEAPON_MARKSMANRIFLE',
    -- Munición / Consumibles de equipo
    'ammo-rifle',
    'ammo-pistol',
    'ammo-shotgun',
    'armor',
    'medikit',
    'bandage'
}

-- Lista de Equipos disponibles
Config.Teams = {
    {
        id = 'yomas',
        name = 'Yomas',
        job = 'yomas',
        grade = 0,
        description = 'Fuerza Táctica. Escuadrón especial encargado de mantener el orden.',
        spawnCoords = vec4(1392.2, 1141.6, 114.3, 90.0),
        color = '#3b82f6', -- Azul
        colorGlow = 'rgba(59, 130, 246, 0.4)',
        image = 'img/yomas.jpg',
        badge = 'FUERZA TÁCTICA',
        items = {
            { name = 'WEAPON_CARBINERIFLE', count = 1, type = 'weapon' },
            { name = 'WEAPON_PUMPSHOTGUN', count = 1, type = 'weapon' },
            { name = 'WEAPON_SMG', count = 1, type = 'weapon' },
            { name = 'WEAPON_COMBATPISTOL', count = 1, type = 'weapon' },
            { name = 'WEAPON_STUNGUN', count = 1, type = 'weapon' },
            { name = 'armor', count = 2, type = 'item' },
            { name = 'medikit', count = 3, type = 'item' }
        },
        baseNPC = {
            model = 's_m_y_cop_01',
            coords = vec4(-1094.1, -835.0, 19.3, 120.0),
            scenario = 'WORLD_HUMAN_GUARD_STAND',
            blip = { enabled = true, sprite = 60, color = 3, scale = 0.7, text = 'Base Yomas' }
        }
    },
    {
        id = 'pochas',
        name = 'Pochas',
        job = 'pochas',
        grade = 0,
        description = 'Operaciones Mercenarias. Fuerza rebelde altamente armada para incursiones.',
        spawnCoords = vec4(-1098.5, -831.2, 19.3, 308.0),
        color = '#ef4444', -- Rojo
        colorGlow = 'rgba(239, 68, 68, 0.4)',
        image = 'img/pochas.jpg',
        badge = 'OPERACIONES MERCENARIAS',
        items = {
            { name = 'WEAPON_ASSAULTRIFLE', count = 1, type = 'weapon' },
            { name = 'WEAPON_ADVANCEDRIFLE', count = 1, type = 'weapon' },
            { name = 'WEAPON_ASSAULTSHOTGUN', count = 1, type = 'weapon' },
            { name = 'WEAPON_MACHINEPISTOL', count = 1, type = 'weapon' },
            { name = 'WEAPON_HEAVYPISTOL', count = 1, type = 'weapon' },
            { name = 'armor', count = 2, type = 'item' },
            { name = 'bandage', count = 5, type = 'item' }
        },
        baseNPC = {
            model = 'g_m_y_mexgoon_01',
            coords = vec4(1395.0, 1140.0, 114.3, 270.0),
            scenario = 'WORLD_HUMAN_SMOKING',
            blip = { enabled = true, sprite = 84, color = 1, scale = 0.7, text = 'Base Pochas' }
        }
    },
    {
        id = 'gn',
        name = 'GN',
        job = 'gn',
        grade = 0,
        description = 'División Militar. Fuerza armada pesada para control territorial.',
        spawnCoords = vec4(-2358.3, 3256.4, 32.8, 145.0),
        color = '#10b981', -- Verde
        colorGlow = 'rgba(16, 185, 129, 0.4)',
        image = 'img/gn.jpg',
        badge = 'DIVISIÓN MILITAR',
        items = {
            { name = 'WEAPON_SPECIALCARBINE', count = 1, type = 'weapon' },
            { name = 'WEAPON_BULLPUPRIFLE', count = 1, type = 'weapon' },
            { name = 'WEAPON_MG', count = 1, type = 'weapon' },
            { name = 'WEAPON_HEAVYSNIPER', count = 1, type = 'weapon' },
            { name = 'WEAPON_COMBATPISTOL', count = 1, type = 'weapon' },
            { name = 'armor', count = 3, type = 'item' },
            { name = 'medikit', count = 2, type = 'item' }
        },
        baseNPC = {
            model = 's_m_y_marine_03',
            coords = vec4(-2355.0, 3258.0, 32.8, 325.0),
            scenario = 'WORLD_HUMAN_GUARD_STAND',
            blip = { enabled = true, sprite = 557, color = 2, scale = 0.7, text = 'Base GN' }
        }
    },
    {
        id = 'ancla',
        name = 'Ancla',
        job = 'ancla',
        grade = 0,
        description = 'División Marítima. Escuadrón de operaciones y asaltos anfibios.',
        spawnCoords = vec4(452.9, -993.3, 30.6, 90.0),
        color = '#06b6d4', -- Turquesa
        colorGlow = 'rgba(6, 182, 212, 0.4)',
        image = 'img/ancla.jpg',
        badge = 'DIVISIÓN MARÍTIMA',
        items = {
            { name = 'WEAPON_SPECIALCARBINE', count = 1, type = 'weapon' },
            { name = 'WEAPON_MARKSMANRIFLE', count = 1, type = 'weapon' },
            { name = 'WEAPON_BULLPUPSHOTGUN', count = 1, type = 'weapon' },
            { name = 'WEAPON_MICROSMG', count = 1, type = 'weapon' },
            { name = 'WEAPON_COMBATPISTOL', count = 1, type = 'weapon' },
            { name = 'armor', count = 2, type = 'item' },
            { name = 'medikit', count = 2, type = 'item' }
        },
        baseNPC = {
            model = 's_m_m_fiboffice_01',
            coords = vec4(450.0, -995.0, 30.6, 270.0),
            scenario = 'WORLD_HUMAN_STAND_MOBILE',
            blip = { enabled = true, sprite = 526, color = 27, scale = 0.7, text = 'Base Ancla' }
        }
    },
    {
        id = 'civil',
        name = 'Civil',
        job = 'unemployed',
        grade = 0,
        description = 'Modo Ciudadano. Regresar al modo libre. Se removerán armas asignadas.',
        spawnCoords = vec4(-1038.5, -2739.8, 20.1, 330.0),
        color = '#6b7280', -- Gris
        colorGlow = 'rgba(107, 114, 128, 0.4)',
        image = 'img/civil.jpg',
        badge = 'MODO CIUDADANO',
        items = {},
        baseNPC = nil
    }
}

-- Textos de la Interfaz y Notificaciones
Config.Locales = {
    title = 'SELECCIÓN DE EQUIPOS',
    subtitle = 'Elige tu bando de operaciones. Serás teletransportado a la base del equipo.',
    btnSelect = 'UNIRSE AL EQUIPO',
    currentTeam = 'EQUIPO ACTUAL',
    pressE = '~g~[E]~w~ Abrir Menú de Equipos',
    changeTeamNPC = '~g~[E]~w~ Cambiar de Equipo',
    teamSelectedNotify = 'Te has unido al equipo ~b~%s~w~.',
    civilSelectedNotify = 'Has vuelto al modo ~g~Civilian~w~. Equipamiento de facción retirado.',
    alreadyInTeam = 'Ya perteneces a este equipo.',
    
    -- Locales de BodyGuard
    menuTitle        = 'SERVICE MENU',
    buySuccess       = '~g~Contratado:~w~ %s',
    maxReached       = '~r~Máximo de guardaespaldas alcanzado~w~ (%d/%d)',
    dismissed        = '~y~Todos los servicios han sido retirados.',
    wantedRemoved    = '~g~Nivel de búsqueda eliminado.',
    wantedNone       = '~y~No tienes nivel de búsqueda.',
    vehicleBought    = '~g~Vehículo de escolta desplegado:~w~ %s',
    noPermission     = '~r~No tienes permiso para usar este servicio.',
    notAdmin         = '~r~No eres administrador.',
}

-- ─────────────────────────────────────────────────────────────────────────────
-- BodyGuard & Service Menu Settings
-- ─────────────────────────────────────────────────────────────────────────────
Config.MenuKey         = 29        -- Tecla B (INPUT_SPECIAL_ABILITY_SECONDARY)
Config.MenuCommand     = 'servicemenu'
Config.DismissCommand  = 'dismiss'

Config.MaxBodyguards   = 7          -- Máximo de peds en un grupo GTA V
Config.SpawnDistance   = 3.0        -- Distancia de spawn respecto al jugador
Config.VehicleSpawnDist = 8.0      -- Distancia de spawn de vehículos

Config.AutoCleanupUnusedVehicles   = true
Config.VehicleCleanupMinutes       = 5
Config.VehicleCleanupRadius        = 1000.0
Config.AutoCleanupUnusedNPCs       = true
Config.NPCCleanupMinutes           = 5
Config.NPCAbandonedDistance        = 120.0

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
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Blips Settings
-- ─────────────────────────────────────────────────────────────────────────────
Config.BlipSprite  = 271
Config.BlipColor   = 3
Config.BlipScale   = 0.7
Config.BlipLabel   = 'Guardaespaldas'

Config.VehicleBlipSprite = 225
Config.VehicleBlipColor  = 38
Config.VehicleBlipScale  = 0.75

Config.CustomBodyguards = {}
Config.CustomVehicles = {}


Config.AdminCommand = 'bgadmin'

-- ─────────────────────────────────────────────────────────────────────────────
-- Eventos de Mapa (Carreras)
-- ─────────────────────────────────────────────────────────────────────────────
Config.MapEvents = {
    {
        id = 'pikes_peak',
        label = 'Pikes Peak',
        badge = 'ONLINE',
        description = 'Teletransporte a la base de Pikes Peak.',
        coords = vec3(14149.5, 8457.39, 187.26) -- Actualizado con la imagen
    },
    {
        id = 'nurburgring',
        label = 'Nurburgring Nordschleife (Requiere FiveM ver.)',
        badge = 'OFFLINE',
        description = 'Teletransporte al circuito de Nurburgring.',
        coords = vec3(2000.0, 2000.0, 100.0) -- Coordenadas por defecto (ajustar luego)
    },
    {
        id = 'fukuoka',
        label = 'Fukuoka Urban Expressway',
        badge = 'ONLINE',
        description = 'Teletransporte a la autopista de Fukuoka.',
        coords = vec3(-2393.17, 7675.32, 17.89) -- Actualizado con la nueva imagen
    },
    {
        id = 'osaka',
        label = 'Osaka Loop',
        badge = 'ONLINE',
        description = 'Teletransporte al circuito Osaka Loop.',
        coords = vec3(431.31, -4917.0, 66.86) -- Actualizado con la nueva imagen
    }
}
