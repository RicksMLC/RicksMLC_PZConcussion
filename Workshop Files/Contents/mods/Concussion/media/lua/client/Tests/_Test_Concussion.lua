-- Test Concussion.lua
-- Rick's MLC Concussion

-- [ ] Test the RemoveGrassWithTool mod 
--

require "ISBaseObject"

local MockPlayer = ISBaseObject:derive("MockPlayer");
function MockPlayer:new(player)
    local o = {} 
    setmetatable(o, self)
    self.__index = self

    o.realPlayer = player
    o.lastThought = nil

    return o
end

function MockPlayer:getPlayerNum() return self.realPlayer:getPlayerNum() end

function MockPlayer:getPerkLevel(perkType) return self.realPlayer:getPerkLevel(perkLevel) end

function MockPlayer:getXp() return self.realPlayer:getXp() end

function MockPlayer:getPrimaryHandItem() return self.realPlayer:getPrimaryHandItem() end

function MockPlayer:setPrimaryHandItem(item) self.realPlayer:setPrimaryHandItem(item) end

function MockPlayer:getSecondaryHandItem() return self.realPlayer:getSecondaryHandItem() end

function MockPlayer:setSecondaryHandItem(item) self.realPlayer:setSecondaryHandItem(item) end

function MockPlayer:isTimedActionInstant() return false end

function MockPlayer:getTimedActionTimeModifier() return self.realPlayer:getTimedActionTimeModifier() end

function MockPlayer:Say(text, r, g, b, font, n, preset)
    self.realPlayer:Say(text, r, g, b, font, n, preset)
    self.lastThought = text
    DebugLog.log(DebugType.Mod, "MockPlayer:Say() end: " .. text)
end

function MockPlayer:getMoodles() return self.realPlayer:getMoodles() end

function MockPlayer:getBodyDamage() return self.realPlayer:getBodyDamage() end

----------------------------------------------------------------------

-- Concussion_Test is RemoveGrassWithTool_Test
local Concussion_Test = ISBaseObject:derive("Concussion_Test")
local iTest = nil

function Concussion_Test:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.player = nil
    o.isReady = false
    o.ISRemoveGrassInstance = nil
    o.preTestPrimaryItem = nil
    o.preTestSecondaryItem = nil
    o.resultsWindow = nil
    o.testResults = {}
    return o
end

function Concussion_Test:newInventoryItem(type)
	local item = nil
    if type ~= nil then 
        item = InventoryItemFactory.CreateItem(type)
    end
	return item
end

function Concussion_Test:setPrimaryItem(type)
	local item = self:newInventoryItem(type)
	self.player:setPrimaryHandItem(item)
	return item
end

function Concussion_Test:setSecondaryItem(type)
	local item = self:newInventoryItem(type)
	self.player:setSecondaryHandItem(item)
	return item
end


local function cmpNltO(orig, new) return new < orig end
local function cmpNeqO(orig, new) return orig == new end

