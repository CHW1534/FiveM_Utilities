fx_version 'cerulean'
game 'gta5'

name 'respawn_menu'
author 'CHW'
url 'https://github.com/CHW1534'
description 'Menú de Respawn Táctico — Mapa interactivo, permisos ACE, I-Frames, panel de admin y transiciones cinematográficas'
version '1.1.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/admin_panel.css',
    'html/admin_panel.js',
    'html/img/map_gtav.jpg',
    'data/respawn_perms.json'
}

shared_script 'config.lua'

client_scripts {
    'client/main.lua',
    'client/admin_panel.lua'
}

server_scripts {
    'server/admin_panel.lua',
    'server/main.lua'
}

