---------------------
-- DragRace Client --
-- Beams of Norway --
---------------------
local M = {}
Displays = {}
BONDEBUG = false
local function getObjects(side)
	ret = {}
	ret.time = {
		digits = {
			scenetree.findObject('timeDisp' .. side .. '1'),
			scenetree.findObject('timeDisp' .. side .. '2'),
			scenetree.findObject('timeDisp' .. side .. '3'),
			scenetree.findObject('timeDisp' .. side .. '4'),
			scenetree.findObject('timeDisp' .. side .. '5'),
		},
		dot = scenetree.findObject('timeDisp' .. side .. 'Dot'),
	}
	ret.speed = {
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

local function BonDragRaceClientResetDisplay(display)
	for _, v in ipairs(display.digits) do
		v:setHidden(true)
	end
	display.dot:setHidden(true)
end

local function BonDragRaceClientResetLaneDisplays(lane)
	BonDragRaceClientResetDisplay(Displays[lane].time)
	BonDragRaceClientResetDisplay(Displays[lane].speed)
end

local function BonDragRaceClientSetDisplay(display, number, isTimeDisplay)
    -- Check if the number is 0
    if number == 0 then
        BonDragRaceClientResetDisplay(display)
        return
    end
	
   -- Convert the number to a string
    local str_number = tostring(number)
	dump(number)
	dump(str_number)

	local str_left = ""
	local str_right = ""
	local afterComma = false
	local hideDot = false

	local str_number = tostring(number)
	local str_left = ""
	local str_right = ""
	local afterComma = false

	for i = 1, #str_number, 1 do
		if str_number:sub(i, i) == "." then
			afterComma = true
		else
        if afterComma then
            str_right = str_right .. str_number:sub(i, i)
			
			else
	            str_left = str_left .. str_number:sub(i, i)
			end
	    end
	end

	--make sure the number string has the correct length 
	local dot_position = isTimeDisplay and 2 or 3
	
	if #str_left > dot_position then
		hideDot = true
		dot_position = 5
	end

	while #str_left < dot_position do
		str_left = " "..str_left
	end
	
	local afterDot = 5 - dot_position
	while #str_right < afterDot do
		str_right = str_right .. "0"
	end

	print("l92")
	dump(str_left)
	dump(str_right)
	
	-- Update the display
    for i = 1, 5, 1 do
		local c = ' '
		if i <= dot_position then
			c = str_left:sub(i,i)
		else
			c = str_right:sub(i-dot_position, i-dot_position)
		end
		dump(c)
		
		if c ~= ' ' then
            local path = 'art/shapes/quarter_mile_display/display_' .. c .. '.dae'

            display.digits[i]:preApply()
            display.digits[i]:setField('shapeName', 0, path)
            display.digits[i]:setHidden(false)
            display.digits[i]:postApply()
        else
            display.digits[i]:setHidden(true)
        end
    end

    display.dot:setHidden(hideDot)
end

local function BonDragRaceClientDisplayUpdate(data) -- leftDisplay/rightDisplay -> hidden, time, speed
	local decodedData = jsonDecode(data)
	debugPrint(decodedData)
	dump(decodedData)
	leftDisplayInfo = decodedData.leftDisplay
	rightDisplayInfo = decodedData.rightDisplay

	leftTimeDisplay = Displays[1].time
	leftSpeedDisplay = Displays[1].speed
	rightTimeDisplay = Displays[2].time
	rightSpeedDisplay = Displays[2].speed
	
	BonDragRaceClientSetDisplay(leftTimeDisplay, leftDisplayInfo.time, true)
	BonDragRaceClientSetDisplay(leftSpeedDisplay, leftDisplayInfo.speed, false)
	BonDragRaceClientSetDisplay(rightTimeDisplay, rightDisplayInfo.time, true)
	BonDragRaceClientSetDisplay(rightSpeedDisplay, rightDisplayInfo.speed, false)

	if leftDisplayInfo.hidden then
		BonDragRaceClientResetLaneDisplays(1)
	end
	if rightDisplayInfo.hidden then
		BonDragRaceClientResetLaneDisplays(2)
	end
end
local function onBeamNGTrigger(data)
    debugPrint()
	local currentOsClockHp = os.clockhp()
    debugPrint()
	local vehicle = be:getObjectByID(data.subjectID)
	local velLen = vehicle:getVelocity():len()
	local jsonData = jsonEncode({eventType = "BonDragRaceTrigger", triggerInfo = data, osclockhp = currentOsClockHp, velocityLen = velLen})
    debugPrint()
    TriggerServerEvent("onBonDragRaceTrigger", jsonData)
    debugPrint()
	return
end

function BonDragRaceLights(data)
	--{lightName = lightName, state = lightState }
	local dataDecoded = jsonDecode(data)
    debugPrint(dataDecoded)
	local light = scenetree.findObject(dataDecoded.lightName)
    debugPrint()
	light:setHidden(not dataDecoded.state)
    debugPrint()
end

function BonDragRaceReportStartTime(data)
    local decodedData = jsonDecode(data)
    local raceNr = decodedData.raceNr
    local jsonData = jsonEncode({eventType = "BonDragRaceStartTimeReport", osclockhp = os.clockhp()})
    TriggerServerEvent("onBonDragRaceStartTimeReport", jsonData)
end

function onExtensionLoaded()
	Displays = {
		getObjects('L'), --rename to be more unique??
		getObjects('R'),
	}
    print("BON.lua Loaded")
end
function onExtensionUnloaded()
    print("BON.lua Unloaded")
end
--BonDragRaceLights
AddEventHandler("BonDragRaceLights", BonDragRaceLights)
AddEventHandler("BonDragRaceReportStartTime", BonDragRaceReportStartTime)
AddEventHandler("BonDragRaceClientDisplayUpdate", BonDragRaceClientDisplayUpdate)

M.onInit = function() setExtensionUnloadMode(M, "manual") end

M.BonDragRaceReportStartTime = BonDragRaceReportStartTime
M.BonDragRaceClientDisplayUpdate = BonDragRaceClientDisplayUpdate
M.onBeamNGTrigger = onBeamNGTrigger
M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded

M.BonDragRaceLights = BonDragRaceLights

--
function debugPrint(...)
    if not BONDEBUG then return end
    local info = debug.getinfo(2, "nSl")
    local source = info.short_src or info.source or "unknown"
    local line = info.currentline or 0
    local funcName = info.name or "unknown function"

    local debugInfo = string.format("[%s:%d - %s] ", source, line, funcName)
    print(debugInfo, ...)
end
print("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAARHRHRHRHRHRHRHRHRHRHRHRHRHRHRHR")
print("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAARHRHRHRHRHRHRHRHRHRHRHRHRHRHRHR")
print("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAARHRHRHRHRHRHRHRHRHRHRHRHRHRHRHR")
print("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAARHRHRHRHRHRHRHRHRHRHRHRHRHRHRHR")
print("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAARHRHRHRHRHRHRHRHRHRHRHRHRHRHRHR")
return M