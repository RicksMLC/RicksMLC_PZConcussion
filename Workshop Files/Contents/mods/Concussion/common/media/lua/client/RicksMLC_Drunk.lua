-- Drunk.lua
-- TODO:
--  [+] Detect drunk - isEatFoodAction:perform() is called at end of drink - check if item is alcohol or moodle?
--  [+] Detect moving while drunk
--  [+] Stagger (randomise WASD for a short time) when drunk
--      [+] Scale probablity with moodle level
--      [+] Scale stumble time with moodle level
--      [ ] Stagger sideways/backwards 
--          [ ] is strafe stagger possible?
--  [+] Trip when drunk
--      [+] Inebriated (level 2) and running
--      [+] Plastered and Shit-faced (not even running)
--      [-] Adjust trip type based on movement type:
--          [-] Sprinting has a sprinting fall
--          [-] Running has a running fall
--          [-] Walking/standing still has a standing fall backwards
--      [?] Trip in random forward direction
require "ISBaseObject"
require "TimedActions/ISEatFoodAction"

RicksMLC_Drunk = ISBaseObject:derive("RicksMLC_Drunk");


--         1=w  2=g   3=r   4=o  5=blu 6=bla
local r = {1.0, 0.0,  0.75, 0.86, 0.3, 0.3}
local g = {1.0, 0.75, 0.0,  0.65, 0.3, 0.3}
local b = {1.0, 0.0,  0.0,  0.02, 0.7, 0.3}
local fonts = {UIFont.AutoNormLarge, UIFont.AutoNormMedium, UIFont.AutoNormSmall, UIFont.Handwritten}
function RicksMLC_Drunk.Think(player, thought, colourNum)
	-- colourNum 1 = white, 2 = green, 3 = red, 4 = orange, 5 = blue, 6 = black
	player:Say(thought, r[colourNum], g[colourNum], b[colourNum], fonts[2], 1, "radio")
    --player:setHaloNote(thought, r[colourNum], g[colourNum], b[colourNum], 150)
end

local RicksMLC_DrunkHandler = nil

function RicksMLC_Drunk.Instance() return RicksMLC_DrunkHandler end

function RicksMLC_Drunk:new() 
	local o = {}
	setmetatable(o, self)
	self.__index = self

    o.character = nil

    o.baseChanceToStagger = 20 -- lvl1=20%, lvl2=40% lvl3=60% lvl
    o.baseStaggerTimeSeconds = 0.30 -- multiply by the drunk level
    o.baseChanceToTrip = 8 -- percentage

    o.cooldownCounter = 2 -- Cooldown for the every minute listener after the effect is finished.

    o.drunkLevel = 0
    o.chanceToStagger = 0
    o.isStaggerOn = false
    o.staggerTimeSeconds = 0.5
    o.elapsedTime = 0

    o.chanceToTrip = 0

    o.drunkCheckNum = 1
    o.started = false

    return o
end

---------------------------------------
-- Stagger timer handling methods

function RicksMLC_Drunk:HandleOnTick()
    -- turn off stagger if time is up
    self.elapsedTime = self.elapsedTime + GameTime.getInstance():getRealworldSecondsSinceLastUpdate()
    if self.elapsedTime > self.staggerTimeSeconds then
        self:StopStaggerTimer()
    end
end

local ScriptLvl4 = {
    "* ILooooveYoughe *",
    "* I'll taKya allZ on! *",
    "* Garnblnflarg *",
    "* Iz u nd Chat 'n mE! *"
}

local ScriptLvl3 = {
    "* Whoa *",
    "* Shhhh - derez zumbhies *",
    "* Donchu worry *GLARGH* this will fix you *",
    "* Shoopit Zombieh, makin'meloogbad *"
}

