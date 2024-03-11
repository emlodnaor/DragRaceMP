---------------------
-- DragRace Server --
-- Beams of Norway --
---------------------
BonDragRace = {}
BonDragRace.racelog = {}
BonDragRace.currentRace = 1 
BonDragRace.lights = {}

local metric = true -- change this to get km\h, or mph
local timerPostMovement = 3 --this waits x sec after any movement(trigger activation) before activating the race (amber lights) so that both players have a change to line up properly...
local timerAmberPeriod = 0.4 --how long the amberLights stay on
local timerGreenOff = 3 --This turnes the green lights off x seconds after the race has started

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

local function getSpeed(velocityLen)
    local conversionFactor = metric and 3.6 or 2.2369362920544
    local result = velocityLen * conversionFactor
    return tonumber(string.format("%.2f", result))
end

function handleOnBonDragRaceTrigger(sender_id, data) --hadels clients activating triggers
    --debugPrint()
    if data == "" then
        print(sender_id..": No data recived...")
    end
    
    local theData = Util.JsonDecode(data)
    local velocityLen = theData.velocityLen
    local triggerInfo = theData.triggerInfo
    local triggerEvent = triggerInfo.event
    local entered = triggerEvent == "enter"
    local subjectId = triggerInfo.subjectID
    local mpUserId = MP.GetPlayerIdentifiers(sender_id).beammp
    local identifyer = mpUserId.."-"..subjectId
    local triggerName = triggerInfo.triggerName
    local clientClock = theData.osclockhp
    local currentRace = BonDragRace.racelog[BonDragRace.currentRace]
    --debugPrint(theData)
    

    if triggerName == "prestageTrigL" then
        BonDragRaceControllLights("lightPreStageL", entered)
        if entered then createNewRaceIfNeeded() end
        local currentRace = BonDragRace.racelog[BonDragRace.currentRace] --this is needed here since it's nil before it's created
        currentRace.leftPlayer = identifyer
        currentRace.leftPlayerSenderId = sender_id
        if not entered and currentRace.leftReady then
            currentRace.leftReady = false
        end
        if entered and BonDragRace.lights["lightStageL"] then
            currentRace.leftReady = true
        end
    end

    if triggerName == "prestageTrigR" then
        BonDragRaceControllLights("lightPreStageR", entered)
        if entered then createNewRaceIfNeeded() end
        local currentRace = BonDragRace.racelog[BonDragRace.currentRace] --this is needed here since it's nil before it's created
        currentRace.rightPlayer = identifyer
        currentRace.rightPlayerSenderId = sender_id
        if not entered and currentRace.rightReady then
            currentRace.rightReady = false
        end
        if entered and BonDragRace.lights["lightStageR"] then
            currentRace.rightReady = true
        end
    end
    

    if  not BonDragRace.racelog[BonDragRace.currentRace].finished then --logs the clientClock time when activating a trigger
        BonDragRace.racelog[BonDragRace.currentRace].triggerTimes[identifyer.."-"..triggerName.."-"..triggerEvent] = clientClock
        BonDragRace.racelog[BonDragRace.currentRace].triggerSpeeds[identifyer.."-"..triggerName.."-"..triggerEvent] = getSpeed(velocityLen)
    end

    if triggerName == "startTrigL" then
        BonDragRaceControllLights("lightStageL", entered)
        if BonDragRace.lights["lightPreStageL"] then
            currentRace.leftReady = entered
        end
    end
    if triggerName == "startTrigR" then
        BonDragRaceControllLights("lightStageR", entered)
        if BonDragRace.lights["lightPreStageR"] then
            currentRace.rightReady = entered
        end
    end
    if triggerName == "falseStartTrig" then -- handels false starts
        debugPrint(currentRace.activated, currentRace.started)
        if currentRace.activated and not currentRace.started then
            if entered then
                if identifyer == currentRace.leftPlayer then
                    currentRace.falseStartLeft = true
                    currentRace.leftFinished = true --hmm
                    BonDragRaceRedLightsL(true)
                    BonDragRaceFinishARace()
                end
                if identifyer == currentRace.rightPlayer then
                    currentRace.falseStartRight = true
                    currentRace.rightFinished = true --hmm
                    debugPrint()
                    BonDragRaceRedLightsR(true)
                    debugPrint()
                    BonDragRaceFinishARace()
                end
            end
        end
    end
    if triggerName == "timeSlipBoothL" or triggerName == "timeSlipBoothR" then
        if entered then
            sendRaceLog(identifyer, sender_id)
        end
    end

    if triggerName == "finishTrig" and BonDragRace.racelog[BonDragRace.currentRace].started then            
        if identifyer == currentRace.leftPlayer then currentRace.leftFinished = true end
        if identifyer == currentRace.rightPlayer then currentRace.rightFinished = true end
        BonDragRaceFinishARace()
    end

    BonDragRace.racelog[BonDragRace.currentRace].lastTriggerTime = os.clock()
