-- filepath: resources/anticheat/fxmanifest.lua

fx_version 'cerulean'
game 'gta5'

author 'dnz'
description 'Anti-Cheat System for FiveM'
version '1.0.0'

client_script 'anticheat_client.lua'
server_script 'anticheat_server.lua'

files {
    'nui/menu.html'
}

ui_page 'nui/menu.html'
