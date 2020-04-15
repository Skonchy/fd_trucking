fx_version 'adamant'

game 'gta5'

files{

}

server_scripts{
    '@async/async.lua',
    '@mysql-async/lib/MySQL.lua',
    'config.lua',
    'server.lua'
}

client_scripts{
    'config.lua',
    'client.lua'
}

dependencies{
    'mysql-async',
    'async'
}