end


function sendRaceLog(identifyer, sender_id)
    for i = #BonDragRace.racelog, 1, -1 do
        if (BonDragRace.racelog[i].leftPlayer == identifyer or BonDragRace.racelog[i].rightPlayer == identifyer) and Finished(i) then
            local currentRace = BonDragRace.racelog[i]

            local leftPrestageTime = "\u{2003}\u{2003}"
            local leftTime60 = "\u{2003}\u{2003}"
            local leftTime330 = "\u{2003}\u{2003}"
            local leftTime18 = "\u{2003}\u{2003}"
            local leftTime1000 = "\u{2003}\u{2003}"
            local leftTimeFinish ="\u{2003}\u{2003}"
            local leftSpeed = "\u{2003}\u{2003}"
            local leftStartSignalTime = "\u{2003}\u{2003}"
            local leftReaction = "\u{2003}\u{2003}"

            if BonDragRace.racelog[i].leftPlayer ~= nil then
                leftPrestageTime = string.format("%.3f",currentRace.triggerTimes[BonDragRace.racelog[i].leftPlayer.."-prestageTrigL-exit"])
                leftTime60 = string.format("%.3f",currentRace.triggerTimes[BonDragRace.racelog[i].leftPlayer.."-sixtyTrig-enter"] - leftPrestageTime)
                leftTime330 = string.format("%.3f",currentRace.triggerTimes[BonDragRace.racelog[i].leftPlayer.."-threeThirtyTrig-enter"] - leftPrestageTime)
                leftTime18 = string.format("%.3f",currentRace.triggerTimes[BonDragRace.racelog[i].leftPlayer.."-oneEighthTrig-enter"] - leftPrestageTime)
                leftTime1000 = string.format("%.3f",currentRace.triggerTimes[BonDragRace.racelog[i].leftPlayer.."-thousandTrig-enter"] - leftPrestageTime)
                leftTimeFinish = string.format("%.3f",currentRace.triggerTimes[BonDragRace.racelog[i].leftPlayer.."-finishTrig-enter"] - leftPrestageTime)
                leftSpeed = string.format("%.2f",currentRace.triggerSpeeds[BonDragRace.racelog[i].leftPlayer.."-finishTrig-enter"])
                leftStartSignalTime = string.format("%.3f",currentRace.leftStartTime)
                leftReaction = string.format("%.3f",currentRace.triggerTimes[BonDragRace.racelog[i].leftPlayer.."-prestageTrigL-exit"] - leftStartSignalTime)
            end

            local rightPrestageTime = ""
            local rightTime60 = ""
            local rightTime330 = ""
            local rightTime18 = ""
            local rightTime1000 = ""
            local rightTimeFinish = ""
            local rightSpeed = ""
            local rightStartSignalTime = ""
            local rightReaction = ""

            if BonDragRace.racelog[i].rightPlayer ~= nil then
                rightPrestageTime = string.format("%.3f",currentRace.triggerTimes[BonDragRace.racelog[i].rightPlayer.."-prestageTrigR-exit"])
                rightTime60 = string.format("%.3f",currentRace.triggerTimes[BonDragRace.racelog[i].rightPlayer.."-sixtyTrig-enter"] - rightPrestageTime)
                rightTime330 = string.format("%.3f",currentRace.triggerTimes[BonDragRace.racelog[i].rightPlayer.."-threeThirtyTrig-enter"] - rightPrestageTime)
                rightTime18 = string.format("%.3f",currentRace.triggerTimes[BonDragRace.racelog[i].rightPlayer.."-oneEighthTrig-enter"] - rightPrestageTime)
                rightTime1000 = string.format("%.3f",currentRace.triggerTimes[BonDragRace.racelog[i].rightPlayer.."-thousandTrig-enter"] - rightPrestageTime)
                rightTimeFinish = string.format("%.3f",currentRace.triggerTimes[BonDragRace.racelog[i].rightPlayer.."-finishTrig-enter"] - rightPrestageTime)
                rightSpeed = string.format("%.2f",currentRace.triggerSpeeds[BonDragRace.racelog[i].rightPlayer.."-finishTrig-enter"])
                rightStartSignalTime = string.format("%.3f",currentRace.rightStartTime)
                rightReaction = string.format("%.3f",currentRace.triggerTimes[BonDragRace.racelog[i].rightPlayer.."-prestageTrigR-exit"] - rightStartSignalTime)
            end

            local raceIdString = "===========\u{2003}Race "..i.."\u{2003}==========="
            local lineNameString = "Left Lane:\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}Right Lane:"
            local reactionString = "R/T: "..leftReaction.."\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}R/T: "..rightReaction
            local timeString60 = "60Ft: "..leftTime60.."\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}\u{2002}60Ft: "..rightTime60
            local timeString330 = "330Ft"
            local timeString18 = "1/8: "..leftTime18.."\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}1/8: "..rightTime18
            local timeString1000 = "1000"
            local timeStringFinish = "1/4: "..leftTimeFinish.."\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}1/4: "..rightTimeFinish
            local speedType = metric and "km/h" or "mph"
            local speedString = speedType..": "..leftSpeed.."\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}"..speedType..": "..rightSpeed
            local winnerString = ""
            if BonDragRace.racelog[i].leftPlayer ~= nil and BonDragRace.racelog[i].rightPlayer ~= nil then
                winnerString = "\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}\u{2003}Winner"
                if leftTimeFinish < rightTimeFinish then winnerString = "Winner" end
            end

            if BonDragRace.racelog[i].leftPlayer == identifyer then
                MP.SendChatMessage(sender_id,"Race: "..i.." T:"..string.format("%.3f", leftTime).."sec, S:"..string.format("%.2f", leftSpeed)..speedType..", R: "..string.format("%.3f", leftReaction).."")
            end
            if BonDragRace.racelog[i].rightPlayer == identifyer then
                MP.SendChatMessage(sender_id,"Race: "..i.." T:"..string.format("%.3f", rightTime).."sec, S:"..string.format("%.2f", rightSpeed)..speedType..", R: "..string.format("%.3f", rightReaction).."")
            end

            local message = raceIdString.."\n"..lineNameString.."\n"..reactionString.."\n"..timeString60.."\n"..timeString18.."\n"..timeStringFinish.."\n"..speedString.."\n"..winnerString
            MP.TriggerClientEventJson(sender_id, "onSlipReport", {msg = message, timeOnScreen = 15 })
            break
        end
    end
