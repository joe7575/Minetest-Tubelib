--[[

	Tube Library
	============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	legacy_nodes.lua:
	
	Tubelib support for chests and furnace
	
]]--

tubelib.register_node("default:chest", {"default:chest_open"}, {
	on_pull_item = function(pos, side)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return tubelib.get_item(inv, "main")
	end,
	on_push_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return tubelib.put_item(inv, "main", item)
	end,
	on_unpull_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return tubelib.put_item(inv, "main", item)
	end,
	on_recv_message = function(pos, topic, payload)
		if topic == "state" then
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			if inv:is_empty("main") then
				return "empty"
			else
				return "not empty"
			end
		else
			return "unsupported"
		end
	end,
})	


tubelib.register_node("default:chest_locked", {"default:chest_locked_open"}, {
	on_pull_item = function(pos, side)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return tubelib.get_item(inv, "main")
	end,
	on_push_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return tubelib.put_item(inv, "main", item)
	end,
	on_unpull_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return tubelib.put_item(inv, "main", item)
	end,
	on_recv_message = function(pos, topic, payload)
		if topic == "state" then
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			if inv:is_empty("main") then
				return "empty"
			else
				return "not empty"
			end
		else
			return "unsupported"
		end
	end,
})	

-- used for furnace
local FuelTbl = {
	["default:tree"] = true,
	["default:wood"] = true,
	["default:leaves"] = true,
	["default:jungletree"] = true,
	["default:junglewood"] = true,
	["default:jungleleaves"] = true,
	["default:pine_tree"] = true,
	["default:pine_wood"] = true,
	["default:pine_needles"] = true,
	["default:acacia_tree"] = true,
	["default:acacia_wood"] = true,
	["default:acacia_leaves"] = true,
	["default:aspen_tree"] = true,
	["default:aspen_wood"] = true,
	["default:aspen_leaves"] = true,
	["default:coalblock"] = true,
}

tubelib.register_node("default:furnace", {"default:furnace_active"}, {
	on_pull_item = function(pos, side)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return tubelib.get_item(inv, "dst")
	end,
	on_push_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		if FuelTbl[items:get_name()] == true then
			return tubelib.put_item(inv, "fuel", items)
		else
			return tubelib.put_item(inv, "src", items)
		end
	end,
	on_unpull_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return tubelib.put_item(inv, "dst", item)
	end,
	on_recv_message = function(pos, topic, payload)
		if topic == "state" then
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			if inv:is_empty("fuel") then
				return "no fuel"
			elseif inv:is_empty("src") then
				return "empty"
			else
				return "running"
			end
		else
			return "unsupported"
		end
	end,
})	
