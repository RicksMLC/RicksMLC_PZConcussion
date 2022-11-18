-- Rick's MLC Concussion
-- TODO:
--      [+] Handle collision: https://pzwiki.net/wiki/Modding:Lua_Events/OnAIStateChange
--      [?] Effects: blurry vision, pain, queasy, head injury, sleepy
--      [+] Disorientation: randomise the WASD keys
--
-- Note: https://pzwiki.net/wiki/Category:Lua_Events

require "ISBaseObject"
require "RicksMLC_SaveState"

RicksMLC_Concussion = ISBaseObject:derive("RicksMLC_Concussion");

RicksMLC_ConcussionInstance = nil

function RicksMLC_Concussion:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self

    self.startTime = -1
	self.isConcussed = false
    self.character = nil

    self.isTimerOn = false
    self.elapsedTime = -1
    self.timerEndSeconds = 10

    self.thoughtsOn = true

    self.origForward = getCore():getKey("Forward")
    self.origBackward = getCore():getKey("Backward")
    self.origLeft = getCore():getKey("Left")
    self.origRight = getCore():getKey("Right")

    return o
end

function RicksMLC_Concussion.Instance()
    return RicksMLC_ConcussionInstance
end

function RicksMLC_Concussion:SetEffectTime(timeInSeconds)
    self.timerEndSeconds = timeInSeconds
end

function RicksMLC_Concussion:GetEffectTime()
    return self.timerEndSeconds
end

function RicksMLC_Concussion:SetThoughtsOn()
    self.thoughtsOn = true
end

function RicksMLC_Concussion:SetThoughtsOff()
    self.thoughtsOn = false
end

local r = {1.0, 0.0,  0.75}
local g = {1.0, 0.75, 0.0}
local b = {1.0, 0.0,  0.0}
local fonts = {UIFont.AutoNormLarge, UIFont.AutoNormMedium, UIFont.AutoNormSmall, UIFont.Handwritten}
function RicksMLC_Concussion:Think(player, thought, colourNum)
	-- colourNum 1 = white, 2 = green, 3 = red
	player:Say(thought, r[colourNum], g[colourNum], b[colourNum], fonts[2], 1, "radio")
end

function RicksMLC_Concussion:RandomiseWASD()
    local keyBinds = {"Forward", "Backward", "Left", "Right"}
    local newBinds = {}
    newBinds[1] = {2,3,4,1}
    newBinds[2] = {3,4,1,2}
    newBinds[3] = {4,1,2,3}
    newBinds[4] = {2,4,1,3}
    local n = ZombRand(4) + 1
    getCore():addKeyBinding(keyBinds[newBinds[n][1]], self.origForward)
    getCore():addKeyBinding(keyBinds[newBinds[n][2]], self.origBackward)
    getCore():addKeyBinding(keyBinds[newBinds[n][3]], self.origLeft)
    getCore():addKeyBinding(keyBinds[newBinds[n][4]], self.origRight)
end

function RicksMLC_Concussion:RestoreWASD()
    getCore():addKeyBinding("Forward", self.origForward)
    getCore():addKeyBinding("Backward", self.origBackward)
    getCore():addKeyBinding("Left", self.origLeft)
    getCore():addKeyBinding("Right", self.origRight)
end

function RicksMLC_Concussion:Concuss(character)
    --DebugLog.log("RicksMLC_Concussion:Concuss()")
    self.character = character
    if self.thoughtsOn then
        self:Think(character, getText("IGUI_RicksMLC_Ow"), 3)
    end
    self:RandomiseWASD()
    self:StartTimer()
end

function RicksMLC_Concussion:EndConcussion()
    self:CancelTimer()
    if self.thoughtsOn then
        self:Think(self.character, getText("IGUI_RicksMLC_Better"), 2)
    end
    self:RestoreWASD()
end

function RicksMLC_Concussion:HandleOnAIStateChange(character, newState, oldState)
    --DebugLog.log(DebugType.Mod, "RicksMLC_Concussion:HandleOnAIStateChange()")

    -- if oldState == CollideWithWallState and newState == PlayerGetUpState
    if oldState and newState then
        oldStateName = character:getPreviousStateName()
        newStateName = character:getCurrentStateName()
        -- DebugLog.log(DebugType.Mod, "RicksMLC_Concussion:HandleOnAIStateChange() '" .. oldStateName .. "', '" .. newStateName .. "'")
        if oldStateName == "CollideWithWallState" and newStateName == "PlayerGetUpState" then
            self:Concuss(character)
        end
    end
end

function RicksMLC_Concussion.OnAIStateChange(character, newState, oldState)
    if RicksMLC_ConcussionInstance then
        RicksMLC_ConcussionInstance:HandleOnAIStateChange(character, newState, oldState)
    end
end

function RicksMLC_Concussion.OnCreatePlayer()
    --DebugLog.log(DebugType.Mod, "RicksMLC_Concussion.OnCreatePlayer()")
    RicksMLC_ConcussionInstance = RicksMLC_Concussion:new()
    RicksMLC_ConcussionInstance:SetEffectTime(SandboxVars.RicksMLC_Concussion.EffectTimeSeconds)
    if SandboxVars.RicksMLC_Concussion.ThoughtsOn then
        RicksMLC_ConcussionInstance:SetThoughtsOn()
    else
        RicksMLC_ConcussionInstance:SetThoughtsOff()
    end
end

Events.OnCreatePlayer.Add(RicksMLC_Concussion.OnCreatePlayer)
Events.OnAIStateChange.Add(RicksMLC_Concussion.OnAIStateChange)


function RicksMLC_Concussion:HandleUpdateTimer()
	self.elapsedTime = self.elapsedTime + GameTime.getInstance():getRealworldSecondsSinceLastUpdate()

	if self.elapsedTime >= self.timerEndSeconds then
        self:EndConcussion()
        self:CancelTimer()
        return
	end
end

function RicksMLC_Concussion:CancelTimer()
    self.isTimerOn = false
	Events.OnTick.Remove(RicksMLC_Concussion.UpdateTimer)
end

function RicksMLC_Concussion:StartTimer()
	if (not self.isTimerOn) then
		self.isTimerOn = true
		self.elapsedTime = 0
		Events.OnTick.Add(RicksMLC_Concussion.UpdateTimer)
		--DebugLog.log(DebugType.Mod, "RicksMLC_EE:HandleLevelUp() added UpdateTimer")
	end
end

function RicksMLC_Concussion.UpdateTimer()
	if (RicksMLC_ConcussionInstance) then
		RicksMLC_ConcussionInstance:HandleUpdateTimer()
	else
		--DebugLog.log(DebugType.Mod, "RicksMLC_EE:UpdateTimer() No instance found")	
	end
end