end
function BonDragRaceFinishARace()
    debugPrint()
    if not Finished() then return end
    if BonDragRace.racelog[BonDragRace.currentRace].finished == true then return end

    DisplayTimesOnBoard(BonDragRace.currentRace)

    debugPrint()
    BonDragRace.racelog[BonDragRace.currentRace].finished = true
    local currentRaceNr = BonDragRace.currentRace
    local lastRaceNr = #BonDragRace.racelog
    debugPrint()
    if lastRaceNr > currentRaceNr then BonDragRace.currentRace = currentRaceNr + 1 end
    debugPrint(lastRaceNr, currentRaceNr, currentRaceNr + 1 )
    BonDragRaceRedLights(false)
end
function DisplayReset()
    local data = {leftDisplay = {hidden = true, time = 0, speed = 0}, rightDisplay = {hidden = true, time = 0, speed = 0} }
    MP.TriggerClientEventJson(-1, "BonDragRaceClientDisplayUpdate", data)
end

function DisplayTimesOnBoard(raceNr)
    local currentRace = BonDragRace.racelog[BonDragRace.currentRace]
    local leftTime = 0
    local leftSpeed = 0
    local rightTime = 0
    local rightSpeed = 0
    local displayLeftHidden = true
    local displayRightHidden = true
    
    if currentRace.leftPlayer ~= nil then
        if currentRace.leftFinished then
            local leftIdentifyer = currentRace.leftPlayer
            local leftPrestageTime = currentRace.triggerTimes[leftIdentifyer.."-prestageTrigL-exit"]
            if leftPrestageTime == nil then
                debugPrint("PreStageError")
                dump(currentRace)
            end
            leftTime = currentRace.triggerTimes[leftIdentifyer.."-finishTrig-enter"] - leftPrestageTime
            leftSpeed = currentRace.triggerSpeeds[leftIdentifyer.."-finishTrig-enter"]
            displayLeftHidden = false
        end
    end

    if currentRace.rightPlayer ~= nil then
        if currentRace.rightFinished then
            local rightIdentifyer = currentRace.rightPlayer
            local rightPrestageTime = currentRace.triggerTimes[rightIdentifyer.."-prestageTrigR-exit"]
            if rightPrestageTime == nil then
                debugPrint("PreStageError")
                dump(currentRace)
            end
            rightTime = currentRace.triggerTimes[rightIdentifyer.."-finishTrig-enter"] - rightPrestageTime
            rightSpeed = currentRace.triggerSpeeds[rightIdentifyer.."-finishTrig-enter"]
            displayRightHidden = false
        end
    end

    debugPrint(leftTime, leftSpeed, rightTime, rightSpeed)
    local data = {leftDisplay = {hidden = displayLeftHidden, time = leftTime, speed = leftSpeed}, rightDisplay = {hidden = displayRightHidden, time = rightTime, speed = rightSpeed} }
    MP.TriggerClientEventJson(-1, "BonDragRaceClientDisplayUpdate", data)

    --BonDragRaceClientDisplayUpdate(data) -- leftDisplay/rightDisplay -> hidden, time, speed
