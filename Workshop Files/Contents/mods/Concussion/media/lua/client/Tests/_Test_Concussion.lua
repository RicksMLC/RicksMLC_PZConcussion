-- Test Concussion.lua
-- Rick's MLC Concussion

require "ISBaseObject"

local iTest = nil

----------------------------------------------------------------
local MockWielder = ISBaseObject:derive("MockWielder");
function MockWielder:new()
    local o = {} 
    setmetatable(o, self)
    self.__index = self

    o.bluntPerkLevel = 0
    o.smallBluntPerkLevel = 0
    o.strengthPerkLevel = 0

    return o
end

function MockWielder:getPerkLevel(perkType) 
    if perkType == Perks.Blunt then
        return self.bluntPerkLevel
    elseif perkType == Perks.SmallBlunt then
        return self.smallBluntPerkLevel
    elseif perkType == Perks.Strength then
        return self.strengthPerkLevel
    end
    return 0
end

-------------------------------------------------------------------------------
local MockPlayer = ISBaseObject:derive("MockPlayer");
function MockPlayer:new(player)
    local o = {} 
    setmetatable(o, self)
    self.__index = self

    o.realPlayer = player
    o.lastThought = nil

    o.prevStateName = nil
    o.currentStateName = nil

    return o
end

function MockPlayer:Move(direction) self.realPlayer:Move(direction) end
function MockPlayer:getForwardDirection() return self.realPlayer:getForwardDirection() end
function MockPlayer:setForwardDirection(fwdDirVec) self.realPlayer:setForwardDirection(fwdDirVec) end
function MockPlayer:setForceSprint(value) self.realPlayer:setForceSprint(value) end
function MockPlayer:setSprinting(value) self.realPlayer:setSprinting(value) end
function MockPlayer:getPlayerNum() return self.realPlayer:getPlayerNum() end
function MockPlayer:getPerkLevel(perkType) return self.realPlayer:getPerkLevel(perkLevel) end

function MockPlayer:Say(text, r, g, b, font, n, preset)
    self.realPlayer:Say(text, r, g, b, font, n, preset)
    self.lastThought = text
end

function MockPlayer:getPreviousStateName()
    if not self.prevStateName then return self.realPlayer:getPreviousStateName() end
    return self.prevStateName
end

function MockPlayer:getCurrentStateName()
    if not self.currentStateName then return self.realPlayer:getCurrentStateName() end
    return self.currentStateName
end

function MockPlayer:getMoodles() return self.realPlayer:getMoodles() end

function MockPlayer:getBodyDamage() return self.realPlayer:getBodyDamage() end

----------------------------------------------------------------------
local RicksMLC_Timer = ISBaseObject:derive("RicksMLC_Timer");
function RicksMLC_Timer:new(timeoutInSeconds, testInstance, id, isExpectValid)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.isTimerOn = false
    o.elapsedTime = 0

    o.testInstance = testInstance
    o.timerEndSeconds = timeoutInSeconds
    o.id = id
    o.isExpectValid = isExpectValid

    o.endTimerCallback = nil

    return o
end

function RicksMLC_Timer:HandleUpdateTimer()
	self.elapsedTime = self.elapsedTime + GameTime.getInstance():getRealworldSecondsSinceLastUpdate()
    --DebugLog.log(DebugType.Mod, "RicksMLC_Timer:HandleUpdateTimer()")
	if self.elapsedTime >= self.timerEndSeconds then
        self.endTimerCallback(self.testInstance, self.id, self.isExpectValid)
        self:CancelTimer()
        return
	end
end

function RicksMLC_Timer:CancelTimer()
    DebugLog.log(DebugType.Mod, "RicksMLC_Timer:CancelTimer()")
    self.isTimerOn = false
    self.endTimerCallback = nil
	Events.OnTick.Remove(RicksMLC_Timer.UpdateTimer)
end

function RicksMLC_Timer:StartTimer(endTimerCallback)
	if (not self.isTimerOn) then
		self.isTimerOn = true
		self.elapsedTime = 0
        self.endTimerCallback = endTimerCallback
		Events.OnTick.Add(RicksMLC_Timer.UpdateTimer)
		DebugLog.log(DebugType.Mod, "RicksMLC_Timer:StartTimer() added UpdateTimer")
	end
