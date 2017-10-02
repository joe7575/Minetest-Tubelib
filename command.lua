--[[

	Tube Library
	============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	command.lua:

	Tubelib supports:
	 1) StackItem exchange via tubes and
	 2) wireless data communication between nodes.
	
	
	1. StackItem exchange 
	
	Tubes represent connection between two nodes, so that it is irrelevant
	if the receiving node is nearby or far away, connected via tubes.
	
	For StackItem exchange we have to distinguish the following roles:
	- client: An acting node calling push/pull functions
	- server: An addressed node typically with inventory, to be worked on
	
	
	2. Data communication
	
	For the data communication an addressing method based on node numbers is used. 
	Each registered node gets a unique number with 4 figures (or more if needed).
	The numbers are stored in a storage list. That means, a new node placed on 
	the same position gets the same number as the previouly	placed node on that 
	position.
	
	The communication supports two services:
	- send_message: Send a message to one or more nodes without response
	- send_request: Send a messages to exactly one node and request a response


	3. API funtions
	
    Before a node can take part on ItemStack exchange or data communication
	it has to be registered once via:
	- tubelib.register_node(name, add_names, node_definition)
		
	Each node shall call:
	- tubelib.add_node(pos, name) when it was placed and
	- tubelib.remove_node(pos) when it was dug.
	
	For StackItem exchange the following functions exist:
	- tubelib.pull_items(pos, side)
	- tubelib.push_items(pos, side, items)
	- tubelib.unpull_items(pos, side, items)
	
	For data communication the following functions exist:
	- tubelib.send_message(numbers, placer_name, clicker_name, topic, payload)
	- tubelib.send_request(number, placer_name, clicker_name, topic, payload)
	
	
	4. Examples
	
	Tubelib includes the following example nodes which can be used for study
	and as templates for own projects:
	
	- pusher.lua: 		a simple client pushing/pulling items
	- blackhole.lua:	a simple server client, makes all items disappear
	- button.lua:		a simple communication node, only sending messages
	- lamp.lua:         a simple communication node, only receiving messages
	
]]--

--  
--  The facedirs, contact-sides, coordinates, and orientations of a node:
--
--                 5/up/Y/-
--                         _ 
--                    /\    /| 0/back/Z/north
--                    |    /
--                    |   /
--                 +--|-----+
--                /   o    /|
--               +--------+ |
--         3 ----|        |o----> 1/right/X/east
--               |    o   | |
--               |   /    | +
--               |  /     |/
--               +-/------+
--                /   |
--               2    |
--                    4


-------------------------------------------------------------------
-- Data base storage
-------------------------------------------------------------------
local storage = minetest.get_mod_storage()
local Key2Number = minetest.deserialize(storage:get_string("Key2Number")) or {}
local NextNumber = minetest.deserialize(storage:get_string("NextNumber")) or 1
local Number2Pos = minetest.deserialize(storage:get_string("Number2Pos")) or {}

local function update_mod_storage()
	storage:set_string("Key2Number", minetest.serialize(Key2Number))
	storage:set_string("NextNumber", minetest.serialize(NextNumber))
	storage:set_string("Number2Pos", minetest.serialize(Number2Pos))
end

minetest.register_on_shutdown(function()
	update_mod_storage()
end)

-- store data each hour
minetest.after(60*60, update_mod_storage)


local Name2Name = {}		-- translation table

-------------------------------------------------------------------
-- Local helper functions
-------------------------------------------------------------------

-- Localize functions to avoid table lookups (better performance).
local string_find = string.find
local string_split = string.split
local minetest_is_protected = minetest.is_protected
local tubelib_NodeDef = tubelib.NodeDef
local get_neighbor_pos = tubelib.get_neighbor_pos

-- Translate from facedir to contact side of the other node
-- (left for one is right for the other node)
local FacedirToSide = {[0] = "F", "L", "B", "R", "U", "D"}

-- Generate a key string based on the given pos table,
-- Used internaly as table key,
local function get_key_str(pos)
	pos = minetest.pos_to_string(pos)
	return '"'..string.sub(pos, 2, -2)..'"'
end

-- Determine position related node number for addressing purposes
local function get_number(pos)
	local key = get_key_str(pos)
	if not Key2Number[key] then
		Key2Number[key] = NextNumber
		NextNumber = NextNumber + 1
	end
	return string.format("%.04u", Key2Number[key])
