Config = {}

-- Framework Settings
Config.UseESX = true
Config.ESXExport = 'esx:getSharedObject' -- Evento o export para ESX

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
        id = 'police',
        name = 'Fuerza Táctica',
        job = 'police',
        grade = 0,
        description = 'Escuadron especial encargado de mantener el orden y combatir amenazas armadas.',
        spawnCoords = vec4(-1098.5, -831.2, 19.3, 308.0), -- Teletransporte a la Base Táctica
        color = '#3b82f6', -- Color azul primario
        colorGlow = 'rgba(59, 130, 246, 0.4)',
        image = 'img/police.png',
        badge = 'POLICÍA',
        items = {
            { name = 'WEAPON_CARBINERIFLE', count = 1, type = 'weapon' },
            { name = 'WEAPON_COMBATPISTOL', count = 1, type = 'weapon' },
            { name = 'armor', count = 2, type = 'item' },
            { name = 'medikit', count = 3, type = 'item' }
        },
        baseNPC = {
            model = 's_m_y_cop_01',
            coords = vec4(-1094.1, -835.0, 19.3, 120.0),
            scenario = 'WORLD_HUMAN_GUARD_STAND',
            blip = { enabled = true, sprite = 60, color = 3, scale = 0.7, text = 'Base Táctica' }
        }
    },
    {
        id = 'cartel',
        name = 'Operaciones Mercenarias',
        job = 'cartel',
        grade = 0,
        description = 'Fuerza rebelde altamente armada especializada en incursiones y combate urbano.',
        spawnCoords = vec4(1392.2, 1141.6, 114.3, 90.0), -- Teletransporte a la Base Mercenaria
        color = '#ef4444', -- Color rojo primario
        colorGlow = 'rgba(239, 68, 68, 0.4)',
        image = 'img/cartel.png',
        badge = 'MERCENARIOS',
        items = {
            { name = 'WEAPON_ASSAULTRIFLE', count = 1, type = 'weapon' },
            { name = 'WEAPON_HEAVYPISTOL', count = 1, type = 'weapon' },
            { name = 'armor', count = 2, type = 'item' },
            { name = 'bandage', count = 5, type = 'item' }
        },
        baseNPC = {
            model = 'g_m_y_mexgoon_01',
            coords = vec4(1395.0, 1140.0, 114.3, 270.0),
            scenario = 'WORLD_HUMAN_SMOKING',
            blip = { enabled = true, sprite = 84, color = 1, scale = 0.7, text = 'Base Mercenaria' }
        }
    },
    {
        id = 'army',
        name = 'División Militar',
        job = 'army',
        grade = 0,
        description = 'Fuerza armada pesada entrenada para control territorial y combate defensivo.',
        spawnCoords = vec4(-2358.3, 3256.4, 32.8, 145.0), -- Teletransporte a la Base Militar
        color = '#10b981', -- Color verde primario
        colorGlow = 'rgba(16, 185, 129, 0.4)',
        image = 'img/army.png',
        badge = 'EJÉRCITO',
        items = {
            { name = 'WEAPON_SPECIALCARBINE', count = 1, type = 'weapon' },
            { name = 'WEAPON_COMBATPISTOL', count = 1, type = 'weapon' },
            { name = 'armor', count = 3, type = 'item' },
            { name = 'medikit', count = 2, type = 'item' }
        },
        baseNPC = {
            model = 's_m_y_marine_03',
            coords = vec4(-2355.0, 3258.0, 32.8, 325.0),
            scenario = 'WORLD_HUMAN_GUARD_STAND',
            blip = { enabled = true, sprite = 557, color = 2, scale = 0.7, text = 'Base Militar' }
        }
    },
    {
        id = 'civil',
        name = 'Modo Ciudadano',
        job = 'unemployed',
        grade = 0,
        description = 'Regresar al modo libre civil. Se removerán los ítems y armas tácticas asignadas.',
        spawnCoords = vec4(-1038.5, -2739.8, 20.1, 330.0), -- Teletransporte de vuelta al lobby
        color = '#6b7280', -- Color gris
        colorGlow = 'rgba(107, 114, 128, 0.4)',
        image = 'img/civil.png',
        badge = 'CIVIL',
        items = {}, -- Sin ítems
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
    alreadyInTeam = 'Ya perteneces a este equipo.'
}
