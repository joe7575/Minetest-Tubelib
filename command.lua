--[[

	Tube Library
	============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	command.lua:

	User interface functions for message communication 
  and StackItem push/pulling.

]]--

-------------------------------------------------------------------
-- Data base storage
-------------------------------------------------------------------
local storage = minetest.get_mod_storage()
local Key2Number = minetest.deserialize(storage:get_string("Key2Number")) or {}
local NextNumber = minetest.deserialize(storage:get_string("NextNumber")) or 1
local Number2Pos = minetest.deserialize(storage:get_string("Number2Pos")) or {}

function tubelib.update_mod_storage()
	storage:set_string("Key2Number", minetest.serialize(Key2Number))
	storage:set_string("NextNumber", minetest.serialize(NextNumber))
	storage:set_string("Number2Pos", minetest.serialize(Number2Pos))
end

minetest.register_on_shutdown(function()
	tubelib.update_mod_storage()
end)

local Name2Name = {}		-- translation table

-------------------------------------------------------------------
-- Local helper functions
-------------------------------------------------------------------
-- Localize functions to avoid table lookups (better performance).
local string_find = string.find
local string_split = string.split
local minetest_is_protected = minetest.is_protected
local tubelib_NodeDef = tubelib.NodeDef


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
	
-- Determine position related node number for addressing purposes
local function get_number(pos)
	local key = tubelib.get_key_str(pos)
	if not Key2Number[key] then
		Key2Number[key] = NextNumber
		NextNumber = NextNumber + 1
	end
	return string.format("%.04u", Key2Number[key])
end

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
	
-------------------------------------------------------------------
-- API helper functions
-------------------------------------------------------------------
	
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
	if node and string_find(node.name, "tubelib:tube") then
		local _pos = minetest.string_to_pos(minetest.get_meta(dst_pos):get_string("dest_pos"))
		-- two possible reasons, why _pos == pos:
		-- 1)  wrong side of a single tube node
		-- 2)  node connected with itself. In this case "dest_pos2" is not available
		if vector.equals(_pos, pos) then		--
			dst_pos = minetest.string_to_pos(minetest.get_meta(dst_pos):get_string("dest_pos2"))
		end
		if dst_pos == nil then
			dst_pos = _pos
		end
		node = minetest.get_node(dst_pos)
	end
	-- translate the current node name into the base name, used at registration
	if Name2Name[node.name] then
		node.name = Name2Name[node.name]
	end
	return node, dst_pos
end	

-- Generate a key string based on the given pos table,
-- Used internaly as table key,
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

-- Check the given list of numbers.
-- Returns true if number(s) is/are valid.
function tubelib.check_numbers(numbers)
	if numbers then
		for _,num in ipairs(string_split(numbers, " ")) do
			if Number2Pos[num] == nil then
				return false
			end
		end
		return true
	end
	return false
end	

-- Determines and returns the node position number based on the given pos.
function tubelib.get_node_number(pos, name)
	local number = get_number(pos)
	Number2Pos[number] = {
		pos = pos, 
		name = name,
	}
	tubelib.update_mod_storage()
	return number
end

-- Remove node from the position list
function tubelib.remove_node(pos)
	local number = get_number(pos)
	if Number2Pos[number] then
		Number2Pos[number] = {
			pos = pos, 
			name = nil,
		}
		tubelib.update_mod_storage()
	end
end


-- Function returns { pos, name } for the node on the given position number.
function tubelib.get_node_info(dest_num)
	if Number2Pos[dest_num] then
		return Number2Pos[dest_num]
	end
	return nil
end	


-------------------------------------------------------------------
-- Node register function
-------------------------------------------------------------------

-- Register node for tubelib communication
-- Call this function only at load time!
-- Param 'add_names'  tbd  TODO
-- Param 'node_definition' is a table according to:
-- 
--    {
--        on_pull_item = func(pos),
--            -- The function shall return an item stack with one element 
-- 			  -- like ItemStack("default:cobble") or nil.
--        on_push_item = func(pos, item),
--        on_recv_message = func(pos, topic, payload),
--    }
--
function tubelib.register_node(name, add_names, node_definition)
	tubelib.knownNodes[name] = true
	tubelib_NodeDef[name] = node_definition
	Name2Name[name] = name
	for _,n in ipairs(add_names) do
		tubelib.knownNodes[n] = true
		Name2Name[n] = name
	end
