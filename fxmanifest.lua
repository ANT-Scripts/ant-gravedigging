fx_version 'cerulean'
game 'gta5'

name "ant-gravedigging"
description "A Grave Digging script for FiveM RP servers"
author "ANT Scripts"
version "1.0.0"

lua54 'yes'
use_experimental_fxv2_oal 'yes'

shared_scripts {
	'@ox_lib/init.lua',
	'shared/*.lua'
}

client_scripts {
	'client/*.lua'
}

server_scripts {
	'server/*.lua'
}