end

function RicksMLC_Timer.UpdateTimer()
	if (iTest and iTest.timer) then
		iTest.timer:HandleUpdateTimer()
	else
		--DebugLog.log(DebugType.Mod, "RicksMLC_EE:UpdateTimer() No instance found")	
	end
end

----------------------------------------------------------------------------------------

local Concussion_Test = ISBaseObject:derive("Concussion_Test")

function Concussion_Test:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.mockPlayer = nil
    o.isReady = false

    o.wielder = nil
    o.concussionInstance = nil

    o.origGetPlayerFn = RicksMLC_Concussion.getPlayer

    o.timer = nil
    o.numRunIntoWallCases = 0
    o.testRunIntoWallResult = {}
    o.numRunIntoWallCallbacks = 0

    o.resultsWindow = nil
    o.testResults = {}
    return o
end

-- TODO: Overload for TestRunIntoWall 
local origSetEffectTimeFn = RicksMLC_Concussion.GetDefaultEffectTime
local overrideEffectTime = -1
function RicksMLC_Concussion.GetDefaultEffectTime(time)
    if overrideEffectTime == -1 then return origSetEffectTimeFn(time) end
    return overrideEffectTime    
end

function Concussion_Test:TestRunIntoWall(testId, isPlayer, newState, oldState, isExpectConcussion)
    DebugLog.log(DebugType.Mod, "Concussion_Test:TestRunIntoWall() begin")

    self.testRunIntoWallResult[testId] = {"started", ""}

    local result = ""
    -- Test Plan:
    --  1. Set the concussion time to a short time (<1 second?)
    --  2. Call the event subscriber method to fake the event.
    --  3. Wait for the concussion time + a tick for the concussion timer to end
    --  4. Record result
    overrideEffectTime = 2
    local character = nil
    if isPlayer then
        character = self.mockPlayer
    end
    self.mockPlayer.prevStateName = oldState
    self.mockPlayer.currentStateName = newState

    RicksMLC_Concussion.OnAIStateChange(character, newState, oldState)

    if isExpectConcussion then
        -- Check concussion state is on
        if self.mockPlayer.lastThought ~= getText("IGUI_RicksMLC_Ow") then
            result = "ERROR: Player last thought was not IGUI_RicksMLC_Ow '" .. (self.mockPlayer.lastThought ~= nil and self.mockPlayer.lastThought or "nil") .. "'"
        end
        if not self:areAllKeysChanged() then
            result = result .. "  Error: Keys not all changed"
        end
    else
        if self.mockPlayer.lastThought == getText("IGUI_RicksMLC_Ow") then
            result = "ERROR: Player last thought was IGUI_RicksMLC_Ow when expecting no concussion"
        end
        if self:areAnyKeysChanged() then
            result = result .. "  Error: Key changed when expecting no concussion"
        end
    end
    if result == "" then
        result = "ok so far"
    end

    local checkTimeout = overrideEffectTime + 0.1
    self.timer = RicksMLC_Timer:new(checkTimeout, iTest, testId, isExpectConcussion)
    DebugLog.log(DebugType.Mod, "Concussion_Test:TestRunIntoWall() timer:Start Timer")

    overrideEffectTime = -1 -- Reset the override so a legitimate call will use the real value
    self.mockPlayer.prevStateName = nil    -- Reset the override state names so the legitimate states are used
    self.mockPlayer.currentStateName = nil

    self.timer:StartTimer(Concussion_Test.TestRunIntoWallCallback)
    
    self.testRunIntoWallResult[testId][2] = result
end

