fx_version 'cerulean'
game 'gta5'

name 'BodyGuard'
author 'CHW'
url 'https://github.com/CHW1534'
description 'Sistema de guardaespaldas — Contrata NPCs que te siguen, protegen y luchan por ti. Vehículos de escolta, menú interactivo y sistema standalone.'
version '2.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

shared_script 'config.lua'

client_scripts {
    'client/main.lua',
    'client/menu.lua'
}

server_scripts {
    'server/main.lua'
}
