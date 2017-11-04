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
	2017-09-26  v0.04  param side added, node blackhole added
	2017-10-06  v0.05  Parameter 'player_name' added, furnace fuel detection changed
	2017-10-08  v0.06  tubelib.get_node_number() added, tubelib.version added
	2017-10-29  v0.07  Pusher bugfix, commands start/stop replaced by on/off
	2017-11-02  v0.08  Data base changed, aging of node positions added
	2017-11-04  v0.09  functions set_data/get_data added
	
]]--


tubelib = {
	NodeDef = {},		-- node registration info
}

tubelib.version = 0.08


--------------------------- conversion to v0.04
minetest.register_lbm({
	label = "[Tubelib] Distributor update",
	name = "tubelib:update",
	nodenames = {"tubelib:distributor", "tubelib:distributor_active"},
	run_at_every_load = false,
	action = function(pos, node)
		local meta = minetest.get_meta(pos)
		if minetest.deserialize(meta:get_string("filter")) == nil then
			local filter = {false,false,false,false}
			meta:set_string("filter", minetest.serialize(filter))
		end
		local inv = meta:get_inventory()
		inv:set_size('yellow', 6)
		inv:set_size('green', 6)
		inv:set_size('red', 6)
		inv:set_size('blue', 6)
	end
})

dofile(minetest.get_modpath("tubelib") .. "/tubes.lua")
dofile(minetest.get_modpath("tubelib") .. "/command.lua")
dofile(minetest.get_modpath("tubelib") .. "/states.lua")
dofile(minetest.get_modpath("tubelib") .. "/pusher.lua")
dofile(minetest.get_modpath("tubelib") .. "/blackhole.lua")
dofile(minetest.get_modpath("tubelib") .. "/button.lua")
dofile(minetest.get_modpath("tubelib") .. "/lamp.lua")
dofile(minetest.get_modpath("tubelib") .. "/distributor.lua")
dofile(minetest.get_modpath("tubelib") .. "/legacy_nodes.lua")

