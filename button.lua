--[[

	Tube Library
	============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	button.lua:
	
	Example of a simple communication node, only sending messages to other nodes.
	This node does not claim a position number via "add_node()", 
	nore providing any server API.

]]--


local function switch_on(pos, node)
	node.name = "tubelib:button_active"
	minetest.swap_node(pos, node)
	minetest.sound_play("button", {
			pos = pos,
			gain = 0.5,
			max_hear_distance = 5,
		})
	local meta = minetest.get_meta(pos)
	local number = meta:get_string("number")
	local cycle_time = meta:get_int("cycle_time")
	if cycle_time > 0 then 	-- button mode?
		minetest.get_node_timer(pos):start(cycle_time)
	end
	local placer_name = meta:get_string("placer_name")
	local clicker_name = nil
	if meta:get_string("public") == "false" then
		clicker_name = meta:get_string("clicker_name")
	end
	tubelib.send_message(number, placer_name, clicker_name, "start", nil)		-- <<=== tubelib
end

local function switch_off(pos)
	local node = minetest.get_node(pos)
	node.name = "tubelib:button"
	minetest.swap_node(pos, node)
	minetest.get_node_timer(pos):stop()
	minetest.sound_play("button", {
			pos = pos,
			gain = 0.5,
			max_hear_distance = 5,
		})
	local meta = minetest.get_meta(pos)
	local number = meta:get_string("number")
	local placer_name = meta:get_string("placer_name")
	tubelib.send_message(number, placer_name, nil, "stop", nil)					-- <<=== tubelib
end


minetest.register_node("tubelib:button", {
	description = "Tubelib Button/Switch",
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		'tubelib_button.png',
		'tubelib_button.png',
		'tubelib_button.png',
		'tubelib_button.png',
		"tubelib_button_off.png",
	},

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", "size[5,6]"..
		"dropdown[0.2,0;3;type;switch,button 2s,button 4s,button 8s,button 16s;1]".. 
		"field[0.5,2;3,1;number;Insert destination block number;]" ..
		"checkbox[1,3;public;public;false]"..
		"button_exit[1,4;2,1;exit;Save]")
		meta:set_string("placer_name", placer:get_player_name())
		meta:set_string("public", "false")
		meta:set_int("cycle_time", 0)
	end,

	on_receive_fields = function(pos, formname, fields, player)
		local meta = minetest.get_meta(pos)
		if tubelib.check_numbers(fields.number) then							-- <<=== tubelib
			meta:set_string("number", fields.number)
			meta:set_string("infotext", "Tubelib Button, connected with block "..fields.number)
		else
			return
		end
		if fields.public then
			meta:set_string("public", fields.public)
		end
		local cycle_time = nil
		if fields.type == "switch" then
			cycle_time = 0
		elseif fields.type == "button 2s" then
			cycle_time = 2
		elseif fields.type == "button 4s" then
			cycle_time = 4
		elseif fields.type == "button 8s" then
			cycle_time = 8
		elseif fields.type == "button 16s" then
			cycle_time = 16
		end
		if cycle_time ~= nil then
			meta:set_int("cycle_time", cycle_time)
		end
		if fields.exit then
			meta:set_string("formspec", nil)
		end
	end,
	
	on_rightclick = function(pos, node, clicker)
		local meta = minetest.get_meta(pos)
		meta:set_string("clicker_name", clicker:get_player_name())
		switch_on(pos, node)
	end,

	paramtype2 = "facedir",
	groups = {cracky=2, crumbly=2},
	is_ground_content = false,
})


minetest.register_node("tubelib:button_active", {
	description = "Tubelib Button/Switch",
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		'tubelib_button.png',
		'tubelib_button.png',
		'tubelib_button.png',
		'tubelib_button.png',
		"tubelib_button_on.png",
	},

	on_rightclick = function(pos, node, clicker)
		local meta = minetest.get_meta(pos)
		meta:set_string("clicker_name", clicker:get_player_name())
		switch_off(pos, node)
	end,

	on_timer = switch_off,

	paramtype2 = "facedir",
	groups = {crumbly=0, not_in_creative_inventory=1},
	is_ground_content = false,
})

minetest.register_craft({
	output = "tubelib:button 4",
	recipe = {
		{"group:wood", 		"group:wood",  			"group:wood"},
		{"dye:red", 		"default:mese_crystal",	"tubelib:tube1"},
		{"group:wood", 		"default:glass",  		"group:wood"},
	},
})