function Concussion_Test.TestRunIntoWallCallback(iTest, testId, isExpectConcussion)
    DebugLog.log(DebugType.Mod, "Concussion_Test.TestRunIntoWallCheckTimer()")
    -- Check concussion state has ended
    local result = ""
    if isExpectConcussion then
        if iTest.mockPlayer.lastThought ~= getText("IGUI_RicksMLC_Better") then
            result = "ERROR: Player last thought was not IGUI_RicksMLC_Better '" .. (iTest.mockPlayer.lastThought ~= nil and iTest.mockPlayer.lastThought or "nil") .. "'"
        end
    else
        if iTest.mockPlayer.lastThought == getText("IGUI_RicksMLC_Better") then
            result = "ERROR: Player last thought was IGUI_RicksMLC_Better ' when no concussion"
        end
    end
    if iTest:areAnyKeysChanged() then
        result = result .. " Error: Keys have not reset to correct values"
    end
    if result == "" then
        result = "ok"
    end

    iTest.testRunIntoWallResult[testId][3] = result
    iTest.testResults[#iTest.testResults+1] = "Case " .. tostring(testId) .. ": " ..iTest.testRunIntoWallResult[testId][1] .. ", " .. iTest.testRunIntoWallResult[testId][2] .. ", " ..iTest.testRunIntoWallResult[testId][3]
    iTest.numRunIntoWallCallbacks = iTest.numRunIntoWallCallbacks + 1
    if iTest.numRunIntoWallCallbacks < iTest.numRunIntoWallCases then
        iTest:RunNextCase(iTest.numRunIntoWallCallbacks + 1)
    else
        DebugLog.log(DebugType.Mod, "Concussion_Test.TestRunIntoWallCheckTimer(): Call EndTest()")
        iTest:FinishRunIntoWallCases()
    end
end

function Concussion_Test:FinishRunIntoWallCases()
    iTest.testResults[#iTest.testResults+1] = "Run Into Wall Tests: complete."
    Concussion_Test.EndTest()
end

local runIntoWallCases = {
--  id, isPlayer, newState,        oldState             , isExpectConcussion
    {1, false, "PlayerGetUpState", "CollideWithWallState", false},
    {2, true,  "PlayerGetUpState", "CollideWithWallState", true},
    {3, true,  "SomeWrongState  ", "CollideWithWallState", false},
    {4, true,  "PlayerGetUpState", "SomeOtherWrongState",  false},
}

function Concussion_Test:RunNextCase(caseId)
    testCase = runIntoWallCases[caseId]
    iTest.mockPlayer.lastThought = "" -- Clear your head of the previous tests
    self:TestRunIntoWall(testCase[1], testCase[2], testCase[3], testCase[4], testCase[5])
end

function Concussion_Test:TestRunIntoWallCases()
    -- Run the test run into wall cases.
    -- waiting for the callback on each case?
    iTest.testResults[#iTest.testResults+1] = "Run Into Wall Tests: begin..."
    iTest.numRunIntoWallCases = #runIntoWallCases
    iTest:RunNextCase(1)
end

function Concussion_Test:newInventoryItem(type)
	local item = nil
    if type ~= nil then 
        item = InventoryItemFactory.CreateItem(type)
    end
	return item
end

-- Overload the random so a fixed value can be returned for test cases
local origRandom = RicksMLC_Concussion.Random
local fixedRandom = -1
function RicksMLC_Concussion.Random(min, max)
    if fixedRandom == -1 then return origRandom(min, max) end
    return fixedRandom
end

-- Overloadable getPlayer() so the mock player can sub in for the real player during test runs.
function Concussion_Test.getPlayer()
    return iTest.mockPlayer
end

local testPVPCases = {
    --  id, primary item,      bluntLvl, smallBluntLvl, strength, "random", expectedConcussion
        {1, "base.Hammer",     3,        2,             5,        4,         6 }, -- Concussed 6 seconds
        {2, "base.Hammer",     3,        2,             5,        5,        -1 }, -- Not concussed random says no
        {3, nil,               0,        1,             5,        9,        -1 }, -- not concussed no blunt weapon
        {4, "base.Crowbar",    3,        1,            10,        5,        11 }, -- concussed 11 seconds
        {5, "base.Crowbar",    0,        0,            10,        1,        11 }, -- not concussed
        {6, "base.Saucepan",   10,       1,             5,        1,         6 }  -- concusssed 6 seconds
    }
function Concussion_Test:TestPVPCase(id, handWeaponType, bluntLvl, smallBluntLvl, strengthLvl, randomNumber, expectedConcussion)
    self.wielder.bluntPerkLevel= bluntLvl
    self.wielder.smallBluntPerkLevel = smallBluntLvl
    self.wielder.strengthPerkLevel = strengthLvl
    local handWeapon = self:newInventoryItem(handWeaponType)
    fixedRandom = randomNumber

    RicksMLC_Concussion.OnWeaponHitCharacter(self.wielder, self.mockPlayer, handWeapon, damage)

    local result = "Case " .. tostring(id) .. ": "
    if expectedConcussion > -1 then
        if not iTest.concussionInstance.isTimerOn then
            return result .. "Error: Expected concussion but isTimerOn == false"
        end
        if not self:areAllKeysChanged() then
            return result .. "Error: Keys not all changed"
        end
        if iTest.concussionInstance:GetEffectTime() ~= expectedConcussion then
            return result .. "Error: concussion effect time (" .. tostring(iTest.concussionInstance:GetEffectTime()) .. ") ~= expectedConcussion (" .. tostring(expectedConcussion) .. ")"
        end
    else
        if iTest.concussionInstance.isTimerOn then
            return result .. "Error: Expected no concussion but isTimerOn == true"
        end
        if iTest.concussionInstance:GetEffectTime() > 0 then
            return result .. "Error: Expected no concussion but effect time > 0"
        end
    end
    return result .. "ok"
end

function Concussion_Test:areAllKeysChanged() 
    return self.concussionInstance.origForward ~= getCore():getKey("Forward")
        and self.concussionInstance.origBackward ~= getCore():getKey("Backward")
        and self.concussionInstance.origLeft ~= getCore():getKey("Left")
        and self.concussionInstance.origRight ~= getCore():getKey("Right")
end

function Concussion_Test:areAnyKeysChanged() 
    return self.concussionInstance.origForward ~= getCore():getKey("Forward")
        or self.concussionInstance.origBackward ~= getCore():getKey("Backward")
        or self.concussionInstance.origLeft ~= getCore():getKey("Left")
        or self.concussionInstance.origRight ~= getCore():getKey("Right")
end


function Concussion_Test:ResetForNextTestCase()
    -- Reset the RicksMLC_ConcussionInstance states so it is clean for the next test
    --      turn the timer off... we are not testing the timer and clearing of concussion in this test case
    --      reset the keys to the original pre-test state
    --      clear the effect time
    -- The EndConcussion() method does all of these things.
    -- Calling RicksMLC_Concussion:EndConcussion() with tests in the on/off sequence therefore also tests this function resets correctly for the next concussion.
    iTest.concussionInstance:EndConcussion()
end

function Concussion_Test:TestPVPCases()
    self.testResults[#self.testResults+1] = "TestPVPCases(): " .. tostring(#testPVPCases)
    for i, testCase in ipairs(testPVPCases) do 
        self.testResults[#self.testResults+1] = self:TestPVPCase(testCase[1], testCase[2], testCase[3], testCase[4], testCase[5], testCase[6], testCase[7])
        -- reset the RicksMLC_ConcussionInstance state to prepare for the next test
        self:ResetForNextTestCase()
    end
    self.testResults[#self.testResults+1] = "TestPVPCases(): complete."
    fixedRandom = -1
end

function Concussion_Test:Run()
    DebugLog.log(DebugType.Mod, "Concussion_Test:Run()")
    if not self.isReady then
        DebugLog.log(DebugType.Mod, "Concussion_Test:Run() not ready")
        return
    end
    DebugLog.log(DebugType.Mod, "Concussion_Test:Run() begin")

    self:ClearTestResults() -- reinit the test results for writing to the test window.
    self:TestPVPCases()
    self:TestRunIntoWallCases()

    DebugLog.log(DebugType.Mod, "Concussion_Test:Run() end")
end

function Concussion_Test:IsTestFinished()
    if self.timer and not self.timer.isTimerOn then
        return true
    end
    return false
end

function Concussion_Test:ClearTestResults()
    self.testResults = {}
    if self.resultsWindow then
        self.resultsWindow:setObject(self.testResults)
    end
end

function Concussion_Test:Init()
    DebugLog.log(DebugType.Mod, "Concussion_Test:Init()")
    -- Create the test instance of the ISRemoveGrass

    self.mockPlayer = MockPlayer:new(getPlayer())
    self.wielder = MockWielder:new()
    self:ClearTestResults()
    self:CreateWindow()

    self.origGetPlayerFn = RicksMLC_Concussion.getPlayer
    RicksMLC_Concussion.getPlayer = Concussion_Test.getPlayer

    -- Create the object instances to test, if any
    self.concussionInstance = RicksMLC_Concussion:Instance()
    --if not self.concussionInstance thenplayer
    --    DebugLog.log(DebugType.Mod, "Concussion_Test:Init(): ERROR self.concussionInstance is nil")
    --    self.testResults[#self.testResults+1] = "Concussion_Test:Init(): ERROR self.concussionInstance is nil"
    --    return
    --end

    self.isReady = true
end

function Concussion_Test:CreateWindow()
    if self.resultsWindow then
        self.resultsWindow:setObject(self.testResults)
    else
        DebugLog.log(DebugType.Mod, "Concussion_Test:CreateWindow()")
        local x = getPlayerScreenLeft(self.mockPlayer:getPlayerNum())
        local y = getPlayerScreenTop(self.mockPlayer:getPlayerNum())
        local w = getPlayerScreenWidth(self.mockPlayer:getPlayerNum())
        local h = getPlayerScreenHeight(self.mockPlayer:getPlayerNum())
        self.resultsWindow = _Test_RicksMLC_UI_Window:new(x + 70, y + 50, self.mockPlayer, self.testResults)
        self.resultsWindow:initialise()
        self.resultsWindow:addToUIManager()
        _Test_RicksMLC_UI_Window.windows[self.mockPlayer] = window
        if self.mockPlayer:getPlayerNum() == 0 then
            ISLayoutManager.RegisterWindow('Concussion_Test', ISCollapsableWindow, self.resultsWindow)
        end
    end

    self.resultsWindow:setVisible(true)
    self.resultsWindow:addToUIManager()
    local joypadData = JoypadState.players[self.mockPlayer:getPlayerNum()+1]
    if joypadData then
        joypadData.focus = window
    end
end

function Concussion_Test:Teardown()
    DebugLog.log(DebugType.Mod, "Concussion_Test:Teardown()")
    RicksMLC_Concussion.getPlayer = self.origGetPlayerFn
    self.isReady = false
end

-- Static --

function Concussion_Test.IsTestSave()
    local saveInfo = getSaveInfo(getWorld():getWorld())
    DebugLog.log(DebugType.Mod, "Concussion_Test.OnLoad() '" .. saveInfo.saveName .. "'")
	return saveInfo.saveName and saveInfo.saveName == "RicksMLC_Concussion_Test"
end

function Concussion_Test.Execute()
    if iTest then 
        DebugLog.log(DebugType.Mod, "Concussion_Test.Execute(): test already running - abort")
        return 
    end

    iTest = Concussion_Test:new()
    iTest:Init()
    if iTest.isReady then 
        DebugLog.log(DebugType.Mod, "Concussion_Test.Execute() isReady")
        iTest:Run()
        DebugLog.log(DebugType.Mod, "Concussion_Test.Execute() Run complete.")
    end
    -- TODO: Call this after the last callbacks have returned
    --Concussion_Test.EndTest()
end

function Concussion_Test.EndTest()
    DebugLog.log(DebugType.Mod, "Concussion_Test.EndTest() - setting iTest to nil")
    if iTest then
        iTest:Teardown()
        iTest = nil
    end
end

function Concussion_Test.OnLoad()
    -- Check the loaded save is a test save?
    DebugLog.log(DebugType.Mod, "Concussion_Test.OnLoad()")
	if Concussion_Test.IsTestSave() then
        DebugLog.log(DebugType.Mod, "  - Test File Loaded")
        --FIXME: This is auto run: Concussion_Test.Execute()
    end
end

function Concussion_Test.OnGameStart()
    DebugLog.log(DebugType.Mod, "Concussion_Test.OnGameStart()")
end

function Concussion_Test.HandleOnKeyPressed(key)
	-- Hard coded to F9 for now
	if key == nil then return end

	if key == Keyboard.KEY_F9 and Concussion_Test.IsTestSave() then
        DebugLog.log(DebugLog.Mod, "Concussion_Test.HandleOnKeyPressed() Execute test")
        Concussion_Test.Execute()
    end
end

Events.OnKeyPressed.Add(Concussion_Test.HandleOnKeyPressed)

Events.OnGameStart.Add(Concussion_Test.OnGameStart)
Events.OnLoad.Add(Concussion_Test.OnLoad)
