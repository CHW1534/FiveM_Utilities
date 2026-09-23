fx_version 'cerulean'
game 'gta5'

name 'service_menu'
author 'CHW'
url 'https://github.com/CHW1534'
description 'Tactical Service Menu & Faction Manager with 3D Web NUI, AI Escorts, Teleportation & Inventory Blacklist'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/img/*.png',
    'html/img/*.jpg',
    'html/img/*.svg',
    'html/img/items/*.png'
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
