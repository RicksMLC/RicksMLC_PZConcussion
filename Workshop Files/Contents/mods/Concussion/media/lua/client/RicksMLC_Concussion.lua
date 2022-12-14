-- Rick's MLC Concussion
-- TODO:
--      [+] Handle concussin trigger: https://pzwiki.net/wiki/Modding:Lua_Events/OnAIStateChange
--      [?] Effects: blurry vision, pain, queasy, head injury, sleepy
--      [+] Disorientation: randomise the WASD keys
--      [-] multiplayer
--
-- Note: https://pzwiki.net/wiki/Category:Lua_Events

require "ISBaseObject"
require "RicksMLC_WASDCtrl"

RicksMLC_Concussion = ISBaseObject:derive("RicksMLC_Concussion");

RicksMLC_ConcussionInstance = nil

function RicksMLC_Concussion:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self

    self.character = nil

    self.isTimerOn = false
    self.elapsedTime = -1
    self.timerEndSeconds = 0

    self.thoughtsOn = true

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
    --player:setHaloNote(thought, r[colourNum], g[colourNum], b[colourNum], 150)
end

function RicksMLC_Concussion:Concuss(character, concussTime)
    --DebugLog.log("RicksMLC_Concussion:Concuss()")
    if concussTime == 0 then return end

    self:SetEffectTime(concussTime)
    self.character = character
    if self.thoughtsOn then
        self:Think(character, getText("IGUI_RicksMLC_Ow"), 3)
    end
    RicksMLC_WASDController:RandomiseWASD()
    self:StartTimer()
end

function RicksMLC_Concussion:EndConcussion()
    self:CancelTimer()
    if self.thoughtsOn then
        self:Think(self.character, getText("IGUI_RicksMLC_Better"), 2)
    end
    RicksMLC_WASDController:RestoreWASD()
end

function RicksMLC_Concussion.GetBaseWallEffectTime()
    return SandboxVars.RicksMLC_Concussion.WallEffectTimeSeconds
end

function RicksMLC_Concussion.GetBaseTripEffectTime()
    return SandboxVars.RicksMLC_Concussion.TripEffectTimeSeconds
end

function RicksMLC_Concussion:HandleOnAIStateChange(character, newState, oldState)
    --DebugLog.log(DebugType.Mod, "RicksMLC_Concussion:HandleOnAIStateChange()")

    if oldState and newState then
        local oldStateName = character:getPreviousStateName()
        local newStateName = character:getCurrentStateName()
        if newStateName ==  "PlayerGetUpState" then
            if oldStateName == "CollideWithWallState" then
                self:Concuss(character, RicksMLC_Concussion.GetBaseWallEffectTime())
            elseif oldStateName == "BumpedState" and not RicksMLC_Drunk.IsDrunk() then
                -- "BumpedState" is when drunk or trip while sprinting.  Ignore drunk trips - they are controlled in RicksMLC_Drunk.
                local chance = RicksMLC_Concussion.Random(1, 100)
                if chance <= SandboxVars.RicksMLC_Concussion.TripChance then
                    self:Concuss(character, RicksMLC_Concussion.GetBaseTripEffectTime())
                end
            end
            --DebugLog.log(DebugType.Mod, "RicksMLC_Concussion:HandleOnAIStateChange(): '" .. oldStateName .. "'")
        end
    end
end

-- Wrap the ZombRand so it can be overridden in the test 
function RicksMLC_Concussion.Random(min, max)
    return ZombRand(min, max)
end

-- Wrap the getPlayer() so it can be overridden in the test 
function RicksMLC_Concussion.getPlayer()
    return getPlayer()
end

