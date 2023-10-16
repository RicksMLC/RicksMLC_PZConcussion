-- Rick's MLC Concussion
-- TODO:
--      [+] Handle concussin trigger: https://pzwiki.net/wiki/Modding:Lua_Events/OnAIStateChange
--      [+] Disorientation: randomise the WASD keys
--      [-] multiplayer
--      [!] Effects: blurry vision, pain, queasy, head injury, sleepy
--
-- Note: https://pzwiki.net/wiki/Category:Lua_Events

require "ISBaseObject"
require "RicksMLC_WASDCtrl"

require "MF_ISMoodle"

local RicksMLC_ConcussionMoodle = "RicksMLC_Concussion"
if MF then
    MF.createMoodle(RicksMLC_ConcussionMoodle)
end

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

function RicksMLC_Concussion:AccidentalDischarge(character)
    if character ~= getPlayer() then return end
    local weapon = character:getPrimaryHandItem()
    if not weapon or not instanceof(weapon, "HandWeapon") or not weapon:isRanged() then return end

    local ad = ZombRand(100)
    local chance = SandboxVars.RicksMLC_Concussion.AccidentalDischargeChance
    if ad > chance then return end

    --ISReloadWeaponAction.attackHook = function(character, chargeDelta, weapon)
    if ISReloadWeaponAction.canShoot(weapon) then
        local radius = weapon:getSoundRadius();
        if isClient() then -- limit sound radius in MP
            radius = radius / 1.8
        end
        character:addWorldSoundUnlessInvisible(radius, weapon:getSoundVolume(), false);
        character:playSound(weapon:getSwingSound());
        character:startMuzzleFlash()
        if weapon:haveChamber() then
            weapon:setRoundChambered(false)
        end

        ISReloadWeaponAction.onShoot(character, weapon) -- Handles the weapon discharge ammunition

        -- Probability to hit:
        --  Base chance is 60% with 20% chance of hitting a zombie
        --  Unlucky is 85% shoot self, with 10% shoot zombie
        --  Lucky is 10% self, with 90% chance of hitting a zombie
        local baseChance = SandboxVars.RicksMLC_Concussion.ShootSelfBaseChance
        local zombieChance = SandboxVars.RicksMLC_Concussion.ShootZombieChance
        if character:HasTrait("Lucky") then
            baseChance = SandboxVars.RicksMLC_Concussion.ShootSelfLuckyChance
            zombieChance = SandboxVars.RicksMLC_Concussion.ShootZombieLuckyChance
        elseif character:HasTrait("Unlucky") then
            baseChance = SandboxVars.RicksMLC_Concussion.ShootSelfUnluckyChance
            zombieChance = SandboxVars.RicksMLC_Concussion.ShootZombieUnluckyChance
        end
        local n = ZombRand(100)
        if n <= baseChance then
            -- Shot yourself
            character:Hit(weapon, character, 0, false, 0)
        else
            local z = ZombRand(100)
            if z <= zombieChance then
                -- Shoot a zombie
                local zombie = getCell():getNearestVisibleZombie(character:getPlayerNum())
                if zombie then
                    local distance = IsoUtils.DistanceToSquared(zombie:getX(), zombie:getY(), zombie:getZ(),
                                                                character:getX(), character:getY(), character:getZ())
                    if distance <= (weapon:getMaxRange() * weapon:getMaxRange()) then
                        zombie:Hit(weapon, character, 0, false, 0)
                        zombie:knockDown(false)
                    end
                end
            end
        end
    else
        character:playSound(weapon:getClickSound())
    end
end

function RicksMLC_Concussion:Concuss(character, concussTime)
    --DebugLog.log("RicksMLC_Concussion:Concuss()")
    if concussTime == 0 then return end

    if SandboxVars.RicksMLC_Concussion.AccidentalDischarge then
        self:AccidentalDischarge(character)
    end

    self:SetEffectTime(concussTime)
    self.character = character
    if self.thoughtsOn then
        self:Think(character, getText("IGUI_RicksMLC_Ow"), 3)
    end
    if MF then
        local moodle = MF.getMoodle(RicksMLC_ConcussionMoodle)
        moodle:setValue(0.4)--float 0.4 is default bad level 1.
    end
    RicksMLC_WASDController:RandomiseWASD()
    self:StartTimer()
end

function RicksMLC_Concussion:EndConcussion()
    self:CancelTimer()
    if self.thoughtsOn then
        self:Think(self.character, getText("IGUI_RicksMLC_Better"), 2)
    end
    if MF then
        local moodle = MF.getMoodle(RicksMLC_ConcussionMoodle)
        moodle:setValue(0.5)--float 0.5 is default neutral.
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

    if character:isGodMod() then return end

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
    if character:isInvincible() then return end

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
    if isClient() then 
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
