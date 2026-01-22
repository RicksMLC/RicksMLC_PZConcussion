-- Test Drunk
-- Rick's MLC Concussion

require "ISBaseObject"
require "RicksMLC_Timer"
require "RicksMLC_Concussion"
local iTest = nil

-- TODO: Check for isSitOnGround

local Drunk_Test = ISBaseObject:derive("Drunk_Test")

-- Overloadable getPlayer() so the mock player can sub in for the real player during test runs.
function Drunk_Test.getPlayer()
    return iTest.mockPlayer
end

function Drunk_Test:new()
    local o = {}
    setmetatable(o, self)

    o.mockPlayer = nil
    o.isReady = false

    o.drunkInstance = nil

--    o.origGetPlayerFn = RicksMLC_Concussion.getPlayer

--    o.timer = nil

    o.resultsWindow = nil
    o.testResults = {}

    o.testSuiteId = 1

    return o
end

function Drunk_Test:Run()
    DebugLog.log(DebugType.Mod, "Drunk_Test:Run()")
    if not self.isReady then
        DebugLog.log(DebugType.Mod, "Drunk_Test:Run() not ready")
        return
    end
    DebugLog.log(DebugType.Mod, "Drunk_Test:Run() begin")

    self:ClearTestResults() -- reinit the test results for writing to the test window.
    self:TestPVPCases()
    -- The following test rely on a timer, so run it last
    self:TestRunIntoWallCases()

    DebugLog.log(DebugType.Mod, "Drunk_Test:Run() end")
end

function Drunk_Test:IsTestFinished()
    if self.timer and not self.timer.isTimerOn then
        return true
    end
    return false
end

function Drunk_Test:EndTest()
    -- Callback to the harness to let it know we are finished
    RicksMLC_TestHarness.Instance():EndTest(self.testSuiteId)
    -- FIXME: Remove once the Test_Harness is working
    -- DebugLog.log(DebugType.Mod, "Drunk_Test.EndTest() - setting iTest to nil")
    -- if iTest then
    --     iTest:Teardown()
    --     iTest = nil
    -- end
end

function Drunk_Test:ClearTestResults()
    self.testResults = {}
    if self.resultsWindow then
        self.resultsWindow:setObject(self.testResults)
    end
end

function Drunk_Test:Init()
    DebugLog.log(DebugType.Mod, "Drunk_Test:Init()")

    self.mockPlayer = MockPlayer:new(getPlayer())

    -- Create the object instances to test, if any
    self.drunkInstance = RicksMLC_Drunk:Instance()

    self.isReady = true
end

function Drunk_Test:GetName()
    return "Drunk_Test"
end

function Drunk_Test.OnGameStart()
    DebugLog.log(DebugType.Mod, "Drunk_Test.OnGameStart()")

    if iTest then 
        DebugLog.log(DebugType.Mod, "Drunk_Test.OnGameStart(): test already running - abort")
        return 
    end

    iTest = Drunk_Test:new()
    -- FIXME: Uncomment once the Test_Harness is working
    -- iTest.testSuiteId = RicksMLC_TestHarness.Instance():Register(iTest)

end

Events.OnGameStart.Add(Drunk_Test.OnGameStart)