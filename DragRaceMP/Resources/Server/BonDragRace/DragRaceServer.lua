---------------------
-- DragRace Server --
-- Beams of Norway --
---------------------
BonDragRace = {}
BonDragRace.racelog = {}
BonDragRace.currentRace = 0

function handleOnBonDragRaceTrigger(sender_id, data)
    if data == "" then
        print(sender_id..": No data recived...")
    end
    local entered = triggerEvent == "enter"
    local theData = Util.JsonDecode(data)
    local triggerInfo = theData.triggerInfo
    local triggerEvent = triggerInfo.event
    local triggerName = triggerInfo.triggerName
    local clientClock = osclockhp

    if triggerName == "prestageTrigL" then
        BonDragRaceControllLights("lightPreStageL", entered)
        createNewRaceIfNeeded()
        BonDragRace.racelog[BonDragRace.currentRace].leftPlayer = sender_id
    end
    if triggerName == "prestageTrigR" then
        BonDragRaceControllLights("lightPreStageR", entered)
        createNewRaceIfNeeded()
        BonDragRace.racelog[BonDragRace.currentRace].rightPlayer = sender_id
    end
    if triggerName == "startTrigL" then
        BonDragRaceControllLights("lightStageL", entered)
        BonDragRace.racelog[BonDragRace.currentRace].leftReady = true
    end
    if triggerName == "startTrigR" then
        BonDragRaceControllLights("lightStageR", entered)
        BonDragRace.racelog[BonDragRace.currentRace].rightReady = true
    end
    if triggerName == "falseStartTrig" then
        if BonDragRace.raceActive and not BonDragRace.raceStarted then
            BonDragRaceControllLights("lightRedL", entered) -- detemine L/R by sender_id
            BonDragRaceControllLights("lightRedR", entered) -- detemine L/R by sender_id
        end
    end
    if triggerName == "finishTrig" then
        BonDragRace.racelog[BonDragRace.currentRace].finished = true
    end

    if BonDragRace.racelog[BonDragRace.currentRace].triggerTimes ~= nil then
        BonDragRace.racelog[BonDragRace.currentRace].triggerTimes[triggername.."-"..triggerEvent] = clientClock
    end
end

function createNewRaceIfNeeded()
    local raceId = BonDragRace.currentRace
    if BonDragRace.racelog[BonDragRace.currentRace] == nil then
        createNewRace(raceId)
    elseif BonDragRace.racelog[BonDragRace.currentRace].finished then
        createNewRace(raceId + 1)
    end
end
function createNewRace(raceId)
    BonDragRace.racelog[raceId] = {}
    BonDragRace.racelog[raceId].triggerTimes = {}
end

function BonDragRaceControllLights(lightName, lightState)
    local data = {lightName = lightName, state = lightState }
    MP.TriggerClientEventJson(-1, "BonDragRaceLights", data)
    BonDragRace.rightPlayer = sender_id
end

function MyChatMessageHandler(sender_id, sender_name, message)
    if startsWith(message,"/help") then
        
        return 1
    else
        return 0
    end
end
function startRace(currentRace)
    BonDragRace.racelog[BonDragRace.currentRace].started = true
    BonDragRaceAmberLights(false)
    BonDragRaceGreenLights(true)
end

function BonDragRaceAmberLights(lightState)
     BonDragRaceControllLights("lightAmberL1", lightState)
     BonDragRaceControllLights("lightAmberL2", lightState)
     BonDragRaceControllLights("lightAmberL3", lightState)
     BonDragRaceControllLights("lightAmberR1", lightState)
     BonDragRaceControllLights("lightAmberR2", lightState)
     BonDragRaceControllLights("lightAmberR3", lightState)
end
function BonDragRaceGreenLights(lightState)
    BonDragRaceControllLights("lightGreenL", lightState)
    BonDragRaceControllLights("lightGreenR", lightState)
end

function handleTimer()
    if BonDragRace.racelog[BonDragRace.currentRace] == nil then return end
    local currentRace = BonDragRace.racelog[BonDragRace.currentRace]
    if not currentRace.started and currentRace.countdown == 0 then
        startRace(BonDragRace.currentRace)
    end
    if currentRace.activated and not currentRace.started then
        BonDragRace.racelog[BonDragRace.currentRace].countdown = currentRace.countdown - 1
    end
    if currentRace.leftReady and currentRace.rightReady and currentRace.activated == nil then
        BonDragRace.racelog[BonDragRace.currentRace].activated = true
        BonDragRace.racelog[BonDragRace.currentRace].countdown = 25
        BonDragRaceAmberLights(true)
    end
end

function onInit()
    MP.RegisterEvent("onTimer", "handleTimer")
    MP.CreateEventTimer("onTimer", 250)
    MP.RegisterEvent("onBonDragRaceTrigger", "handleOnBonDragRaceTrigger")
    MP.RegisterEvent("onConsoleInput", "handleConsoleInput")
    MP.RegisterEvent("onChatMessage", "MyChatMessageHandler")
end