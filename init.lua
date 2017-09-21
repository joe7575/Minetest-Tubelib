--[[

	Tube Library
	============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	2017-09-08  v0.01  first version
	2017-09-12  v0.02  bugfix in tubelib.get_pos() and others
	2017-09-21  v0.03  function get_num_items added

]]--


tubelib = {
	NodeDef = {},		-- node registarion info
}

tubelib.debug = true


-- used by tubes to contact
tubelib.knownNodes = {
	["tubelib:tube1"] = true,
	["tubelib:tube2"] = true,
	["tubelib:tube3"] = true,
	["tubelib:tube4"] = true,
	["tubelib:tube5"] = true,
	["tubelib:tube6"] = true,
	["default:chest_locked"] = true,
	["default:chest"] = true,
	["default:furnace"] = true,
	["default:furnace_active"] = true,
}

-- used by push_item/pull_item
tubelib.legacyNodes = {
	["default:chest_locked"] = true,
	["default:chest"] = true,
	["default:chest_locked_open"] = true,
	["default:chest_open"] = true,
	["default:furnace"] = true,
	["default:furnace_active"] = true,
}


dofile(minetest.get_modpath("tubelib") .. "/command.lua")
dofile(minetest.get_modpath("tubelib") .. "/tubes.lua")
dofile(minetest.get_modpath("tubelib") .. "/pusher.lua")
dofile(minetest.get_modpath("tubelib") .. "/distributor.lua")
dofile(minetest.get_modpath("tubelib") .. "/button.lua")
dofile(minetest.get_modpath("tubelib") .. "/lamp.lua")

