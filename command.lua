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


-------------------------------------------------------------------
-- Helper functions
-------------------------------------------------------------------

-- Store receive function for each type of block
tubelib.ReceiveFunction = {}


-- Determine position related node number for addressing purposes
local function get_number(pos)
	local key = tubelib.get_key_str(pos)
	if not Key2Number[key] then
		Key2Number[key] = NextNumber
		NextNumber = NextNumber + 1
	end
	return string.format("%.04u", Key2Number[key])
end
	
-- Get server block data { pos, name, owner }	
function tubelib.get_server(dest_num)
	if Number2Pos[dest_num] then
		return Number2Pos[dest_num]
	end
	return nil
end	


-- Return true if number(s) is/are known
function tubelib.check_numbers(numbers)
	if numbers then
		for _,num in ipairs(string.split(numbers, " ")) do
			if Number2Pos[num] == nil then
				return false
			end
		end
		return true
	end
	return false
end	

	
-------------------------------------------------------------------
-- Registration functions
-------------------------------------------------------------------

-- Add server node position to the tubelib data base
-- Function returns the assigned number for communication.
function tubelib.add_server_node(pos, name, placer)
	local number = get_number(pos)
	Number2Pos[number] = {
		pos = pos, 
		name = name,
		owner = placer:get_player_name()
	}
	tubelib.update_mod_storage()
	return number
end

-- Register server receive function for tubelib commmunication
-- Call this function only at load time!
function tubelib.register_receive_function(name, recv_clbk)
	tubelib.ReceiveFunction[name] = recv_clbk
end

-------------------------------------------------------------------
-- Send function
-------------------------------------------------------------------

-- Send a command to all blocks referenced by 'numbers', a list of 
-- one or more destination addressses separated by blanks. 
-- The command is based on the topic string (e.g. "start") and
-- topic related payload.
-- The player_name is needed to check the protection rights. If player is unknown
-- use nil instead.
function tubelib.send_cmnd(numbers, player_name, topic, payload)
	for _,num in ipairs(string.split(numbers, " ")) do
		if Number2Pos[num] then
			local data = Number2Pos[num]
			if player_name == nil or not minetest.is_protected(data.pos, player_name) then
				if tubelib.ReceiveFunction[data.name] then
					tubelib.ReceiveFunction[data.name](data.pos, topic, payload)
				end
			end
		end
	end
end		