end

-- Determine the contact side of the node at the given pos
-- param facedir: facedir to the node
local function get_node_side(npos, facedir)	
	local node = minetest.get_node(npos)
	if facedir < 4 then
		facedir = (facedir - node.param2 + 4) % 4
	end
	return FacedirToSide[facedir], node
end


-------------------------------------------------------------------
-- API helper functions
-------------------------------------------------------------------
	
-- Check the given list of numbers.
-- Returns true if number(s) is/are valid and point to real nodes.
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

-- Function returns { pos, name } for the node on the given position number.
function tubelib.get_node_info(dest_num)
	if Number2Pos[dest_num] then
		return Number2Pos[dest_num]
	end
	return nil
end	


-------------------------------------------------------------------
-------------------------------------------------------------------
-- Node construction/destruction functions
-------------------------------------------------------------------
-------------------------------------------------------------------
	
-- Add node to the tubelib lists and update the tube surrounding.
-- Function determines and returns the node position number,
-- needed for message communication.
function tubelib.add_node(pos, name)
	-- store position 
	local number = get_number(pos)
	Number2Pos[number] = {
		pos = pos, 
		name = name,
	}
	-- update surrounding tubes
	tubelib.update_tubes(pos)
	return number
end

-- Function removes the node from the tubelib lists.
function tubelib.remove_node(pos)
	local number = get_number(pos)
	if Number2Pos[number] then
		Number2Pos[number] = {
			pos = pos, 
			name = nil,
		}
	end
end


-------------------------------------------------------------------
-- Node register function
-------------------------------------------------------------------

-- Register node for tubelib communication
-- Call this function only at load time!
-- Param name: The node name like "tubelib:pusher"
-- Param add_names: Alternativ node names if needded, e.g.: "tubelib:pusher_active"
-- Param node_definition: A table according to:
-- 
--    {
-- 	      -- Pull an item from the node inventory.
-- 	      -- The function shall return an item stack with one element
--        -- like ItemStack("default:cobble") or nil.
--        -- Param side: The node contact side, where the item shall be pulled out.
--        on_pull_item = func(pos, side),
--
--        -- Push the given item into the node inventory.
--        -- Function shall return true/false
--        -- Param side: The node contact side, where the item shall be pushed in.
--        on_push_item = func(pos, side, item),
--
--        -- Undo the previous pull and place the given item back into the inventory.
--        -- Param side: The node contact side, where the item shall be unpulled.
--        on_unpull_item = func(pos, side, item),
--
--        -- Execute the requested command
--        -- and return true/false for commands like start/stop 
--        -- or return the requested data for commands like a status request.
--        -- Param topic: A topic string like "start"
--        -- Param payload: Additional data for more come complex commands, 
--        --                payload can be a number, string, or table.
--        on_recv_message = func(pos, topic, payload),
--            -- 
--    }
--
function tubelib.register_node(name, add_names, node_definition)
	tubelib_NodeDef[name] = node_definition
	-- store facedir table for all known node names
	tubelib.knownNodes[name] = true
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
-- "placer_name" is the name of the player, who places the node.
-- "clicker_name" is the name of the player, who uses the node.
-- "placer_name" of sending and receiving nodes have to be the same.
-- If every player should be able to send a message, use nil for clicker_name.
-- Because several nodes could be addressed, the function don't return a response.
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
-- Request message function
-------------------------------------------------------------------

-- In contrast to "send_message" this functions send a message to exactly one block 
-- referenced by 'number' and delivers the node response. 
-- The message is based on the topic string (e.g. "status") and
-- topic related payload.
-- The placer and clicker names are needed to check the protection rights. 
-- "placer_name" is the name of the player, who places the node.
-- "clicker_name" is the name of the player, who uses the node.
-- "placer_name" of sending and receiving nodes have to be the same.
-- If every player should be able to send a message, use nil for clicker_name.
function tubelib.send_request(number, placer_name, clicker_name, topic, payload)
	if Number2Pos[number] and Number2Pos[number].name then
		local data = Number2Pos[number]
		if placer_name and not minetest_is_protected(data.pos, placer_name) then
			if clicker_name == nil or not minetest_is_protected(data.pos, clicker_name) then
				if data and data.name and tubelib_NodeDef[data.name].on_recv_message then
					return tubelib_NodeDef[data.name].on_recv_message(data.pos, topic, payload)
				end
			end
		end
	end
	return false
