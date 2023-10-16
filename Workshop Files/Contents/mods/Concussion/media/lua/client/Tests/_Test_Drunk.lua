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
    self.__index = self

    o.mockPlayer = nil
    o.isReady = false

    o.concussionInstance = nil

--    o.origGetPlayerFn = RicksMLC_Concussion.getPlayer

--    o.timer = nil

    --o.resultsWindow = nil
    o.testResults = {}

    o.testSuiteId = 1

    return o
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
    iTest.testSuiteId = RicksMLC_TestHarness.Instance():Register(iTest)

end

Events.OnGameStart.Add(Concussion_Test.OnGameStart)