function RicksMLC_Drunk:SayDrunkLevel()
    if not SandboxVars.RicksMLC_Drunk.ThoughtsOn then return end

    local thoughtColor = PZMath.roundToInt(ZombRand(1, 6))
    local n = PZMath.roundToInt(RicksMLC_Drunk.Random(1, 4))
    if self.drunkLevel >= 4 then
        RicksMLC_Drunk.Think(getPlayer(), ScriptLvl4[n], thoughtColor)
        return
    end
    if self.drunkLevel >= 3 then
        RicksMLC_Drunk.Think(getPlayer(), ScriptLvl3[n] , thoughtColor)
        return
    end
    if self.drunkLevel >= 2 then
        RicksMLC_Drunk.Think(getPlayer(), "* Burp *", thoughtColor)
        return
    end
    if self.drunkLevel >= 1 then
        RicksMLC_Drunk.Think(getPlayer(), "* Hic *", thoughtColor)
    end
end

function RicksMLC_Drunk:StartStaggerTimer()
    if self.isStaggerOn then return end -- Already staggering
    --DebugLog.log(DebugType.Mod, "RicksMLC_Drunk:StartStaggerTimer()")

    self:SayDrunkLevel()

    self.isStaggerOn = true
    self.elapsedTime = 0
    if self.character:isSeatedInVehicle() then
        DebugLog.log(DebugType.Mod, "RicksMLC_Drunk:StartStaggerTimer() inVehicle")
        RicksMLC_WASDController:SwapLeftRight()
    else
        RicksMLC_WASDController:RandomiseWASD()
    end

    Events.OnTick.Add(RicksMLC_Drunk.OnTick)
end

function RicksMLC_Drunk:TripPlayer()
    --DebugLog.log(DebugType.Mod, "RicksMLC_Drunk:TripPlayer()")
    
    --FIXME: Uncomment to fix the trip when sobered up while sitting
    if self.character:isSitOnGround() then return end -- No tripping if sitting.

    -- BumpTypes: "stagger", "trippingFromSprint",  "left", "right"
    -- BumpFallTypes: "pushedBehind", "pushedFront". "pushedFront" means "fall backwards" ie: pushed from the front.
    if self.character:isSprinting() then
        self.character:setSprinting(true);  -- Set sprint so the fall is more spectacular
        self.character:setBumpType("trippingFromSprint"); 
        self.character:setVariable("BumpFallType", "pushedBehind"); -- "pushedBehind", "pushedFront",
    elseif self.character:isRunning() then
        self.character:setBumpType("trippingFromSprint"); -- "stagger", "trippingFromSprint",  "left", "right"
        self.character:setVariable("BumpFallType", "pushedBehind"); -- "pushedBehind", "pushedFront",
    else
        if RicksMLC_Drunk.Random(0, 1) > 0.5 then
            self.character:setBumpType("left")
        else
            self.character:setBumpType("right")
        end
        self.character:setVariable("BumpFallType", "pushedFront"); -- "pushedBehind", "pushedFront",
    end
	self.character:setVariable("BumpDone", false);
	self.character:setVariable("BumpFall", true);
    -- Falling over while drunk and carrying a loaded firearm may be hazardous to your health.
    RicksMLC_Concussion.Instance():AccidentalDischarge(self.character)
    self:StartCooldown()
end


function RicksMLC_Drunk:StartCooldown()
    if self.drunkLevel > 2 then 
        self.cooldownCounter = 2
    else
        self.cooldownCounter = 3
    end
end

function RicksMLC_Drunk:StopStaggerTimer()
    Events.OnTick.Remove(RicksMLC_Drunk.OnTick)
    --DebugLog.log(DebugType.Mod, "RicksMLC_Drunk:StopStaggerTimer()")
    self.elapsedTime = 0
    self.staggerTimeSeconds = 0
    RicksMLC_WASDController:RestoreWASD()
    self.isStaggerOn = false
    self:StartCooldown()
end

-- Static function for stagger timer - just passes onto the handler instance
function RicksMLC_Drunk.OnTick()
    RicksMLC_DrunkHandler:HandleOnTick()
end

---------------------------------------------------
-- Drunk Level triggers and checks

-- Wrap the ZombRand so it can be overridden in the test 
function RicksMLC_Drunk.Random(min, max)
    return ZombRandFloat(min, max)
end