end

-------------------------------------------------------------------
-- Send message function
-------------------------------------------------------------------

-- Send a message to all blocks referenced by 'numbers', a list of 
-- one or more destination addressses separated by blanks. 
-- The message is based on the topic string (e.g. "start") and
-- topic related payload.
-- The placer and clicker names are needed to check the protection rights. 
-- If everybody should be able to send a message, use nil for clicker_name.
function tubelib.send_message(numbers, placer_name, clicker_name, topic, payload)
	for _,num in ipairs(string_split(numbers, " ")) do
		if Number2Pos[num] and Number2Pos[num].name then
			local data = Number2Pos[num]
			if placer_name and not minetest_is_protected(data.pos, placer_name) then
				if clicker_name == nil or not minetest_is_protected(data.pos, clicker_name) then
					if data and data.name and tubelib_NodeDef[data.name].on_recv_message then
						tubelib_NodeDef[data.name].on_recv_message(data.pos, topic, payload)
					end
				end
			end
		end
	end
end		

-------------------------------------------------------------------
-- Client side Push/Pull item functions
-------------------------------------------------------------------

-- Param 'pos', 'facedir', and 'side' are used to determine the neighbor position.
-- Param 'pos' is the own position
-- Param 'facedir' is the own node facedir 
-- Param 'side' is one of F(orward), R(ight), B(ackward), L(eft), D(own), U(p)
-- relative to the placers view to the node.
-- The function returns an item stack with one element like ItemStack("default:cobble")
-- or nil.
function tubelib.pull_items(pos, facedir, side)
	local node, src_pos = tubelib.get_pos(pos, facedir, side)
	if tubelib_NodeDef[node.name] and tubelib_NodeDef[node.name].on_pull_item then
		return tubelib_NodeDef[node.name].on_pull_item(src_pos)
	elseif legacy_node(node) then
		local meta = minetest.get_meta(src_pos)
		local inv = meta:get_inventory()
		if node.name == "default:furnace" or node.name == "default:furnace_active" then
			return tubelib.get_item(inv, "dst")
		else
			return tubelib.get_item(inv, "main")
		end
	end
	return nil
end

-- Param 'pos', 'facedir', and 'side' are used to determine the neighbor position.
-- Param 'pos' is the own position
-- Param 'facedir' is the own node facedir 
-- Param 'side' is one of F(orward), R(ight), B(ackward), L(eft), D(own), U(p)
-- relative to the placers view to the node.
-- Param 'item' is an item stack with one element like ItemStack("default:cobble")
function tubelib.push_items(pos, facedir, side, items)
	local node, dst_pos = tubelib.get_pos(pos, facedir, side)
	--print(node.name, items:get_name())
	if tubelib_NodeDef[node.name] and tubelib_NodeDef[node.name].on_push_item then
		return tubelib_NodeDef[node.name].on_push_item(dst_pos, items)
	elseif legacy_node(node) then
		local meta = minetest.get_meta(dst_pos)
		local inv = meta:get_inventory()
		if node.name == "default:furnace" or node.name == "default:furnace_active" then
			minetest.get_node_timer(dst_pos):start(1.0)
			if FuelTbl[items:get_name()] == true then
				return tubelib.put_item(inv, "fuel", items)
			else
				return tubelib.put_item(inv, "src", items)
			end
		else
			return tubelib.put_item(inv, "main", items)
		end
	elseif node and node.name == "air" then
		minetest.add_item(dst_pos, items)
		return true 
	end
	return false
end


-------------------------------------------------------------------
-- Server side helper functions
-------------------------------------------------------------------

-- Get one item from the given ItemList. The position within the list
-- is randomly selected so that different items stack will be considered.
-- Returns nil if ItemList is empty.
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

-- Get one item from the given ItemList, specified by stack number (1..n).
-- Returns nil if ItemList is empty.
function tubelib.get_this_item(inv, listname, number)
	if inv:is_empty(listname) then
		return nil
	end
	
	local items = inv:get_stack(listname, number)
	if items:get_count() > 0 then
		local taken = items:take_item(1)
		inv:set_stack(listname, number, items)
		return taken
	end
	return nil
end


-- Put the given item into the given ItemList.
-- Function returns false if ItemList is full.
function tubelib.put_item(inv, listname, item)
	if inv:room_for_item(listname, item) then
		inv:add_item(listname, item)
		return true
	end
	return false
end
