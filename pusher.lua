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
	local meta = minetest.get_meta(pos)
	local number = meta:get_string("number")
	meta:set_int("running", 1)
	meta:set_string("infotext", "Pusher "..number..": running")
	node.name = "tubelib:pusher_active"
	minetest.swap_node(pos, node)
	minetest.get_node_timer(pos):start(2)
	return true
end	

local function switch_off(pos, node)
	local meta = minetest.get_meta(pos)
	local number = meta:get_string("number")
	meta:set_int("running", 0)
	meta:set_string("infotext", "Pusher "..number..": stopped")
	node.name = "tubelib:pusher"
	minetest.swap_node(pos, node)
	minetest.get_node_timer(pos):stop()
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

local function keep_running(pos, elapsed)
	local meta = minetest.get_meta(pos)
	local number = meta:get_string("number")
	local facedir = meta:get_int("facedir")
	local items = tubelib.pull_items(pos, facedir, "L")
	if items ~= nil then
		if tubelib.push_items(pos, facedir, "R", items) == false then
			tubelib.push_items(pos, facedir, "L", items)
			meta:set_string("infotext", "Pusher "..number..": blocked")
		else
			meta:set_string("infotext", "Pusher "..number..": running")
		end
	else
		meta:set_string("infotext", "Pusher "..number..": unloaded")
	end
	return true
end

minetest.register_node("tubelib:pusher", {
	description = "Tubelib Pusher",
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_pusher1.png',
		'tubelib_pusher1.png',
		'tubelib_outp.png',
		'tubelib_inp.png',
		"tubelib_pusher1.png^[transformR180]",
		"tubelib_pusher1.png",
	},

	after_place_node = function(pos, placer)
		local number = tubelib.add_server_node(pos, "tubelib:pusher", placer)
		local meta = minetest.get_meta(pos)
		local facedir = minetest.dir_to_facedir(placer:get_look_dir(), false)
		meta:set_int("facedir", facedir)
		meta:set_string("number", number)
		meta:set_string("infotext", "Pusher "..number..": stopped")
	end,

	on_rightclick = function(pos, node, clicker)
		if not minetest.is_protected(pos, clicker:get_player_name()) then
			switch_on(pos, node)
		end
	end,

	paramtype2 = "facedir",
	groups = {cracky=1},
	is_ground_content = false,
})


minetest.register_node("tubelib:pusher_active", {
	description = "Tubelib Pusher",
	tiles = {
		-- up, down, right, left, back, front
		{
			image = "tubelib_pusher.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 2.0,
			},
		},
		{
			image = "tubelib_pusher.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 2.0,
			},
		},
		'tubelib_outp.png',
		'tubelib_inp.png',
		{
			image = "tubelib_pusher.png^[transformR180]",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 2.0,
			},
		},
		{
			image = "tubelib_pusher.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 2.0,
			},
		},
	},

	on_rightclick = function(pos, node, clicker)
		if not minetest.is_protected(pos, clicker:get_player_name()) then
			switch_off(pos, node)
		end
	end,
	
	on_timer = keep_running,
	
	paramtype2 = "facedir",
	groups = {crumbly=0, not_in_creative_inventory=1},
	is_ground_content = false,
})

tubelib.register_receive_function("tubelib:pusher", command_reception)
tubelib.register_node_name("tubelib:pusher")	
tubelib.register_node_name("tubelib:pusher_active")	
