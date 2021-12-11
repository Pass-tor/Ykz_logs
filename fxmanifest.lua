

version '1.0.0'
author 'Pastor'
description 'FXServer logs to Discord (https://pastor.com/)'
repository 'https://github.com/pastor/Ykz_logs'

-- Server Scripts
server_scripts {
    'server/server.lua',
    'server/functions.lua',
    'server/Updates.lua'
} 

--Client Scripts
client_scripts {
    'client/client.lua',
    'client/functions.lua',
    'client/weapons.lua'
}

files {
    'config/eventLogs.json',
    'config/config.json'
}

game 'gta5'
fx_version 'cerulean'
