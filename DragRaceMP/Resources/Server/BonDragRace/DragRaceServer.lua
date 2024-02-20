---------------------
-- DragRace Server --
-- Beams of Norway --
---------------------
BonDragRace = {}
BonDragRace.racelog = {}
BonDragRace.currentRace = 0 --this approach needs to change to fully allow next race to prepare before first ends...
BonDragRace.lights = {}

function debugPrint(...)
    local info = debug.getinfo(2, "nSl")
    local source = info.short_src or info.source or "unknown"
    local line = info.currentline or 0
    local funcName = info.name or "unknown function"

    local debugInfo = string.format("[%s:%d - %s] ", source, line, funcName)
    print(debugInfo, ...)
end
function startsWith(str, pattern) 
    return string.match(str, "^" .. pattern) ~= nil
end
function handleOnBonDragRaceTrigger(sender_id, data) --hadels clients activating triggers
    debugPrint()
    if data == "" then
        print(sender_id..": No data recived...")
    end
    
    local theData = Util.JsonDecode(data)
    local triggerInfo = theData.triggerInfo
    local triggerEvent = triggerInfo.event
    local entered = triggerEvent == "enter"
    local subjectId = triggerInfo.subjectID
    local triggerName = triggerInfo.triggerName
    local clientClock = theData.osclockhp
    debugPrint(theData)

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
        BonDragRace.racelog[BonDragRace.currentRace].leftReady = entered
    end
    if triggerName == "startTrigR" then
        BonDragRaceControllLights("lightStageR", entered)
        BonDragRace.racelog[BonDragRace.currentRace].rightReady = entered
    end
    if triggerName == "falseStartTrig" then -- handels false starts
        if BonDragRace.raceActive and not BonDragRace.raceStarted then
            BonDragRaceRedLights(entered) -- detemine L/R by sender_id
        end
    end


    if triggerName == "finishTrig" and BonDragRace.racelog[BonDragRace.currentRace].started then -- finishes the race (need to make this multiplayer aware)
        debugPrint(BonDragRace)    
        BonDragRace.racelog[BonDragRace.currentRace].finished = true
        
    end

    if  BonDragRace.racelog[BonDragRace.currentRace].started then --logs the clientClock time when activating a trigger
        BonDragRace.racelog[BonDragRace.currentRace].triggerTimes[subjectId.."-"..triggerName.."-"..triggerEvent] = clientClock
        
    end
end

function createNewRaceIfNeeded() --checks if we need to create a new race
    debugPrint()
    local raceId = BonDragRace.currentRace
    if BonDragRace.racelog[BonDragRace.currentRace] == nil then
        createNewRace(raceId)
    elseif BonDragRace.racelog[BonDragRace.currentRace].finished then
        createNewRace(raceId + 1)
    end
end
function createNewRace(raceId) -- initiates a new race
    debugPrint()
    BonDragRace.racelog[raceId] = {}
    BonDragRace.racelog[raceId].triggerTimes = {}
    BonDragRace.racelog[raceId].createdTime = os.clock()
end

function BonDragRaceControllLights(lightName, lightState) --lights controller, keeps track of the state of the lights and turns them on or off
    if BonDragRace.lights[lightName] == lightState then
        return
    end
    BonDragRace.lights[lightName] = lightState
    
    local data = {lightName = lightName, state = lightState }
    MP.TriggerClientEventJson(-1, "BonDragRaceLights", data)
    BonDragRace.rightPlayer = sender_id
end

function MyChatMessageHandler(sender_id, sender_name, message)
    debugPrint()
    
    if startsWith(message,"/help") then --debugging
        debugPrint(BonDragRace) 
        return 1
    else
        return 0
    end
end
function startRace(currentRace) --starts the race
    debugPrint()
    local currentRace = BonDragRace.racelog[BonDragRace.currentRace]
    currentRace.started = true
    currentRace.startTime = os.clock()
    BonDragRaceAmberLights(false)
    if currentRace.leftReady ~= nil then BonDragRaceAmberLightsL(true) end
    if currentRace.rightReady ~= nil then BonDragRaceAmberLightsR(true) end
end

