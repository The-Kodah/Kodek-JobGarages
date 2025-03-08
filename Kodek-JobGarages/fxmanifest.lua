fx_version 'cerulean'

game 'gta5'
lua54 'yes'
author "Kodah"
description "Job Garage Script Originally Made by NevoSwissa#8239 (CL-PoliceGarageV2)"
version '1.0.0'

shared_scripts {
    'config.lua',
    '@ox_lib/init.lua',
}

client_scripts {
    'client/client.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua',
}