function RicksMLC_Concussion:HandleOnWeaponHitCharacter(wielder, character, handWeapon, damage)
    -- Multiplayer PVP effect: Concuss the character based on the wielder perk level of the weapon
    -- Probability of concussion is proportional to perkLevel + 2. ie lvl 0 is 20%
    -- Duration of concussion is strength level + 1
    
    --DebugLog.log(DebugType.Mod, "RicksMLC_Concussion:HandleOnWeaponHitCharacter()")

    if not handWeapon then return end

    -- Probability to have concussion
    -- Add factor 2 to perkLevel to give better probability.  This means lvl >= 8 is 100%
    local perkLevel = 0
    if handWeapon:getCategories():contains("Blunt") then
        perkLevel = wielder:getPerkLevel(Perks.Blunt);
    elseif handWeapon:getCategories():contains("SmallBlunt") then
        perkLevel = wielder:getPerkLevel(Perks.SmallBlunt);
    end
    local chance = RicksMLC_Concussion.Random(1,10)
    local minFactor = 2
    if chance > perkLevel + minFactor then return end

    -- The number of seconds for the concussion is 1 to 11, depending on the strength level
    local strengthLevel = wielder:getPerkLevel(Perks.Strength)
    self:Concuss(character, strengthLevel + 1)
end

function RicksMLC_Concussion.OnAIStateChange(character, newState, oldState)
    -- Make sure this event is for the player, otherwise on multiplayer everyone gets concussed
    if character ~= RicksMLC_Concussion.getPlayer() or isServer() then return end

    if RicksMLC_ConcussionInstance then
        RicksMLC_ConcussionInstance:HandleOnAIStateChange(character, newState, oldState)
    end
end

-- Event OnWeaponHitCharacter
-- PVP only.  Don't concuss:
--      if the wielder is the player (can't concuss yourself with weapons), or
--      it the character is not the player or this is a server.
function RicksMLC_Concussion.OnWeaponHitCharacter(wielder, character, handWeapon, damage)
    if wielder == RicksMLC_Concussion.getPlayer() then return end
    if character ~= RicksMLC_Concussion.getPlayer() or isServer() then return end

    if RicksMLC_ConcussionInstance then
        RicksMLC_ConcussionInstance:HandleOnWeaponHitCharacter(wielder, character, handWeapon, damage)
    else
        DebugLog.log(DebugType.Mod, "RicksMLC_Concussion.OnWeaponHitCharacter() - no instance!")
    end
end


function RicksMLC_Concussion.OnGameStart()
    --DebugLog.log(DebugType.Mod, "RicksMLC_Concussion.GameStart()")
    -- Concussion only makese sense on the player client/single player.
    -- Return if this is a dedicated server.
    if isServer() and not isClient() then return end

    -- Single player isClient == false
    -- Multiplayer isClient == true
    if not isClient() then 
        Events.OnWeaponHitCharacter.Add(RicksMLC_Concussion.OnWeaponHitCharacter)
    end

    RicksMLC_ConcussionInstance = RicksMLC_Concussion:new()
    RicksMLC_ConcussionInstance:SetEffectTime(SandboxVars.RicksMLC_Concussion.EffectTimeSeconds)
    if SandboxVars.RicksMLC_Concussion.ThoughtsOn then
        RicksMLC_ConcussionInstance:SetThoughtsOn()
    else
        RicksMLC_ConcussionInstance:SetThoughtsOff()
    end
end

function RicksMLC_Concussion:HandleUpdateTimer()
	self.elapsedTime = self.elapsedTime + GameTime.getInstance():getRealworldSecondsSinceLastUpdate()

	if self.elapsedTime >= self.timerEndSeconds then
        self:EndConcussion()
	end
end

function RicksMLC_Concussion:CancelTimer()
    Events.OnTick.Remove(RicksMLC_Concussion.UpdateTimer)
    self.isTimerOn = false
    self:SetEffectTime(0)
end

function RicksMLC_Concussion:StartTimer()
	if (not self.isTimerOn) then
		self.isTimerOn = true
		self.elapsedTime = 0
		Events.OnTick.Add(RicksMLC_Concussion.UpdateTimer)
	end
end

function RicksMLC_Concussion.UpdateTimer()
	if (RicksMLC_ConcussionInstance) then
		RicksMLC_ConcussionInstance:HandleUpdateTimer()
	end
end

Events.OnGameStart.Add(RicksMLC_Concussion.OnGameStart)
Events.OnAIStateChange.Add(RicksMLC_Concussion.OnAIStateChange)
