--[[

	Tube Library
	============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--

local function distributor_formspec(running)
	return "size[8,8.5]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"list[context;src;0,0;2,4;]"..
	"image[2,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]"..
	"button_exit[2,3;1,1;button;OK]"..
	"checkbox[3,0;running1;On;"..dump(running[1]).."]"..
	"checkbox[3,1;running2;On;"..dump(running[2]).."]"..
	"checkbox[3,2;running3;On;"..dump(running[3]).."]"..
	"checkbox[3,3;running4;On;"..dump(running[4]).."]"..
	"image[3.6,0;0.3,1;tubelib_red.png]"..
	"image[3.6,1;0.3,1;tubelib_green.png]"..
	"image[3.6,2;0.3,1;tubelib_blue.png]"..
	"image[3.6,3;0.3,1;tubelib_yellow.png]"..
	"list[context;red;4,0;4,1;]"..
	"list[context;green;4,1;4,1;]"..
	"list[context;blue;4,2;4,1;]"..
	"list[context;yellow;4,3;4,1;]"..
	"list[current_player;main;0,4.5;8,4;]"..
	"listring[context;src]"..
	"listring[current_player;main]"
end

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	if listname == "src" then
		return stack:get_count()
	else
		return 1
	end
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return stack:get_count()
end

local function filter_settings(meta)
	local inv = meta:get_inventory()
	local red = inv:get_list("red")
	local green = inv:get_list("green")
	local blue = inv:get_list("blue")
	local yellow = inv:get_list("yellow")
	local filter = {{},{},{},{}}
	for idx,itemlist in ipairs({red, green, blue, yellow}) do
		for _,items in ipairs(itemlist) do
			if items:get_count() == 1 then
				filter[idx][#filter[idx]+1] = items:get_name()
			end
		end
	end
	meta:set_string("filter", minetest.serialize(filter))
end

local function get_next_side(meta, item_name, filter)
	local running = minetest.deserialize(meta:get_string("running"))
	local side = meta:get_int("side") or 0
	local num2asc = {"F", "L", "B", "R"}
	meta:set_int("side", (side + 1) % 4)
	local i, idx
	for i = 1,4 do
		idx = ((i + side) % 4) + 1
		if running[idx] == true then
			for _,name in ipairs(filter[idx]) do
				if name == item_name then
					return num2asc[idx]
				end
			end
		end
	end
	for i = 1,4 do
		idx = ((i + side) % 4) + 1
		if running[idx] == true then
			if #filter[idx] == 0 then
				return num2asc[idx]
			end
		end
	end
	return nil
end

local function start_the_machine(pos)
	local node = minetest.get_node(pos)
	if node.name ~= "tubelib:distributor_active" then
		node.name = "tubelib:distributor_active"
		minetest.swap_node(pos, node)
	end
	minetest.get_node_timer(pos):start(2)
	local meta = minetest.get_meta(pos)
	local number = meta:get_string("number")
	meta:set_string("infotext", "Tubelib Distributor "..number..": running")
end

local function stop_the_machine(pos)
	local node = minetest.get_node(pos)
	if node.name ~= "tubelib:distributor" then
		node.name = "tubelib:distributor"
		minetest.swap_node(pos, node)
		minetest.get_node_timer(pos):stop()
	end
	local meta = minetest.get_meta(pos)
	local number = meta:get_string("number")
	meta:set_string("infotext", "Tubelib Distributor "..number..": stopped")
end

local function command_reception(pos, topic, payload)
	if string.match(topic, "start") then
		return start_the_machine(pos)
	elseif string.match(topic, "stop") then
		return stop_the_machine(pos)
	else
		return false
	end
end

local function keep_running(pos, elapsed)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local filter = minetest.deserialize(meta:get_string("filter"))
	local item = tubelib.get_item(inv, "src")
	local facedir = meta:get_int("facedir")
	if item then
		local side = get_next_side(meta, item:get_name(), filter)
		if side then
			if tubelib.push_items(pos, facedir, side, item) then
				return true
			end
		end
		-- put item back to inventory
		tubelib.put_item(inv, "src", item)
	end
	return true
end

local function on_receive_fields(pos, formname, fields, player)
	local meta = minetest.get_meta(pos)
	local running = minetest.deserialize(meta:get_string("running"))
	if fields.running1 ~= nil then
		running[1] = fields.running1 == "true"
	elseif fields.running2 ~= nil then
		running[2] = fields.running2 == "true"
	elseif fields.running3 ~= nil then
		running[3] = fields.running3 == "true"
	elseif fields.running4 ~= nil then
		running[4] = fields.running4 == "true"
	end
	meta:set_string("running", minetest.serialize(running))
	meta:set_string("formspec", distributor_formspec(running))
	if fields.button ~= nil then
		if running[1] or running[2] or running[3] or running[4] then
			filter_settings(meta)
			start_the_machine(pos)
		else
			stop_the_machine(pos)
		end
	end
end

minetest.register_node("tubelib:distributor", {
	description = "Tubelib Distributor",
	tiles = {
		-- up, down, right, left, back, front
		'tubelib_distributor.png',
		'tubelib_distributor.png',
		'tubelib_distributor_yellow.png',
		'tubelib_distributor_green.png',
		"tubelib_distributor_red.png",
		"tubelib_distributor_blue.png",
	},

	after_place_node = function(pos, placer)
		local number = tubelib.add_server_node(pos, "tubelib:distributor", placer)
		local meta = minetest.get_meta(pos)
		local facedir = minetest.dir_to_facedir(placer:get_look_dir(), false)
		local running = {false,false,false,false}
		meta:set_string("infotext", "Tubelib Distributor "..number..": stopped")
		meta:set_string("formspec", distributor_formspec(running))
		meta:set_string("running", minetest.serialize(running))
		meta:set_string("number", number)
		meta:set_int("facedir", facedir)
		local inv = meta:get_inventory()
		inv:set_size('src', 8)
		inv:set_size('yellow', 4)
		inv:set_size('green', 4)
		inv:set_size('red', 4)
		inv:set_size('blue', 4)
	end,

	on_receive_fields = on_receive_fields,

	on_dig = function(pos, node, puncher, pointed_thing)
		if minetest.is_protected(pos, puncher:get_player_name()) then
			return
		end
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		if inv:is_empty("src") then
			minetest.node_dig(pos, node, puncher, pointed_thing)
		end
	end,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,

	paramtype2 = "facedir",
	groups = {cracky=1},
	is_ground_content = false,
})


minetest.register_node("tubelib:distributor_active", {
	description = "Tubelib Distributor",
	tiles = {
		-- up, down, right, left, back, front
		{
			image = "tubelib_distributor_active.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 2.0,
			},
		},
		'tubelib_distributor.png',
		'tubelib_distributor_yellow.png',
		'tubelib_distributor_green.png',
		"tubelib_distributor_red.png",
		"tubelib_distributor_blue.png",
	},

	on_receive_fields = on_receive_fields,
	
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,

	on_timer = keep_running,

	paramtype2 = "facedir",
	groups = {crumbly=0, not_in_creative_inventory=1},
	is_ground_content = false,
})

local function get_items(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	return tubelib.get_item(inv, "src")
end

local function put_items(pos, items)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	return tubelib.put_item(inv, "src", items)
end

tubelib.register_receive_function("tubelib:distributor", command_reception)
tubelib.register_item_functions("tubelib:distributor", put_items, get_items)	
tubelib.register_item_functions("tubelib:distributor_active", put_items, get_items)	