function RicksMLC_Drunk:GetChanceToStagger()
    return self.baseChanceToStagger * self.drunkLevel
end

function RicksMLC_Drunk:GetStaggerTime()
    if self.character:isSeatedInVehicle() then
        -- change the vehicle control for the Tipsy level time only.
        return self.baseStaggerTimeSeconds
    else
        return self.baseStaggerTimeSeconds * self.drunkLevel
    end
end

function RicksMLC_Drunk:GetChanceToTrip()
    local chance = self.baseChanceToTrip * self.drunkLevel
    if self.character:isRunning() or self.character:isSprinting() then 
        chance = chance * 2
    end
    return chance
end

function RicksMLC_Drunk:HandleEveryOneMinute()
    local drunkMoodleLevel = getPlayer():getMoodles():getMoodleLevel(MoodleType.Drunk)
    --DebugLog.log(DebugType.Mod, "RicksMLC_Drunk:HandleEveryOneMinute() drunkLevel:" .. tostring(self.drunkLevel))

    if getPlayer():isGodMod() then
        self.drunkLevel = 0
        self:StopDrunkHandler()
        return
    end

    -- Wait 2 minutes before turning off, to give the "eat" action time to start the effect
    if drunkMoodleLevel < 1 and self.drunkCheckNum > 2 then
        self.drunkLevel = drunkMoodleLevel
        self:StopDrunkHandler()
        return
    end
    self.drunkCheckNum = self.drunkCheckNum + 1
    if drunkMoodleLevel ~= self.drunkLevel then
        -- More drunk? Reset the stagger percentages and try to stagger every minute?
        self.drunkLevel = drunkMoodleLevel
        self.elapsedTime = 0
    end

    -- If the cooldown counter is on just update and return.
    if self.cooldownCounter > 0 then
        self.cooldownCounter = self.cooldownCounter - 1
        return 
    end

    self.staggerTimeSeconds = self:GetStaggerTime()
    self.chanceToStagger = self:GetChanceToStagger()
    
    local makeStagger = RicksMLC_Drunk.Random(0.0, 100.0)
    if makeStagger < self.chanceToStagger then
        self:StartStaggerTimer()
    end

    -- Tripping: Can't trip in a vehicle, so just return.
    if self.character:isSeatedInVehicle() then return end

    --DebugLog.log(DebugType.Mod, "RicksMLC_Drunk:HandleEveryOneMinute() chanceToTrip:" .. tostring(self.chanceToTrip))
    if (self.drunkLevel >= 2 and (self.character:isRunning() or self.character:isSprinting())) or self.drunkLevel > 3 then
        local makeTrip = RicksMLC_Drunk.Random(0.0, 100.0)
        self.chanceToTrip = self:GetChanceToTrip()
        if makeTrip < self.chanceToTrip then
            self:TripPlayer()
        end
    end
end

function RicksMLC_Drunk:InitDrunkLevelChecks()
    self.drunkCheckNum = 1
    self.drunkLevel = 0
    self.started = true
end

function RicksMLC_Drunk.OnEveryOneMinute()
    RicksMLC_DrunkHandler:HandleEveryOneMinute()
end

function RicksMLC_Drunk.StartDrunkHandler()
    --DebugLog.log(DebugType.Mod, "RicksMLC_Drunk.StartDrunkHandler() drunkCheckNum: " .. tostring(RicksMLC_DrunkHandler.started))

    if RicksMLC_DrunkHandler.started then return end

    RicksMLC_DrunkHandler:InitDrunkLevelChecks()
    Events.EveryOneMinute.Add(RicksMLC_Drunk.OnEveryOneMinute)
end

function RicksMLC_Drunk:StopDrunkHandler()
    --DebugLog.log(DebugType.Mod, "RicksMLC_Drunk.StopDrunkHandler()")
    self:StopStaggerTimer()
    Events.EveryOneMinute.Remove(RicksMLC_Drunk.OnEveryOneMinute)
    self.drunkCheckNum = 0
    self.drunkLevel = drunkMoodleLevel
    self.started = false
    self.chanceToTrip = 0
    self.chanceToStagger = 0