function BonDragRaceAllLights(lightState)
    BonDragRaceAmberLights(lightState)
    BonDragRaceGreenLights(lightState)
    BonDragRaceRedLights(lightState)
end
function BonDragRaceAmberLights(lightState) -- turns on or off the amber lights
    BonDragRaceAmberLightsL(lightState)
    BonDragRaceAmberLightsR(lightState)
end
function BonDragRaceAmberLightsL(lightState) -- turns on or off the amber lights
     BonDragRaceControllLights("lightAmberL1", lightState)
     BonDragRaceControllLights("lightAmberL2", lightState)
     BonDragRaceControllLights("lightAmberL3", lightState)
end
function BonDragRaceAmberLightsR(lightState) -- turns on or off the amber lights
     BonDragRaceControllLights("lightAmberR1", lightState)
     BonDragRaceControllLights("lightAmberR2", lightState)
     BonDragRaceControllLights("lightAmberR3", lightState)
end
function BonDragRaceGreenLights(lightState) --turns on or off the green lights
    BonDragRaceGreenLightsL(lightState)
    BonDragRaceGreenLightsR(lightState)
end
function BonDragRaceGreenLightsL(lightState) 
    BonDragRaceControllLights("lightGreenL", lightState)
end
function BonDragRaceGreenLightsR(lightState) 
    BonDragRaceControllLights("lightGreenR", lightState)
end
function BonDragRaceRedLights(lightState) --turns on or off the red lights
    BonDragRaceRedLightsL(lightState)
    BonDragRaceRedLightsR(lightState)
end
function BonDragRaceRedLightsL(lightState) 
    BonDragRaceControllLights("lightGreenL", lightState)
end
function BonDragRaceRedLightsR(lightState) 
    BonDragRaceControllLights("lightGreenR", lightState)
end

function raceCanStart()
    local currentRace = BonDragRace.racelog[BonDragRace.currentRace]
    if currentRace.createdTime + 3 > os.clock() then return false end -- gives the players 3 sec to get into the prestage, incase the first player enters the stage before they are present... 
    if currentRace.activated then return false end
    if not currentRace.leftReady and not currentRace.rightReady then return false end --none of the players are ready
    if currentRace.leftReady and currentRace.rightReady then return true end --both players are ready
    if currentRace.leftReady and currentRace.rightPlayer == nil then return true end --left player is ready and alone
    if currentRace.rightReady and currentRace.leftPlayer == nil then return true end --rightPlayer is ready and alone
    return false --some conditions I didn't think about...

end
function handleTimer()
    if BonDragRace.racelog[BonDragRace.currentRace] == nil then  --bugger off if there is no races to handle
        return 
    end

    local currentRace = BonDragRace.racelog[BonDragRace.currentRace]


    if currentRace.timeToStart ~= nil then
        if not currentRace.started and os.clock() > currentRace.timeToStart then -- start the race
            startRace(BonDragRace.currentRace)
        end
    end

    if raceCanStart() then --activate the race and set the timeToStart
        BonDragRace.racelog[BonDragRace.currentRace].activated = true
        BonDragRace.racelog[BonDragRace.currentRace].timeToStart = os.clock() + 3 -- 3 sec
        debugPrint(currentRace.leftReady, currentRace.rightReady)
        if currentRace.leftReady ~= nil then BonDragRaceAmberLightsL(true) end
        if currentRace.rightReady ~= nil then BonDragRaceAmberLightsR(true) end
    end

    if currentRace.started and currentRace.startTime + 3 < os.clock() then --green lights turned off 3 sec after the race have started
        BonDragRaceGreenLights(false)
    end
end

function onInit()
    MP.CancelEventTimer("onTimer")
    BonDragRaceAllLights(false)
    debugPrint("ONINIT ONINIT ONINIT ONINIT ONINIT")
    MP.RegisterEvent("onTimer", "handleTimer")
    MP.CreateEventTimer("onTimer", 250)
    MP.RegisterEvent("onBonDragRaceTrigger", "handleOnBonDragRaceTrigger")
    MP.RegisterEvent("onConsoleInput", "handleConsoleInput")
    MP.RegisterEvent("onChatMessage", "MyChatMessageHandler")
end