local testAdjustMaxTimeCases = {
--  id, primary item,      secondary item,  compare, failmsg if compare fails,               Expected "say" text
    {1, "base.HandScythe", nil,             cmpNltO, "new >= orig. orig: <orig> new: <new>", "Using this Hand Scythe is much faster"},
    {2, nil,               nil,             cmpNeqO, "new ~= orig. orig: <orig> new: <new>", "I wish I had a Hand Scythe"},
    {3, "base.HandScythe", "base.Saucepan", cmpNeqO, "new ~= orig. orig: <orig> new: <new>", "I can't use this Hand Scythe to cut grass unless the other hand is empty"},
    {4, "base.Saucepan",   nil,             cmpNeqO, "new ~= orig. orig: <orig> new: <new>", "This is not a Hand Scythe. It's a Saucepan"}
}
function Concussion_Test:TestAdjustMaxTime(testId, testCase)
    self:setPrimaryItem(testCase[2])
    self:setSecondaryItem(testCase[3])
    local maxTime = 1
    local newMaxTime = self.ISRemoveGrassInstance:adjustMaxTime(maxTime) 
    if testCase[4](maxTime, newMaxTime) then
        if self.player.lastThought == testCase[6] then
            self.testResults[#self.testResults+1] = "[o] Test: "  .. tostring(testId) .. " Passed."
            DebugLog.log(DebugType.Mod, self.testResults[#self.testResults])
        else
            local msg = "[x] Test: "  .. tostring(testId) .. " Failed - Mismatched Say text"
            local expMsg = " <INDENT:10> expected: " .. testCase[6]
            local actMsg = " actual: " .. (self.player.lastThought or "nil")
            self.testResults[#self.testResults+1] = msg .. " <LINE> " .. expMsg .. " <LINE> " .. actMsg
            DebugLog.log(DebugType.Mod, msg)
            DebugLog.log(DebugType.Mod, expMsg)
            DebugLog.log(DebugType.Mod, actMsg)
        end
    else
        local failMsg = string.gsub(testCase[5], "<orig>", tostring(maxTime))
        failMsg = string.gsub(failMsg, "<new>", tostring(newMaxTime))
        self.testResults[#self.testResults+1] = "[x] Test: "  .. tostring(testId) .. " Failed " .. failMsg
        DebugLog.log(DebugType.Mod, self.testResults[#self.testResults])
    end
end

function Concussion_Test:Init()
    DebugLog.log(DebugType.Mod, "Concussion_Test:Init()")
    -- Create the test instance of the ISRemoveGrass

    self.player = MockPlayer:new(getPlayer())
    self.preTestPrimaryItem = self.player:getPrimaryHandItem()
    self.preTestSecondaryItem = self.player:getSecondaryHandItem()

    self:CreateWindow()

    local square = nil
    self.ISRemoveGrassInstance = ISRemoveGrass:new(self.player, square)
    if not self.ISRemoveGrassInstance then
        DebugLog.log(DebugType.Mod, "Concussion_Test:Init(): ERROR self.ISRemoveGrassInstance is nil")
        return
    end
    self.isReady = true
end

function Concussion_Test:CreateWindow()
    if self.resultsWindow then
        self.resultsWindow:setObject(self.testResults)
    else
        DebugLog.log(DebugType.Mod, "Concussion_Test:CreateWindow()")
        local x = getPlayerScreenLeft(self.player:getPlayerNum())
        local y = getPlayerScreenTop(self.player:getPlayerNum())
        local w = getPlayerScreenWidth(self.player:getPlayerNum())
        local h = getPlayerScreenHeight(self.player:getPlayerNum())
        self.resultsWindow = _Test_RicksMLC_UI_Window:new(x + 70, y + 50, self.player, self.testResults)
        self.resultsWindow:initialise()
        self.resultsWindow:addToUIManager()
        _Test_RicksMLC_UI_Window.windows[self.player] = window
        if self.player:getPlayerNum() == 0 then
            ISLayoutManager.RegisterWindow('Concussion_Test', ISCollapsableWindow, self.resultsWindow)
        end
    end

    self.resultsWindow:setVisible(true)
    self.resultsWindow:addToUIManager()
    local joypadData = JoypadState.players[self.player:getPlayerNum()+1]
    if joypadData then
        joypadData.focus = window
    end
end


function Concussion_Test:Run()
    DebugLog.log(DebugType.Mod, "Concussion_Test:Run()")
    if not self.isReady then
        DebugLog.log(DebugType.Mod, "Concussion_Test:Run() not ready")
        return
    end
    DebugLog.log(DebugType.Mod, "Concussion_Test:Run() begin")
    for i = 1, #testAdjustMaxTimeCases do
        self:TestAdjustMaxTime(i, testAdjustMaxTimeCases[i])
    end
    self.resultsWindow:createChildren()

    DebugLog.log(DebugType.Mod, "Concussion_Test:Run() end")
end

function Concussion_Test:Teardown()
    DebugLog.log(DebugType.Mod, "Concussion_Test:Teardown()")
    self.player:setPrimaryHandItem(self.preTestPrimaryItem)
    self.player:setSecondaryHandItem(self.getSecondaryHandItem)
    self.preTestPrimaryItem = nil
    self.preTestSecondaryItem = nil
    self.ISRemoveGrassInstance = nil
    self.isReady = false
end

-- Static --

function Concussion_Test.IsTestSave()
    local saveInfo = getSaveInfo(getWorld():getWorld())
    DebugLog.log(DebugType.Mod, "Concussion_Test.OnLoad() '" .. saveInfo.saveName .. "'")
	return saveInfo.saveName and saveInfo.saveName == "RicksMLC_Concussion_Test"
end

function Concussion_Test.Execute()
    iTest = Concussion_Test:new()
    iTest:Init()
    if iTest.isReady then 
        DebugLog.log(DebugType.Mod, "Concussion_Test.Execute() isReady")
        iTest:Run()
        DebugLog.log(DebugType.Mod, "Concussion_Test.Execute() Run complete.")
    end
    iTest:Teardown()
    iTest = nil
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
