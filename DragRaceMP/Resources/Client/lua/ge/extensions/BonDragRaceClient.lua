---------------------
-- DragRace Client --
-- Beams of Norway --
---------------------
local M = {}
BONDEBUG = false

local function onBeamNGTrigger(data)
    debugPrint()
	local currentOsClockHp = os.clockhp()
    debugPrint()
	local jsonData = jsonEncode({eventType = "BonDragRaceTrigger", triggerInfo = data, osclockhp = currentOsClockHp})
    debugPrint()
    TriggerServerEvent("onBonDragRaceTrigger", jsonData)
    debugPrint()
	return
end

function BonDragRaceLights(data)
	--{lightName = lightName, state = lightState }
	dataDecoded = jsonDecode(data)
    debugPrint(dataDecoded)
	local light = scenetree.findObject(dataDecoded.lightName)
    debugPrint()
	light:setHidden(not dataDecoded.state)
    debugPrint()
end


function onExtensionLoaded()
    print("BON.lua Loaded")
end
function onExtensionUnloaded()
    print("BON.lua Unloaded")
end
--BonDragRaceLights
AddEventHandler("BonDragRaceLights", BonDragRaceLights) 

M.onInit = function() setExtensionUnloadMode(M, "manual") end

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