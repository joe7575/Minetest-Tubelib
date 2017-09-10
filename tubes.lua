--[[

	Tube Library
	============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--

local MAX_TUBE_LENGTH = 100

local TubeTypes = {
	0,0,0,0,0,0,1,3,1,3,	-- 01-10
	4,5,3,1,3,1,4,5,1,3,	-- 11-20
	1,3,4,5,3,1,3,1,4,5,	-- 21-30
	2,2,2,2,0,2,2,2,5,2,	-- 31-40
	5,0,					-- 40-41
}

local TubeFacedir = {
	0,0,0,0,0,0,0,2,0,1,	-- 01-10
	2,2,2,1,3,1,3,3,0,3,	-- 11-20
	0,0,0,0,1,1,0,1,1,1,	-- 21-30
	0,0,0,0,0,0,0,0,0,0,	-- 31-40
	0,0,					-- 40-41
}



-- Return neighbor tubes orientation relative to the given pos.
local function get_neighbor_tubes_orientation(pos)
	local orientation = 0
	local Nodes = {
		minetest.get_node({x=pos.x  , y=pos.y  , z=pos.z+1}),
		minetest.get_node({x=pos.x+1, y=pos.y  , z=pos.z  }),
		minetest.get_node({x=pos.x  , y=pos.y  , z=pos.z-1}),
		minetest.get_node({x=pos.x-1, y=pos.y  , z=pos.z  }),
		minetest.get_node({x=pos.x  , y=pos.y-1, z=pos.z  }),
		minetest.get_node({x=pos.x  , y=pos.y+1, z=pos.z  }),
	}
	for side,node in ipairs(Nodes) do
		if tubelib.knownNodes[node.name] then
			orientation = orientation * 6 + side
			if orientation > 6 then 
				break
			end
		end
	end
	return orientation
end	

local function determine_tube_node(pos)
	local node = minetest.get_node(pos) 
	if not string.find(node.name, "tubelib:tube") then
		return nil
	end
	local orientation = get_neighbor_tubes_orientation(pos)
	if orientation > 6 then 
		node.name = "tubelib:tube"..TubeTypes[orientation]
		node.param2 = TubeFacedir[orientation]
		return node
	elseif orientation > 0 then 
		orientation = orientation * 6 + (((node.param2 + 2) % 4) + 1)
		node.name = "tubelib:tube"..TubeTypes[orientation]
		node.param2 = TubeFacedir[orientation]
		return node
	end
	return nil
end	

	
local function update_tube(pos)
	local node = determine_tube_node(pos)
	if node then
		minetest.swap_node(pos, node)
	end
end		

local OffsTable = {
	{2,0},		-- tube1
	{4,5},		-- tube2
	{2,3},		-- tube3
	{2,4},		-- tube4
	{2,5},		-- tube5
}

local function nodetype_to_pos(pos, pos1, node)
	local idx = string.byte(node.name, -1) - 48
	local facedir1 = OffsTable[idx][1]
	local facedir2 = OffsTable[idx][2]
	if facedir1 < 4 then
		facedir1 = (facedir1 + node.param2) % 4
	end
	if facedir2 < 4 then
		facedir2 = (facedir2 + node.param2) % 4
	end
	local dir1 = tubelib.facedir_to_dir(facedir1)
	local dir2 = tubelib.facedir_to_dir(facedir2)
	local p1 = vector.add(pos1, dir1)
	local p2 = vector.add(pos1, dir2)

	if pos == nil then
		return p1, p2
	elseif vector.equals(p1, pos) then
		return p2
	else
		return p1
	end
end
	
local function walk_to_peer(pos, pos1)
	local node = minetest.get_node(pos1)
	local pos2
	local cnt = 0
	while string.find(node.name, "tubelib:tube") and cnt < MAX_TUBE_LENGTH do
		pos2 = nodetype_to_pos(pos, pos1, node)
		pos, pos1 = pos1, pos2
		cnt = cnt + 1
		node = minetest.get_node(pos1)
	end
	return cnt, pos, pos1
end	

local function update_head_tubes(pos)
	local node = minetest.get_node(pos)
	if string.find(node.name, "tubelib:tube") then
		local pos1, pos2 = nodetype_to_pos(nil, pos, node)
		local cnt1, peer1, dest1 = walk_to_peer(pos, pos1)
		local cnt2, peer2, dest2 = walk_to_peer(pos, pos2)
		if cnt1 == 0 and cnt2 == 0 then	-- first tube node placed?
			-- we have to store both dest positions, used by
			minetest.get_meta(peer1):set_string("dest_pos", minetest.pos_to_string(dest2))
			minetest.get_meta(peer2):set_string("dest_pos2", minetest.pos_to_string(dest1))
			minetest.get_meta(peer1):set_string("infotext", minetest.pos_to_string(dest1)..":"..minetest.pos_to_string(dest2))
		else
			minetest.get_meta(peer1):set_string("dest_pos", minetest.pos_to_string(dest2))
			minetest.get_meta(peer2):set_string("dest_pos", minetest.pos_to_string(dest1))
			minetest.get_meta(peer1):set_string("infotext", minetest.pos_to_string(dest2))
			minetest.get_meta(peer2):set_string("infotext", minetest.pos_to_string(dest1))
		end
		-- delete meta data from old head nodes
		if cnt1 > 1 then
			minetest.get_meta(pos1):set_string("dest_pos", nil)
			minetest.get_meta(pos1):set_string("infotext", nil)
		end
		if cnt2 > 1 then
			minetest.get_meta(pos2):set_string("dest_pos", nil)
			minetest.get_meta(pos2):set_string("infotext", nil)
		end
	end
end	
		
local function update_surrounding_tubes(pos)
	update_tube({x=pos.x  , y=pos.y  , z=pos.z+1})
	update_tube({x=pos.x+1, y=pos.y  , z=pos.z  })
	update_tube({x=pos.x  , y=pos.y  , z=pos.z-1})
	update_tube({x=pos.x-1, y=pos.y  , z=pos.z  })
	update_tube({x=pos.x  , y=pos.y-1, z=pos.z  })
	update_tube({x=pos.x  , y=pos.y+1, z=pos.z  })
	update_tube(pos)
	update_head_tubes(pos)
end		

local function after_tube_removed(pos, node)
	local pos1, pos2 = nodetype_to_pos(nil, pos, node)
	local cnt1, peer1, dest1 = walk_to_peer(pos, pos1)
	local cnt2, peer2, dest2 = walk_to_peer(pos, pos2)
	minetest.get_meta(peer1):set_string("dest_pos", minetest.pos_to_string(pos))
	minetest.get_meta(peer1):set_string("infotext", minetest.pos_to_string(pos))
	minetest.get_meta(peer2):set_string("dest_pos", minetest.pos_to_string(pos))
	minetest.get_meta(peer2):set_string("infotext", minetest.pos_to_string(pos))
	if cnt1 > 0 then
		minetest.get_meta(pos1):set_string("dest_pos", minetest.pos_to_string(dest1))
		minetest.get_meta(pos1):set_string("infotext", minetest.pos_to_string(dest1))
	end
	if cnt2 > 0 then
		minetest.get_meta(pos2):set_string("dest_pos", minetest.pos_to_string(dest2))
		minetest.get_meta(pos2):set_string("infotext", minetest.pos_to_string(dest2))
	end
end	
	
local DefNodeboxes = {
    -- x1   y1    z1     x2   y2   z2
    { -1/4, -1/4, -1/4,  1/4, 1/4, 1/4 },
    { -1/4, -1/4, -1/4,  1/4, 1/4, 1/4 },
}

local DirCorrections = {
    {3, 6}, {2, 5},             		-- standard tubes
    {3, 1}, {3, 2}, {3, 5},   	-- knees from front to..
}

local SelectBoxes = {
	{ -1/4, -1/4, -1/2,  1/4, 1/4, 1/2 },
	{ -1/4, -1/2, -1/4,  1/4, 1/2, 1/4 },
	{ -1/2, -1/4, -1/2,  1/4, 1/4, 1/4 },
	{ -1/4, -1/2, -1/2,  1/4, 1/4, 1/4 },
	{ -1/4, -1/4, -1/2,  1/4, 1/2, 1/4 },
}

local TilesData = {
    -- up, down, right, left, back, front
	{
		"tubelib_tube.png^[transformR90",
		"tubelib_tube.png^[transformR90",
		"tubelib_tube.png",
		"tubelib_tube.png",
		"tubelib_hole.png",
		"tubelib_hole.png",
	},
	{
		"tubelib_hole.png",
		"tubelib_hole.png",
		"tubelib_tube.png^[transformR90",
		"tubelib_tube.png^[transformR90",
		"tubelib_tube.png^[transformR90",
        "tubelib_tube.png^[transformR90",
	},
    {
        "tubelib_knee.png^[transformR270",
        "tubelib_knee.png^[transformR180",
        "tubelib_knee2.png^[transformR270",
        "tubelib_hole2.png^[transformR90",
        "tubelib_knee2.png^[transformR90",
        "tubelib_hole2.png^[transformR270",
    },
    {
        "tubelib_knee2.png",
        "tubelib_hole2.png^[transformR180",
        "tubelib_knee.png^[transformR270",
        "tubelib_knee.png",
        "tubelib_knee2.png",
        "tubelib_hole2.png",
    },
    {
        "tubelib_hole2.png",
        "tubelib_knee2.png^[transformR180",
        "tubelib_knee.png^[transformR180",
        "tubelib_knee.png^[transformR90",
        "tubelib_knee2.png^[transformR180",
        "tubelib_hole2.png^[transformR180",
    },
}


for idx,pos in ipairs(DirCorrections) do
    node_box_data = table.copy(DefNodeboxes)
    node_box_data[1][pos[1]] = node_box_data[1][pos[1]] * 2
    node_box_data[2][pos[2]] = node_box_data[2][pos[2]] * 2

	tiles_data = TilesData[idx]
	
	if idx == 1 then
		hidden = 0
	else
		hidden = 1
	end
    minetest.register_node("tubelib:tube"..idx, {
        description = "Tubelib Tube",
        tiles = tiles_data,
        drawtype = "nodebox",
        node_box = {
          type = "fixed",
          fixed = node_box_data,
        },
		selection_box = {
			type = "fixed",
			fixed = SelectBoxes[idx],
		},
		collision_box = {
			type = "fixed",
			fixed = SelectBoxes[idx],
		},
		
		after_place_node = function(pos, placer, itemstack, pointed_thing)
			update_surrounding_tubes(pos)
		end,
		
		after_dig_node = function(pos, oldnode, oldmetadata, digger)
			after_tube_removed(pos, oldnode)
		end,
        paramtype2 = "facedir",
        paramtype = "light",
        sunlight_propagates = true,
        is_ground_content = false,
		groups = {cracky=3, stone=1, not_in_creative_inventory=hidden},
		drop = "tubelib:tube1",
    })
end


minetest.register_craft({
	output = "tubelib:tube1 4",
	recipe = {
		{"default:steel_ingot", "",    "group:wood"},
		{"",           "group:wood",   ""},
		{"group:wood", "",             "default:tin_ingot"},
	},
})
