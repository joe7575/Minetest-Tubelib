--[[

	Tube Library
	============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	states.lua:

	A state model for tubelib nodes.

]]--

tubelib.STOPPED = 1		-- not operational
tubelib.RUNNING = 2		-- in normal operation
tubelib.STANDBY = 3		-- nothing to do or blocked anyhow
tubelib.ERROR   = 4		-- any funtional error, which has to be fixed by the player

tubelib.StatesStr = {"stopped", "running", "standby", "error"}

tubelib.StatesImg = {
	"tubelib_inv_button_off.png", 
	"tubelib_inv_button_on.png", 
	"tubelib_inv_button_standby.png", 
	"tubelib_inv_button_error.png"
}
			
-- Return state button image for the node inventory
function tubelib.state_button(state)
	if state and state < 5 and state > 0 then
		return tubelib.StatesImg[state]
	end
	return tubelib.StatesImg[tubelib.ERROR]
end
			
-- Return state string for the request message
function tubelib.state_string(state)
	if state and state < 5 and state > 0 then
		return tubelib.StatesStr[state]
	end
	return tubelib.StatesStr[tubelib.ERROR]
end
			
