-- Test Concussion.lua
-- Rick's MLC Concussion

require "ISBaseObject"
--require "RicksMLC_Timer"
require "RicksMLC_Concussion"
require "RicksMLC_TestHarness"
local iTest = nil

--------------------------------------------------------------------
-- Overloads:

-- Overload the random so a fixed value can be returned for test cases
local origRandom = RicksMLC_Concussion.Random
local fixedRandom = -1
function RicksMLC_Concussion.Random(min, max)
    if fixedRandom == -1 then return origRandom(min, max) end
    return fixedRandom
end

-- end Overloads

----------------------------------------------------------------
local MockWielder = ISBaseObject:derive("MockWielder");
function MockWielder:new()
    local o = {} 
    setmetatable(o, self)

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
function MockPlayer:getPerkLevel(perkType) return self.realPlayer:getPerkLevel(perkType) end
function MockPlayer:isInvincible() return self.realPlayer:isInvincible() end
function MockPlayer:isGodMod() return self.realPlayer:isGodMod() end

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

-- Overloadable getPlayer() so the mock player can sub in for the real player during test runs.
function Concussion_Test.getPlayer()
    return iTest.mockPlayer
end

function Concussion_Test:new()
    local o = {}
    setmetatable(o, self)

    o.mockPlayer = nil
    o.isReady = false

    o.wielder = nil
    o.concussionInstance = nil

    o.origGetPlayerFn = RicksMLC_Concussion.getPlayer

    o.timer = nil
    o.numRunIntoWallCases = 0
    o.testRunIntoWallResult = {}
    o.numRunIntoWallCallbacks = 0

    --o.resultsWindow = nil
    o.testResults = {}

    o.testSuiteId = 0

    return o
end

---------------------------------------------
-- Overloads for TestRunIntoWall and Trip
local overrideEffectTime = -1
local origBaseWallEffectTimeFn = RicksMLC_Concussion.GetBaseWallEffectTime
function RicksMLC_Concussion.GetBaseWallEffectTime(time)
    if overrideEffectTime == -1 then return origBaseWallSetEffectTimeFn(time) end
    return overrideEffectTime    
end

local origBaseTripEffectTimeFn = RicksMLC_Concussion.GetBaseTripEffectTime
function RicksMLC_Concussion.GetBaseTripEffectTime(time)
    if overrideEffectTime == -1 then return origBaseTripEffectTimeFn(time) end
    return overrideEffectTime
end
---------------------------------------------