end

function Finished(raceNr)
    raceNr = raceNr or BonDragRace.currentRace
    local currentRace = BonDragRace.racelog[raceNr]
    if currentRace.leftFinished and currentRace.rightFinished then return true end
    if currentRace.leftFinished and currentRace.rightPlayer == nil then return true end
    if currentRace.leftPlayer == nil and currentRace.rightFinished then return true end
    return false
end
function createNewRaceIfNeeded() --checks if we need to create a new race
    debugPrint()
    local raceId = BonDragRace.currentRace
    if BonDragRace.racelog[BonDragRace.currentRace] == nil then
        createNewRace(raceId)
    end

    if BonDragRace.racelog[BonDragRace.currentRace].finished then
        createNewRace(raceId + 1)
    end
end
function createNewRace(raceId) -- initiates a new race
    debugPrint()
    if BonDragRace.racelog[BonDragRace.currentRace] ~= nil then
        if BonDragRace.racelog[BonDragRace.currentRace].finished then
            BonDragRace.currentRace = BonDragRace.currentRace + 1 
        end
    end
    BonDragRace.racelog[raceId] = {}
    BonDragRace.racelog[raceId].triggerTimes = {}
    BonDragRace.racelog[raceId].triggerSpeeds = {}
    BonDragRace.racelog[raceId].createdTime = os.clock()
    BonDragRace.racelog[raceId].started = false
    BonDragRace.racelog[raceId].activated = false
end

function BonDragRaceControllLights(lightName, lightState) --lights controller, keeps track of the state of the lights and turns them on or off
    if BonDragRace.lights[lightName] == lightState then
        return
    end
    BonDragRace.lights[lightName] = lightState
    
    local data = {lightName = lightName, state = lightState }
    MP.TriggerClientEventJson(-1, "BonDragRaceLights", data)
end
function BonDragRaceReset() 
    BonDragRace = {}
    BonDragRace.racelog = {}
    BonDragRace.currentRace = 1  
    BonDragRace.lights = {}
    BonDragRaceAllLights(false)
end
function handleonBonDragRaceWorldReadyState2(sender_id, data)
    for lightName, lightState in pairs(BonDragRace.lights) do
        local data = {lightName = lightName, state = lightState }
        MP.TriggerClientEventJson(-1, "BonDragRaceLights", data)
    end
