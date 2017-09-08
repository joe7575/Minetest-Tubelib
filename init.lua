--[[

	Tube Library
	============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	2017-09-08  v0.01  first version

]]--

tubelib = {
	NodeTypes = {},
}

tubelib.debug = true

tubelib.knownNodes = {
	["tubelib:tube1"] = true,
	["tubelib:tube2"] = true,
	["tubelib:tube3"] = true,
	["tubelib:tube4"] = true,
	["tubelib:tube5"] = true,
	["tubelib:tube6"] = true,
	["default:chest_locked"] = true,
	["default:chest"] = true,
}

tubelib.legacyNodes = {
	["default:chest_locked"] = true,
	["default:chest"] = true,
}

function tubelib.get_key_str(pos)
	pos = minetest.pos_to_string(pos)
	return '"'..string.sub(pos, 2, -2)..'"'
end

-- 6D variant of the facedir to dir conversion 
function tubelib.facedir_to_dir(facedir)
	local table = {[0] = 
		{x=0, y=0, z=1},
		{x=1, y=0, z=0},
		{x=0, y=0, z=-1},
		{x=-1, y=0, z=0},
		{x=0, y=-1, z=0},
		{x=0, y=1, z=0},
	}
	return table[facedir]
end

-- Determine neighbor position based on current pos, node facedir
-- and the side F(orward), R(ight), B(ackward), L(eft), D(own), U(p).
-- The function considers tubes in addition.
function tubelib.get_pos(pos, facedir, side)
	local offs = {F=0, R=1, B=2, L=3, D=4, U=5}
	local dst_pos = table.copy(pos)
	facedir = (facedir + offs[side]) % 4
	local dir = tubelib.facedir_to_dir(facedir)
	dst_pos = vector.add(dst_pos, dir)
	local node = minetest.get_node(dst_pos)
	if node and string.find(node.name, "tubelib:tube") then
		dst_pos = minetest.string_to_pos(minetest.get_meta(dst_pos):get_string("dest_pos"))
		node = minetest.get_node(dst_pos)
	end
	return node, dst_pos
end	


local function get_facedir(placer)
	if placer then
		return minetest.dir_to_facedir(placer:get_look_dir(), false)
	end
	return 0
end

local function legacy_node(node)
	if node and tubelib.legacyNodes[node.name] then
		return true
	end
	return false
end
	
-------------------------------------------------------------------
-- Registration functions
-------------------------------------------------------------------

-- Register functions for tube pushing/pulling
-- Call this function only at load time!
function tubelib.register_item_functions(name, push_clbk, pull_clbk)
	tubelib.knownNodes[name] = true
	tubelib.NodeTypes[name] = {push_clbk = push_clbk, pull_clbk = pull_clbk}
end

-------------------------------------------------------------------
-- Client side API functions
-------------------------------------------------------------------

function tubelib.pull_items(pos, facedir, side)
	local node, src_pos = tubelib.get_pos(pos, facedir, side)
	local key = tubelib.get_key_str(src_pos)
	if tubelib.NodeTypes[node.name] and tubelib.NodeTypes[node.name].pull_clbk then
		return tubelib.NodeTypes[node.name].pull_clbk(src_pos)
	elseif legacy_node(node) then
		local meta = minetest.get_meta(src_pos)
		local inv = meta:get_inventory()
		return tubelib.get_item(inv, "main")
	end
	return nil
end

function tubelib.push_items(pos, facedir, side, items)
	local node, dst_pos = tubelib.get_pos(pos, facedir, side)
	local key = tubelib.get_key_str(dst_pos)
	if tubelib.NodeTypes[node.name] and tubelib.NodeTypes[node.name].push_clbk then
		return tubelib.NodeTypes[node.name].push_clbk(dst_pos, items)
	elseif legacy_node(node) then
		local meta = minetest.get_meta(dst_pos)
		local inv = meta:get_inventory()
		return tubelib.put_item(inv, "main", items)
	elseif node and node.name == "air" then
		minetest.add_item(dst_pos, items)
		return true 
	end
	return false
end

-------------------------------------------------------------------
-- Server side helper functions
-------------------------------------------------------------------

function tubelib.get_item(inv, listname)
	if inv:is_empty(listname) then
		--print("nil")
		return nil
	end
	local stack, slot
	local size = inv:get_size(listname)
	local offs = math.random(size)
	--print("tubelib.get_item", offs)
	for idx = 1, size do
		local slot = ((idx + offs) % size) + 1
		local items = inv:get_stack(listname, slot)
		if items:get_count() > 0 then
			local taken = items:take_item(1)
			inv:set_stack(listname, slot, items)
			return taken
		end
	end
	return nil
end


function tubelib.put_item(inv, listname, items)
	if inv:room_for_item(listname, items) then
		inv:add_item(listname, items)
		return true
	end
	return false
end

dofile(minetest.get_modpath("tubelib") .. "/tubes.lua")
dofile(minetest.get_modpath("tubelib") .. "/command.lua")
dofile(minetest.get_modpath("tubelib") .. "/button.lua")
dofile(minetest.get_modpath("tubelib") .. "/lamp.lua")
dofile(minetest.get_modpath("tubelib") .. "/pusher.lua")
dofile(minetest.get_modpath("tubelib") .. "/distributor.lua")
