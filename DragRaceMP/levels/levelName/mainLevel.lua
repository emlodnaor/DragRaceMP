----------------------------
-- Freedom Factory script --
-- BON eM edit
----------------------------

-- MPCoreNetwork.isMPSession()

local M = {}

local Objects = {}

local lane_vehicles = { 0, 0 }

local in_prestage = { false, false }
local has_finished = { false, false }

local in_stage = { false, false }
local in_stage_time = 0

local in_false_start = false

local in_race = false
local in_race_time = 0

local function numInPreStage()
	local ret = 0
	if in_prestage[1] then ret = ret + 1 end
	if in_prestage[2] then ret = ret + 1 end
	return ret
end

local function allInStage()
	local numPrestage = numInPreStage()
	if numPrestage == 0 then
		return false
	end

	local num = 0
	if in_stage[1] then num = num + 1 end
	if in_stage[2] then num = num + 1 end
	return num == numPrestage
end

local function resetLaneLights(lane)
	Objects[lane].lights.prestage:setHidden(true)
	Objects[lane].lights.stage:setHidden(true)
	for _, v in ipairs(Objects[lane].lights.amber) do
		v:setHidden(true)
	end
	Objects[lane].lights.green:setHidden(true)
	Objects[lane].lights.red:setHidden(true)
end

local function resetDisplay(display)
	for _, v in ipairs(display.digits) do
		v:setHidden(true)
	end
	display.dot:setHidden(true)
end

local function resetLaneDisplays(lane)
	resetDisplay(Objects[lane].displays.time)
	resetDisplay(Objects[lane].displays.speed)
end