end		


-------------------------------------------------------------------
-------------------------------------------------------------------
-- Client side Push/Pull item functions
-------------------------------------------------------------------
-------------------------------------------------------------------

-- Pull one item from the given position specified by 'pos' and 'side'.
-- Param 'pos' is the own node position
-- Param 'side' is the contact side, where the item shall be pulled in 
-- The function returns an item stack with one element like ItemStack("default:cobble")
-- or nil.
function tubelib.pull_items(pos, side)
	local npos, facedir = get_neighbor_pos(pos, side)
	local nside, node = get_node_side(npos, facedir)
	local name = Name2Name[node.name]
	if tubelib_NodeDef[name] and tubelib_NodeDef[name].on_pull_item then
		return tubelib_NodeDef[name].on_pull_item(npos, nside)
	end
	return nil
end


-- Push one item to the given position specified by 'pos' and 'side'.
-- Param 'pos' is the own node position
-- Param 'side' is the contact side, where the item shall be pushed out 
-- Param 'item' is an item stack with one element like ItemStack("default:cobble")
function tubelib.push_items(pos, side, items)
	local npos, facedir = get_neighbor_pos(pos, side)
	local nside, node = get_node_side(npos, facedir)
	local name = Name2Name[node.name]
	if tubelib_NodeDef[name] and tubelib_NodeDef[name].on_push_item then
		return tubelib_NodeDef[name].on_push_item(npos, nside, items)	
	elseif node.name == "air" then
		minetest.add_item(npos, items)
		return true 
	end
	return false
end


-- Unpull the previously pulled item to the given position specified by 'pos' and 'side'.
-- Param 'pos' is the own node position
-- Param 'side' is the contact side, where the item shall be pushed out 
-- Param 'item' is an item stack with one element like ItemStack("default:cobble")
function tubelib.unpull_items(pos, side, items)
	local npos, facedir = get_neighbor_pos(pos, side)
	local nside, node = get_node_side(npos, facedir)
	local name = Name2Name[node.name]
	if tubelib_NodeDef[name] and tubelib_NodeDef[name].on_unpull_item then
		return tubelib_NodeDef[name].on_unpull_item(npos, nside, items)
	end
	return false
end
	
	

-------------------------------------------------------------------
-------------------------------------------------------------------
-- Server side helper functions
-------------------------------------------------------------------
-------------------------------------------------------------------

-- Get one item from the given ItemList. The position within the list
-- is incremented each time so that different item stacks will be considered.
-- Returns nil if ItemList is empty.
function tubelib.get_item(meta, listname)
	if meta == nil or meta.get_inventory == nil then return nil end
	local inv = meta:get_inventory()
	if inv:is_empty(listname) then
		return nil
	end
	local size = inv:get_size(listname)
	local startpos = meta:get_int("tubelib_startpos") or 0
	for idx = startpos, startpos+size do
		idx = (idx % size) + 1
		local items = inv:get_stack(listname, idx)
		if items:get_count() > 0 then
			local taken = items:take_item(1)
			inv:set_stack(listname, idx, items)
			meta:set_int("tubelib_startpos", idx)
			return taken
		end
	end
	meta:set_int("tubelib_startpos", 0)
	return nil
end

-- Get one item from the given ItemList, specified by stack number (1..n).
-- Returns nil if ItemList is empty.
function tubelib.get_this_item(meta, listname, number)
	if meta == nil or meta.get_inventory == nil then return nil end
	local inv = meta:get_inventory()
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
function tubelib.put_item(meta, listname, item)
	if meta == nil or meta.get_inventory == nil then return false end
	local inv = meta:get_inventory()
	if inv:room_for_item(listname, item) then
		inv:add_item(listname, item)
		return true
	end
	return false
end

-- Get the number of items from the given ItemList.
-- Returns nil if the number is not available.
function tubelib.get_num_items(meta, listname, num)
	if meta == nil or meta.get_inventory == nil then return nil end
	local inv = meta:get_inventory()
	if inv:is_empty(listname) then
		return nil
	end
	local size = inv:get_size(listname)
	for idx = 1, size do
		local items = inv:get_stack(listname, idx)
		if items:get_count() >= num then
			local taken = items:take_item(num)
			inv:set_stack(listname, idx, items)
			return taken
		end
	end
	return nil
end
