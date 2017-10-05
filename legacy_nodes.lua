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
		return tubelib.get_item(meta, "main")
	end,
	on_push_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		return tubelib.put_item(meta, "main", item)
	end,
	on_unpull_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		return tubelib.put_item(meta, "main", item)
	end,
})	


tubelib.register_node("default:chest_locked", {"default:chest_locked_open"}, {
	on_pull_item = function(pos, side)
		local meta = minetest.get_meta(pos)
		return tubelib.get_item(meta, "main")
	end,
	on_push_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		return tubelib.put_item(meta, "main", item)
	end,
	on_unpull_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		return tubelib.put_item(meta, "main", item)
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
	["default:coal_lump"] = true,
}

tubelib.register_node("default:furnace", {"default:furnace_active"}, {
	on_pull_item = function(pos, side)
		local meta = minetest.get_meta(pos)
		return tubelib.get_item(meta, "dst")
	end,
	on_push_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		minetest.get_node_timer(pos):start(1.0)
		if FuelTbl[item:get_name()] == true then
			return tubelib.put_item(meta, "fuel", item)
		else
			return tubelib.put_item(meta, "src", item)
		end
	end,
	on_unpull_item = function(pos, side, item)
		local meta = minetest.get_meta(pos)
		return tubelib.put_item(meta, "dst", item)
	end,
})	