end

function RicksMLC_Drunk.IsDrunk()
    local drunkLvl = getPlayer():getMoodles():getMoodleLevel(MoodleType.Drunk)
    --DebugLog.log(DebugType.Mod, "RicksMLC_Drunk.IsDrunk() drunkLevel:" .. tostring(drunkLvl))
    return drunkLvl >= 1
end

function RicksMLC_Drunk:HandleOnExitVehicle(character)
    -- Drunk and Concussion both can trip on exit - let Concussion handle the case where the player is drunk and concussed.
    if character ~= getPlayer() or not RicksMLC_Drunk.IsDrunk() or RicksMLC_Concussion:Instance():IsConcussed() then return end

    local trip = RicksMLC_Drunk.Random(1, 100)
    self.chanceToTrip = self:GetChanceToTrip()
    if trip < self.chanceToTrip * 2 then
        self:TripPlayer()
    end
end

function RicksMLC_Drunk:SetSandboxVars()
    --DebugLog.log(DebugType.Mod, "RicksMLC_Drunk:SetSandboxVars()")

    self.cooldownCounter = SandboxVars.RicksMLC_Drunk.StaggerCooldown or 3

end

-------------------------------------------------------------------------------
-- Override:

function RicksMLC_Drunk.HandleISActionComplete(self)
    if not SandboxVars.RicksMLC_Drunk.EffectOn or getPlayer():isGodMod() then return end

    -- item:isAlcoholic() returns false for most liquids, so just check if the player is drunk
    local stats = getPlayer():getStats()
    local drunkenness = stats:getDrunkenness()

    if drunkenness > 0 then
        RicksMLC_Drunk.StartDrunkHandler()
    end    
end

local origDrinkFluidActionComplete = ISDrinkFluidAction.complete
function ISDrinkFluidAction:complete()

    --DebugLog.log(DebugType.Mod, "RicksMLC_Drunk  ISDrinkFluidAction:complete")

    origDrinkFluidActionComplete(self)
    RicksMLC_Drunk.HandleISActionComplete(self)
end

-- B42.01 Box wine uses the ISEatFoodAction for some reason
local origISEatFoodActionComplete = ISEatFoodAction.complete
function ISEatFoodAction:complete()

    --DebugLog.log(DebugType.Mod, "RicksMLC_Drunk  ISEatFoodAction:complete")

    origISEatFoodActionComplete(self)
    RicksMLC_Drunk.HandleISActionComplete(self)
end

---------------------------------------------------------------------------------

function RicksMLC_Drunk.OnExitVehicle(character)
    RicksMLC_DrunkHandler:HandleOnExitVehicle(character)
end

function RicksMLC_Drunk.InitPlayer()
    --DebugLog.log(DebugType.Mod, "RicksMLC_Drunk.InitPlayer()")

    if not SandboxVars.RicksMLC_Drunk.EffectOn then return end

    if isServer() and not isClient() then return end -- If this is a dedicated server just return as nothing to do.

    RicksMLC_DrunkHandler = nil

    RicksMLC_DrunkHandler = RicksMLC_Drunk:new()

    RicksMLC_DrunkHandler.character = getPlayer()

    RicksMLC_DrunkHandler:SetSandboxVars()

    RicksMLC_Drunk.StartDrunkHandler()
end

function RicksMLC_Drunk.OnCreatePlayer() 
    --DebugLog.log(DebugType.Mod, "RicksMLC_Drunk.OnCreatePlayer()")
    RicksMLC_Drunk.InitPlayer()
end

function RicksMLC_Drunk.OnGameStart()
    --DebugLog.log(DebugType.Mod, "RicksMLC_Drunk.OnGameStart()")
    RicksMLC_Drunk.InitPlayer()
end

Events.OnGameStart.Add(RicksMLC_Drunk.OnGameStart)
Events.OnCreatePlayer.Add(RicksMLC_Drunk.OnCreatePlayer)
Events.OnExitVehicle.Add(RicksMLC_Drunk.OnExitVehicle)