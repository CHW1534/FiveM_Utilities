fx_version 'cerulean'
game 'gta5'

name 'team_selector'
author 'CHW'
url 'https://github.com/CHW1534'
description 'Sistema moderno de Selección de Equipos con NPCs, Teletransporte, Ítems y Blacklist'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/img/*.png',
    'html/img/*.jpg'
}

shared_script 'config.lua'

client_scripts {
    'config.lua',
    'client/main.lua',
    'client/bodyguards.lua',
    'client/menu.lua'
}

server_scripts {
    'config.lua',
    'server/main.lua',
    'server/bodyguards.lua'
}
