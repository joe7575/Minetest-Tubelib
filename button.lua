--[[

	Tube Library
	============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--

CYCLE_TIME = 4


local function switch_on(pos, node, player_name)
	if node.name ~= "tubelib:button_active" then
		node.name = "tubelib:button_active"
		minetest.swap_node(pos, node)
		minetest.get_node_timer(pos):start(CYCLE_TIME)
		minetest.sound_play("button", {
				pos = pos,
				gain = 0.5,
				max_hear_distance = 5,
			})
		local meta = minetest.get_meta(pos)
		local number = meta:get_string("number")
		tubelib.send_cmnd(number, player_name, "start", nil)
	end
end

local function switch_off(pos)
	local node = minetest.get_node(pos)
	if node.name ~= "tubelib:button" then
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
		tubelib.send_cmnd(number, nil, "stop", nil)
	end
end


minetest.register_node("tubelib:button", {
	description = "Tubelib Button",
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		'tubelib_front.png',
		'tubelib_front.png',
		'tubelib_front.png',
		'tubelib_front.png',
		"tubelib_button_off.png",
	},

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", "size[4,3]"..
		"field[0.5,0.5;3,1;number;Insert destination block number;]" ..
		"button_exit[1,2;2,1;exit;Save]")
	end,

	on_receive_fields = function(pos, formname, fields, player)
		if tubelib.check_number(fields.number) then
			print(fields.number)
			local meta = minetest.get_meta(pos)
			meta:set_string("number", fields.number)
			meta:set_string("formspec", nil)
			meta:set_string("infotext", "Tubelib Button, connected with block "..fields.number)
		end
	end,
	
	on_rightclick = function(pos, node, clicker)
		switch_on(pos, node, clicker:get_player_name())
	end,

	paramtype2 = "facedir",
	groups = {cracky=1},
	is_ground_content = false,
})


minetest.register_node("tubelib:button_active", {
	description = "Tubelib Button",
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_front.png',
		'tubelib_front.png',
		'tubelib_front.png',
		'tubelib_front.png',
		'tubelib_front.png',
		"tubelib_button_on.png",
	},

	on_timer = switch_off,

	paramtype2 = "facedir",
	groups = {crumbly=0, not_in_creative_inventory=1},
	is_ground_content = false,
})
