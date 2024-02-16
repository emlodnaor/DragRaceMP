---------------------
-- DragRace Client --
-- Beams of Norway --
---------------------
local M = {}

local function onBeamNGTrigger(data)
	local currentOsClockHp = os.clockhp()
	local jsonData = jsonEncode({eventType = "BonDragRaceTrigger", triggerInfo = data, osclockhp = currentOsClockHp})
    TriggerServerEvent("onBonDragRaceTrigger", jsonData)
	return
end



return M