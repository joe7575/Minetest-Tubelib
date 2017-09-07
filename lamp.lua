--[[

	Tube Library
	============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--

local function switch_on(pos, node)
	node.name = "tubelib:lamp_on"
	minetest.swap_node(pos, node)
	return true
end	

local function switch_off(pos, node)
	node.name = "tubelib:lamp"
	minetest.swap_node(pos, node)
	return true
end	

local function command_reception(pos, topic, payload)
	local node = minetest.get_node(pos)
	if string.match(topic, "start") then
		return switch_on(pos, node)
	elseif string.match(topic, "stop") then
		return switch_off(pos, node)
	else
		return false
	end
end

minetest.register_node("tubelib:lamp", {
	description = "Tubelib Lamp",
	tiles = {
		'tubelib_lamp.png',
	},

	after_place_node = function(pos, placer)
		local number = tubelib.add_server_node(pos, "tubelib:lamp", placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", number)
	end,

	on_rightclick = function(pos, node, clicker)
		if not minetest.is_protected(pos, clicker:get_player_name()) then
			switch_on(pos, node)
		end
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
	drop = "tubelib:lamp",
})

tubelib.register_receive_function("tubelib:lamp", command_reception)
tubelib.register_receive_function("tubelib:lamp_on", command_reception)	