local function setDisplay(display, number, digits)
	if number == 0 then
		resetDisplay(display)
		return
	end

	local str_left = tostring(math.floor(number) % (10 ^ digits))
	local str_right = tostring(number % 1):sub(3)

	for i = 1, 5, 1 do
		local c = '0'
		if i <= digits then
			local index = i - (digits - #str_left)
			c = str_left:sub(index, index)
		else
			local index = i - digits
			c = str_right:sub(index, index)
		end

		if c ~= '' then
			local path = 'art/shapes/quarter_mile_display/display_' .. c .. '.dae'

			display.digits[i]:preApply()
			display.digits[i]:setField('shapeName', 0, path)
			display.digits[i]:setHidden(false)
			display.digits[i]:postApply()
		else
			display.digits[i]:setHidden(true)
		end
	end

	display.dot:setHidden(false)
end

local function resetLane(lane)
	resetLaneLights(lane)
	resetLaneDisplays(lane)
end

local function resetAll()
	resetLane(1)
	resetLane(2)

	lane_vehicles = { 0, 0 }

	in_prestage = { false, false }
	in_stage = { false, false }
	has_finished = { false, false }
	in_false_start = false
	in_race = false
end

local function stopWithReason(reason)
	print('== Stopping: ' .. reason)
	resetAll()
	--TODO: Show notification
end

local function getObjects(side)
	local ret = {}

	ret.lights = {}
	ret.lights.prestage = scenetree.findObject('lightPrestage' .. side)
	ret.lights.stage = scenetree.findObject('lightStage' .. side)
	ret.lights.amber = {
		scenetree.findObject('lightAmber' .. side .. '1'),
		scenetree.findObject('lightAmber' .. side .. '2'),
		scenetree.findObject('lightAmber' .. side .. '3'),
	}
	ret.lights.green = scenetree.findObject('lightGreen' .. side)
	ret.lights.red = scenetree.findObject('lightRed' .. side)

	ret.displays = {}
	ret.displays.time = {
		digits = {
			scenetree.findObject('timeDisp' .. side .. '1'),
			scenetree.findObject('timeDisp' .. side .. '2'),
			scenetree.findObject('timeDisp' .. side .. '3'),
			scenetree.findObject('timeDisp' .. side .. '4'),
			scenetree.findObject('timeDisp' .. side .. '5'),
		},
		dot = scenetree.findObject('timeDisp' .. side .. 'Dot'),
	}
	ret.displays.speed = {
		digits = {
			scenetree.findObject('speedDisp' .. side .. '1'),
			scenetree.findObject('speedDisp' .. side .. '2'),
			scenetree.findObject('speedDisp' .. side .. '3'),
			scenetree.findObject('speedDisp' .. side .. '4'),
			scenetree.findObject('speedDisp' .. side .. '5'),
		},
		dot = scenetree.findObject('speedDisp' .. side .. 'Dot'),
	}

	return ret
end

local function loadObjects()
	Objects = {
		getObjects('L'),
		getObjects('R'),
	}
end

local function findVehicleLane(vehicle)
	if lane_vehicles[1] == vehicle then
		return 1
	elseif lane_vehicles[2] == vehicle then
		return 2
	end
	return 0
end

local function onClientPostStartMission()
	loadObjects()
	resetAll()

	print('== Freedom script initialized')
end

local function onExtensionLoaded()
	loadObjects()

	if Objects[1].lights.prestage ~= nil then
		resetAll()

		print('== Freedom script initialized from reload')
	end
end

local function checkLaneTriggers(lane, data)
	local side = ''
	if lane == 1 then
		side = 'L'
	elseif lane == 2 then
		side = 'R'
	end

	if data.event == 'exit' then
		if in_race and not has_finished[lane] then
			if data.triggerName == 'laneTrig' .. side then
				stopWithReason(side .. ' lane was exited mid-race')
			end

		elseif in_prestage[lane] and not in_stage[lane] then
			if data.triggerName == 'prestageTrig' .. side then
				in_prestage[lane] = false
				Objects[lane].lights.prestage:setHidden(true)
			end

		elseif in_stage[lane] then
			if data.triggerName == 'stageTrig' .. side then
				stopWithReason(side .. ' left stage trigger prematurely')
			end
		end
	end

	if data.event == 'enter' then
		if not in_race then -- All of these triggers are pre-race so we must not be in a race to use these
			if not in_prestage[lane] then
				if data.triggerName == 'prestageTrig' .. side then
					if in_false_start then
						in_false_start = false
						Objects[lane].lights.red:setHidden(true)
					end

					in_prestage[lane] = true
					Objects[lane].lights.prestage:setHidden(false)
					resetLaneDisplays(lane)

					lane_vehicles[lane] = data.subjectID
				end

			elseif not in_stage[lane] then
				if data.triggerName == 'startTrig' .. side then
					has_finished[lane] = false
					in_stage[lane] = true
					in_stage_time = 0
					Objects[lane].lights.stage:setHidden(false)
				end

			elseif in_stage[lane] then
				if data.triggerName == 'falseStartTrig' then
					stopWithReason('False start from ' .. side)
					in_false_start = true
					Objects[lane].lights.red:setHidden(false)
				end
			end
		end
	end
end

local function onBeamNGTrigger(data)
	if MPCoreNetwork.isMPSession() then
		return
	end
	checkLaneTriggers(1, data)
	checkLaneTriggers(2, data)

	if data.event == 'enter' then
		if in_race then
			if data.triggerName == 'finishTrig' then
				local vehicle = be:getObjectByID(data.subjectID)
				local lane = findVehicleLane(data.subjectID)

				local finishtime = in_race_time
				local finishspeed = vehicle:getVelocity():len() * 2.2369362920544

				print('====== Lane ' .. lane .. ' ======')
				print('==  Finish time: ' .. finishtime)
				print('== Finish speed: ' .. finishspeed)

				--TODO: Show notification

				setDisplay(Objects[lane].displays.time, finishtime, 2)
				setDisplay(Objects[lane].displays.speed, finishspeed, 3)

				in_prestage[lane] = false
				in_stage[lane] = false
				has_finished[lane] = true
				lane_vehicles[lane] = 0
				resetLaneLights(lane)

				if numInPreStage() == 0 then
					print('== End of race!')
					in_race = false
				end
			end
		end
	end
end

local function onUpdate(dtReal, dtSim, dtRaw)
	if MPCoreNetwork.isMPSession() then
		return		
	end

	if in_race then
		in_race_time = in_race_time + dtSim

	elseif allInStage() then
		
		in_stage_time = in_stage_time + dtSim * 2

		local seconds = math.floor(in_stage_time - 1)

		for lane = 1, 2, 1 do
			if in_stage[lane] then
				for i, v in ipairs(Objects[lane].lights.amber) do
					v:setHidden(seconds ~= i)
				end
				Objects[lane].lights.green:setHidden(seconds < 4)
			end
		end

		if seconds >= 4 then
			in_race = true
			in_race_time = 0
		end
	end
end

M.onClientPostStartMission = onClientPostStartMission
M.onExtensionLoaded = onExtensionLoaded
M.onBeamNGTrigger = onBeamNGTrigger
M.onUpdate = onUpdate

return M

-- Old notes
-- Yes I know the code sucks, it honestly should be entirely rewritten!
--
-- This code was originally written to support only 1 player in 1 lane,
-- but later modified to support 2 lanes at a time, for BeamMP and to
-- allow playing in the left lane instead of the right one. This made
-- the code a lot more complex than it should be.
--
-- Some things to note when rewriting this:
--   * Should have separate objects for each lane
--   * Should support multiple races at a time (eg. allow people to pre-
--     stage while a race is in progress)
--   * Could have some sort of integration with BeamMP to make sure netsync
--     is done properly (eg. for drop-in players)
--     shot when the player crosses the finish line

