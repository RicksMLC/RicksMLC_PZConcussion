-- _Test_Harness.lua
-- Rick's MLC Test Harness

require "ISBaseObject"

RicksMLC_TestHarness = ISBaseObject:derive("RicksMLC_TestHarness")

RicksMLC_TestHarnessInstance = nil
function RicksMLC_TestHarness.Instance() 
    return RicksMLC_TestHarnessInstance
end

function RicksMLC_TestHarness:Register(test)
    -- Register the given test
    self.tests[#test+1] = test
    self:AddTestResult("Registering: " .. test:GetName())
    return #test
end

function RicksMLC_TestHarness:AddTestResult(result)
    self.testResults[#self.testResults+1] = result
end

function RicksMLC_TestHarness:GetTestResults()
    return self.testResults
end


function RicksMLC_TestHarness:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.tests = {}
    o.currentTestSuiteId = 0

    o.resultsWindow = nil
    o.testResults = {}

    return o
end

function RicksMLC_TestHarness:ClearTestResults()
    self.testResults = {}
    if self.resultsWindow then
        self.resultsWindow:setObject(self.testResults)
    end
end

function RicksMLC_TestHarness:Init()
    DebugLog.log(DebugType.Mod, "RicksMLC_TestHarness:Init()")

    self:ClearTestResults()
    self:CreateWindow()

end

function RicksMLC_TestHarness:CreateWindow()
    local playerNum = getPlayer():getPlayerNum()

    if self.resultsWindow then
        self.resultsWindow:setObject(self.testResults)
    else
        DebugLog.log(DebugType.Mod, "RicksMLC_TestHarness:CreateWindow()")

        local x = getPlayerScreenLeft(playerNum)
        local y = getPlayerScreenTop(playerNum)
        local w = getPlayerScreenWidth(playerNum)
        local h = getPlayerScreenHeight(playerNum)
        self.resultsWindow = _Test_RicksMLC_UI_Window:new(x + 70, y + 50, getPlayer(), self.testResults)
        self.resultsWindow:initialise()
        self.resultsWindow:addToUIManager()
        _Test_RicksMLC_UI_Window.windows[getPlayer()] = window
        if playerNum == 0 then
            ISLayoutManager.RegisterWindow('RicksMLC_TestHarness', ISCollapsableWindow, self.resultsWindow)
        end
    end

    self.resultsWindow:setVisible(true)
    self.resultsWindow:addToUIManager()
    local joypadData = JoypadState.players[playerNum+1]
    if joypadData then
        joypadData.focus = window
    end
end

----------------------------------------------------------

function RicksMLC_TestHarness:ExecuteTestSuites()
    if not self.tests then 
        DebugLog.log(DebugType.Mod, "RicksMLC_TestHarness:ExecuteTestSuites() ERROR: No tests to execute")
        return
    end
    RicksMLC_TestHarnessInstance:Init()
    self:AddTestResult("RicksMLC_TestHarness: Execute Test Suites:")
    self.currentTestSuiteId = 1
    self:ExecuteCurrentTest()
end

function RicksMLC_TestHarness:ExecuteCurrentTest()
    DebugLog.log(DebugType.Mod, "RicksMLC_TestHarness.Execute() Suite: " .. tostring(self.currentTestSuiteId))

    if self.currentTestSuiteId == 0 then 
        return -- ?
    end

    local test = self.tests[self.currentTestSuiteId]
    self:AddTestResult("Executing: " .. test:GetName())
    test:Init()
    if test.isReady then
        DebugLog.log(DebugType.Mod, "RicksMLC_TestHarness.Execute() " .. test:GetName() .. " isReady")
        test:Run()
        DebugLog.log(DebugType.Mod, "RicksMLC_TestHarness.Execute() " .. test:GetName() .. " run complete")
    end
end
    

function RicksMLC_TestHarness:EndTest(testSuiteId)
    DebugLog.log(DebugType.Mod, "RicksMLC_TestHarness.EndTest() " .. tostring(testSuiteId))
    if self.tests[testSuiteId] then
        self.tests[testSuiteId]:Teardown()
        --iTest = nil
    end
    self.currentTestSuiteId = self.currentTestSuiteId + 1
    if self.currentTestSuiteId == #self.tests + 1 then
        self.currentTestSuiteId = 0 -- end of tests
        self:AddTestResult("RicksMLC_TestHarness: All test suites complete. End.")
    else
        self:ExecuteCurrentTest()
    end
end
    
function RicksMLC_TestHarness.IsTestSave()
    local saveInfo = getSaveInfo(getWorld():getWorld())
	return saveInfo.saveName and saveInfo.saveName:find("RicksMLC_Test") ~= nil
end

function RicksMLC_TestHarness.OnGameBoot()
    DebugLog.log(DebugType.Mod, "RicksMLC_TestHarness.OnGameBoot()")
    if not RicksMLC_TestHarnessInstance then
        RicksMLC_TestHarnessInstance = RicksMLC_TestHarness:new()
    end
end

function RicksMLC_TestHarness.OnLoad()
    -- Check the loaded save is a test save?
    DebugLog.log(DebugType.Mod, "RicksMLC_TestHarness.OnLoad()")
	if RicksMLC_TestHarness.IsTestSave() then
        DebugLog.log(DebugType.Mod, "  - Test File Loaded")
    end

    if not RicksMLC_TestHarnessInstance then
        RicksMLC_TestHarnessInstance = RicksMLC_TestHarness:new()
    end
    RicksMLC_TestHarnessInstance:Init()
end

function RicksMLC_TestHarness.HandleOnKeyPressed(key)
	-- Hard coded to F9 for now
	if key == nil then return end

    if not RicksMLC_TestHarnessInstance then 
        DebugLog.log(DebugType.Mod, "RicksMLC_TestHarness.HandleOnKeyPressed() ERROR: No instance found")
        return
    end

	if key == Keyboard.KEY_F9 and RicksMLC_TestHarness.IsTestSave() then
        DebugLog.log(DebugType.Mod, "RicksMLC_TestHarness.HandleOnKeyPressed() Execute test")
        RicksMLC_TestHarnessInstance:ExecuteTestSuites()
    end
end

Events.OnGameBoot.Add(RicksMLC_TestHarness.OnGameBoot)
Events.OnKeyPressed.Add(RicksMLC_TestHarness.HandleOnKeyPressed)
Events.OnLoad.Add(RicksMLC_TestHarness.OnLoad)