function Concussion_Test:AddTestResult(result)
    -- FIXME: the self.testResults may be redundant:
    self.testResults[#self.testResults+1] = result
    RicksMLC_TestHarness.Instance():AddTestResult(result)
end

function Concussion_Test:GetTestResults()
    return self.testResults
end

function Concussion_Test:GetName()
    return "Rick's MLC Concussion Mod: Concussion Tests"
end

function Concussion_Test:TestRunIntoWall(testId, isPlayer, newState, oldState, tripProb, isExpectConcussion)
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
    fixedRandom = tripProb
    local rnd = RicksMLC_Concussion.Random(0, 100)
    DebugLog.log(DebugType.Mod, "Concussion_Test:TestRunIntoWall()   rnd: " .. tostring(rnd))

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
    fixedRandom = -1 -- reset the Random() to be random again

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
    -- Fixme: Remove
    --iTest.testResults[#iTest.testResults+1] = "Case " .. tostring(testId) .. ": " ..iTest.testRunIntoWallResult[testId][1] .. ", " .. iTest.testRunIntoWallResult[testId][2] .. ", " ..iTest.testRunIntoWallResult[testId][3]
    iTest:AddTestResult("Case " .. tostring(testId) .. ": " ..iTest.testRunIntoWallResult[testId][1] .. ", " .. iTest.testRunIntoWallResult[testId][2] .. ", " ..iTest.testRunIntoWallResult[testId][3])
    iTest.numRunIntoWallCallbacks = iTest.numRunIntoWallCallbacks + 1
    if iTest.numRunIntoWallCallbacks < iTest.numRunIntoWallCases then
        iTest:RunNextCase(iTest.numRunIntoWallCallbacks + 1)
    else
        DebugLog.log(DebugType.Mod, "Concussion_Test.TestRunIntoWallCheckTimer(): Call FinishRunIntoWallCases()")
        iTest:FinishRunIntoWallCases()
    end
end

function Concussion_Test:FinishRunIntoWallCases()
    iTest:AddTestResult("Run Into Wall Tests: complete.")
    iTest:EndTest()
end

local runIntoWallCases = {
--  id, isPlayer, newState,        oldState               rand isExpectConcussion
    {1, false, "PlayerGetUpState", "CollideWithWallState",  0, false}, -- Rand is ignored for collide with wall
    {2, true,  "PlayerGetUpState", "CollideWithWallState",  0, true},
    {3, true,  "SomeWrongState  ", "CollideWithWallState",  0, false},
    {4, true,  "PlayerGetUpState", "SomeOtherWrongState",   0, false},
    {5, true,  "PlayerGetUpState", "BumpedState",          10, true},  -- default is 10%, so Rand needs to be <= 10
    {6, true,  "PlayerGetUpState", "BumpedState",          11, false} -- No trip as rand is > 10
}

function Concussion_Test:RunNextCase(caseId)
    testCase = runIntoWallCases[caseId]
    iTest.mockPlayer.lastThought = "" -- Clear your head of the previous tests
    self:TestRunIntoWall(testCase[1], testCase[2], testCase[3], testCase[4], testCase[5], testCase[6])
end

function Concussion_Test:TestRunIntoWallCases()
    -- Run the test run into wall cases.
    -- waiting for the callback on each case?
    iTest.testRunIntoWallResult = {}
    iTest.numRunIntoWallCallbacks = 0
    iTest.numRunIntoWallCases = #runIntoWallCases
    iTest:AddTestResult("Run Into Wall Tests: " .. tostring(iTest.numRunIntoWallCases))
    iTest:RunNextCase(1)
end

function Concussion_Test:newInventoryItem(type)
	local item = nil
    if type ~= nil then 
        item = instanceItem(type)
    end
	return item
end

local testPVPCases = {
    --  id, primary item,      bluntLvl, smallBluntLvl, strength, "random", expectedConcussion
        {1, "base.Hammer",     3,        2,             5,        4,         6 }, -- Concussed 6 seconds
        {2, "base.Hammer",     3,        2,             5,        4a,        -1 }, -- Not concussed random says no
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
    return RicksMLC_WASDController.origForward ~= getCore():getKey("Forward")
        and RicksMLC_WASDController.origBackward ~= getCore():getKey("Backward")
        and RicksMLC_WASDController.origLeft ~= getCore():getKey("Left")
        and RicksMLC_WASDController.origRight ~= getCore():getKey("Right")
end

function Concussion_Test:areAnyKeysChanged() 
    return RicksMLC_WASDController.origForward ~= getCore():getKey("Forward")
        or RicksMLC_WASDController.origBackward ~= getCore():getKey("Backward")
        or RicksMLC_WASDController.origLeft ~= getCore():getKey("Left")
        or RicksMLC_WASDController.origRight ~= getCore():getKey("Right")
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
    self:AddTestResult("TestPVPCases(): " .. tostring(#testPVPCases))
    for i, testCase in ipairs(testPVPCases) do 
        self:AddTestResult(self:TestPVPCase(testCase[1], testCase[2], testCase[3], testCase[4], testCase[5], testCase[6], testCase[7]))
        -- reset the RicksMLC_ConcussionInstance state to prepare for the next test
        self:ResetForNextTestCase()
    end
    self:AddTestResult("TestPVPCases(): complete.")
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
    -- The following test rely on a timer, so run it last
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

    self.mockPlayer = MockPlayer:new(getPlayer())
    self.wielder = MockWielder:new()

    self.origGetPlayerFn = RicksMLC_Concussion.getPlayer
    RicksMLC_Concussion.getPlayer = Concussion_Test.getPlayer

    -- Create the object instances to test, if any
    self.concussionInstance = RicksMLC_Concussion:Instance()

    self.isReady = true
end

function Concussion_Test:Teardown()
    DebugLog.log(DebugType.Mod, "Concussion_Test:Teardown()")
    RicksMLC_Concussion.getPlayer = self.origGetPlayerFn
    self.isReady = false
end

----------------------------------------------------------------
-- Static --

function Concussion_Test.IsTestSave()
    local saveInfo = getSaveInfo(getWorld():getWorld())
    DebugLog.log(DebugType.Mod, "Concussion_Test.OnLoad() '" .. saveInfo.saveName .. "'")
	return saveInfo.saveName and saveInfo.saveName:find("RicksMLC_Test") ~= nil
end


function Concussion_Test:EndTest()
    -- Callback to the harness to let it know we are finished
    RicksMLC_TestHarness.Instance():EndTest(self.testSuiteId)
    -- FIXME: Remove once the Test_Harness is working
    -- DebugLog.log(DebugType.Mod, "Concussion_Test.EndTest() - setting iTest to nil")
    -- if iTest then
    --     iTest:Teardown()
    --     iTest = nil
    -- end
end

function Concussion_Test.OnLoad()
    -- Check the loaded save is a test save?
    DebugLog.log(DebugType.Mod, "Concussion_Test.OnLoad()")
	if Concussion_Test.IsTestSave() then
        DebugLog.log(DebugType.Mod, "  - Test File Loaded")
    end
end

function Concussion_Test.OnGameStart()
    DebugLog.log(DebugType.Mod, "Concussion_Test.OnGameStart()")

    if iTest then 
        DebugLog.log(DebugType.Mod, "Concussion_Test.OnGameStart(): test already running - abort")
        return 
    end

    iTest = Concussion_Test:new()
    iTest.testSuiteId = RicksMLC_TestHarness.Instance():Register(iTest)

end

Events.OnGameStart.Add(Concussion_Test.OnGameStart)
Events.OnLoad.Add(Concussion_Test.OnLoad)
