--[[

	Tube Library
	============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	lamp.lua:
	
	Example of a "server" node, only receiving messages from others.
	This node claims a position number and registers its message interface.
	The Lamp supports the following messages:
	 - topic = "start", payload  = nil
	 - topic = "stop" , payload  = nil

]]--

local function switch_on(pos, node)
	node.name = "tubelib:lamp_on"
	minetest.swap_node(pos, node)
end	

local function switch_off(pos, node)
	node.name = "tubelib:lamp"
	minetest.swap_node(pos, node)
end	

minetest.register_node("tubelib:lamp", {
	description = "Tubelib Lamp",
	tiles = {
		'tubelib_lamp.png',
	},

	after_place_node = function(pos, placer)
		local number = tubelib.get_node_number(pos, "tubelib:lamp")		-- <<=== tubelib
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Tubelib Lamp "..number)
	end,

	on_rightclick = function(pos, node, clicker)
		if not minetest.is_protected(pos, clicker:get_player_name()) then
			switch_on(pos, node)
		end
	end,

	after_dig_node = function(pos)
		tubelib.remove_node(pos)										-- <<=== tubelib
	end,

	paramtype = 'light',
	light_source = 0,	
	groups = {cracky=1},
	is_ground_content = false,
})

minetest.register_node("tubelib:lamp_on", {
	description = "Tubelib Lamp",
	tiles = {
		'tubelib_lamp.png',
	},

	on_rightclick = function(pos, node, clicker)
		if not minetest.is_protected(pos, clicker:get_player_name()) then
			switch_off(pos, node)
		end
	end,

	paramtype = 'light',
	light_source = 8,	
	groups = {crumbly=0, not_in_creative_inventory=1},
	is_ground_content = false,
})

minetest.register_craft({
	output = "tubelib:lamp 4",
	recipe = {
		{"wool:white", 		"wool:white",  			"wool:white"},
		{"tubelib:tube1", 	"default:coal_lump",	""},
		{"group:wood", 		"",  					"group:wood"},
	},
})

--------------------------------------------------------------- tubelib
tubelib.register_node("tubelib:lamp", {"tubelib:lamp_on"}, {
	on_pull_item = nil,
	on_push_item = nil,
	on_recv_message = function(pos, topic, payload)
		local node = minetest.get_node(pos)
		if topic == "start" then
			switch_on(pos, node)
		elseif topic == "stop" then
			switch_off(pos, node)
		end
	end,
})		
--------------------------------------------------------------- tubelib