end
function MyChatMessageHandler(sender_id, sender_name, message)
    debugPrint()
    if startsWith(message,"/reset") then --debugging
        debugPrint("Resetting everything") 
        BonDragRaceReset() 
    end
    if startsWith(message,"/help") then --debugging
        debugPrint(BonDragRace) 
        return 1
    else
        return 0
    end
end
function startRace(raceNr) --starts the race
    debugPrint()
    DisplayReset()
    local currentRace = BonDragRace.racelog[raceNr]
    currentRace.started = true
    currentRace.startTime = os.clock()
    BonDragRaceAmberLights(false)
    if currentRace.leftReady ~= nil and currentRace.falseStartLeft == nil then BonDragRaceGreenLightsL(true) end
    if currentRace.rightReady ~= nil and currentRace.falseStartRight == nil then BonDragRaceGreenLightsR(true) end
    AskClientForTimestamp(raceNr)
end
function AskClientForTimestamp(raceNr)
    local currentRace = BonDragRace.racelog[raceNr]
    local leftPlayerSenderId = currentRace.leftPlayerSenderId
    local rightPlayerSenderId = currentRace.rightPlayerSenderId
    local sendData = {raceNr = raceNr}
    if leftPlayerSenderId ~= nil then
        MP.TriggerClientEventJson(leftPlayerSenderId, "BonDragRaceReportStartTime", sendData)
    end
    if rightPlayerSenderId ~= nil then
        MP.TriggerClientEventJson(rightPlayerSenderId, "BonDragRaceReportStartTime", sendData)
    end
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
    BonDragRaceControllLights("lightRedL", lightState)
end
function BonDragRaceRedLightsR(lightState) 
    BonDragRaceControllLights("lightRedR", lightState)
end

function raceCanStart()
    local currentRace = BonDragRace.racelog[BonDragRace.currentRace]
    
    if currentRace.lastTriggerTime + timerPostMovement > os.clock() then -- gives the players time to get into the prestage, incase the first player enters the stage before they are present... 
        --debugPrint("Too Soon...")
        return false 
    end 
    
    if currentRace.activated then 
        --debugPrint("Already started...")
        return false 
    end
    
    if not currentRace.leftReady and not currentRace.rightReady then --none of the players are ready
        --debugPrint("None of the players are ready...")
        return false 
    end 
    
    if currentRace.leftReady and currentRace.rightReady then --both players are ready
        --debugPrint("both players are ready...")
        return true 
    end 
    
    if currentRace.leftReady and currentRace.rightPlayer == nil then --left player is ready and alone
        --debugPrint("left player is ready, right player not present...")
        return true 
    end 
    
    if currentRace.rightReady and currentRace.leftPlayer == nil then --rightPlayer is ready and alone
        --debugPrint("right player is ready, left player not present...")
        return true 
    end 
    
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
        currentRace.activated = true
        currentRace.timeToStart = os.clock() + timerAmberPeriod
        if currentRace.leftReady ~= nil then BonDragRaceAmberLightsL(true) end
        if currentRace.rightReady ~= nil then BonDragRaceAmberLightsR(true) end
        if currentRace.leftReady == nil then BonDragRaceRedLightsL(true) end
        if currentRace.rightReady == nil then BonDragRaceRedLightsR(true) end
    end

    if currentRace.started and currentRace.startTime + timerGreenOff < os.clock() then 
        -- this should only trigger once
        BonDragRaceGreenLights(false)
    end
end
function handleOnBonDragRaceStartTimeReport(sender_id, data)
    decodedData = Util.JsonDecode(data)

    local currentRace = BonDragRace.racelog[BonDragRace.currentRace]
    local leftPlayerSenderId = currentRace.leftPlayerSenderId
    local rightPlayerSenderId = currentRace.rightPlayerSenderId
    if sender_id == leftPlayerSenderId then
        currentRace.leftStartTime = decodedData.osclockhp
    end
    if sender_id == rightPlayerSenderId then
        currentRace.rightStartTime = decodedData.osclockhp
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
    MP.RegisterEvent("onBonDragRaceStartTimeReport", "handleOnBonDragRaceStartTimeReport")
    MP.RegisterEvent("onBonDragRaceWorldReadyState2", "handleonBonDragRaceWorldReadyState2")
end