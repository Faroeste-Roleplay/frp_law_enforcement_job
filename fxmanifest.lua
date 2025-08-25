fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
	'@frp_lib/library/linker.lua',
	'@frp_lib/library/shared/enum/code.lua',
    '@frp_lib/lib/table.lua',

    'config.lua',
	'@callbacks/import.lua',
}

client_scripts {
	'client/main.lua',
	'client/interactions.lua',
	'client/teleport.lua',
	'client/job.lua',
	-- 'client/evidence.lua',
	'client/objects.lua',
	'client/utils.lua',
	'client/command_events.lua',
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/main.lua',	
	'server/commands.lua'
}

dependency 'frp_business'