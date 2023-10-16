-- RicksMLC_EarDamage.lua
--
-- Inflict the "Deaf" trait for a period of time if the player has made too much noise.
-- https://projectzomboid.com/modding////zombie/characters/IsoPlayer.html
-- https://projectzomboid.com/modding////zombie/Lua/LuaManager.GlobalObject.html#getGameTime()
--
-- TODO:
--      [+] Handle the OnWorldSound() to set a start timer for the sound, and the volume
--      [+] On each shot within a timespan, increase the damage til the threshold is reached.
--      [+] Apply the "Deaf" trait on threshold reached.
--      [+] Detect wearing ear protection to prevent damage
--      [ ] Deaf time increases depending on deaf history - the more often it happens the longer the effect
--      [ ] Permanent hearing loss after so many events?

require "ISBaseObject"
require "MF_ISMoodle"
require "RicksMLC_WPHS"

local RicksMLC_EarDamageMoodle = "RicksMLC_EarDamage"
if MF then
    MF.createMoodle(RicksMLC_EarDamageMoodle)
end

local volumeThreshold = 50
local timespanThresholdSeconds = 3
local deafTriggerVolume = 3000

RicksMLC_EarDamage = ISBaseObject:derive("RicksMLC_EarDamage")

local RicksMLC_EarDamageModKey = "RicksMLC_EarDamage"
--local RicksMLC_EarDamageRecord = "RicksMLC_EarDamageRecord"

local RicksMLC_EarDamageInstance = nil
function RicksMLC_EarDamage.Instance() 
    if not RicksMLC_EarDamageInstance then
        RicksMLC_EarDamageInstance = RicksMLC_EarDamage:new()
    end
    return RicksMLC_EarDamageInstance
end

function RicksMLC_EarDamage:new()
    local o = {}
	setmetatable(o, self)
	self.__index = self

    o.hasKeenHearing = false
    o.isTimerOn = false
    o.elapsedTime = -1
    o.timerEndSeconds = 0

    return o
end

function RicksMLC_EarDamage.CalculateGain(radius, volume, objSource, x, y, z)
    local volumeWithGain = volume

    if objSource == getPlayer() then
        local isOutside = getPlayer():isOutside()
        if not isOutside then
            local playerRoomDef = getPlayer():getCurrentRoomDef()
            if playerRoomDef then
                roomArea = math.min(playerRoomDef:getArea(), math.pi * radius * radius)
                volumeWithGain = volume * math.log(roomArea)
            end
            --RicksMLC_EarDamage.Dump(roomArea, radius, volumeWithGain)
        end
        return volumeWithGain
    end

    if not getPlayer():isOutside() then
        local playerRoomDef = getPlayer():getCurrentRoomDef()
        if playerRoomDef then
            if playerRoomDef:isInside(x, y, z) then
                local distToSquared = getPlayer():DistToSquared(x, y)
                local radiusSquared = radius * radius
                if distToSquared <= radiusSquared then
                    -- greater than 4x4 room increases volume.  smaller decreases
                    roomArea = math.min(playerRoomDef:getArea(), math.pi * radiusSquared)
                    volumeWithGain = volume * math.log(roomArea)
                    --RicksMLC_EarDamage.Dump(roomArea, radius, volumeWithGain)
                end
            end
        end
    end
    return volumeWithGain
end

function RicksMLC_EarDamage.Dump(roomArea, radius, volumeWithGain)
    local currentEarDamage = getPlayer():getModData()[RicksMLC_EarDamageModKey]
    if not currentEarDamage then return end

    DebugLog.log(DebugType.Mod,
        "RicksMLC_EarDamage: Outside? " 
        .. (isOutside and "y" or "n") 
        .. " Area: " .. PZMath.roundToInt(roomArea)
        .. " Rad: " .. PZMath.roundToInt(radius)
        .. " Vol: " .. tostring(PZMath.roundToInt(volumeWithGain))
        .. " Tot: " .. tostring(PZMath.roundToInt(currentEarDamage["totalVolume"] + volumeWithGain))
        .. " Max: " .. tostring(deafTriggerVolume))
end

function RicksMLC_EarDamage.OnWorldSound(x, y, z, radius, volume, objSource) 
    --DebugLog.log(DebugType.Mod, "RicksMLC_EarDamage.OnWorldSound()")
    if getPlayer():isInvincible() or getPlayer():isGodMod() then return end

    if getPlayer():HasTrait("Deaf") then return end

    if not instanceof(objSource, 'IsoPlayer') then return end

    local volumeWithGain = RicksMLC_EarDamage.CalculateGain(radius, volume, objSource, x, y, z)
    if volumeWithGain >= volumeThreshold then

        if RicksMLC_WPHS.IsWearingHearingProtection() then
            --DebugLog.log(DebugType.Mod, "RicksMLC_EarDamage.OnWorldSound(): Ear Protection on = no damage")
            return
        end
    
        local currentEarDamage = getPlayer():getModData()[RicksMLC_EarDamageModKey]
        if not currentEarDamage then
            getPlayer():getModData()[RicksMLC_EarDamageModKey] 
                = { firstTimeStamp = getTimestamp(), totalVolume = volumeWithGain }
            return
        end
        -- If we get this far, we are going deaf
        currentEarDamage["totalVolume"] = currentEarDamage["totalVolume"] + volumeWithGain
        RicksMLC_EarDamage.Instance():HandlePossibleDeafness(currentEarDamage)
    end
end

function RicksMLC_EarDamage.OnEveryOneMinute()

    -- If there is a timer it will take care of things
    if RicksMLC_EarDamage.Instance():IsTimerOn() then
        return
    end

    local currentEarDamage = getPlayer():getModData()[RicksMLC_EarDamageModKey]
    if currentEarDamage then
        local firstTime = currentEarDamage["firstTimeStamp"]
        local curTimeStamp = getTimestamp()
        local timespan = curTimeStamp - firstTime
        if timespan > timespanThresholdSeconds then
            -- Enough time has passed, so reset
            getPlayer():getModData()[RicksMLC_EarDamageModKey] = nil
            RicksMLC_EarDamage.ClearMoodles()
            return
        end
    end
end

function RicksMLC_EarDamage.ClearMoodles()
    --DebugLog.log(DebugType.Mod, "RicksMLC_EarDamage.ClearMoodles()")
    if MF and getPlayer() then
        local moodle = MF.getMoodle(RicksMLC_EarDamageMoodle)
        moodle:setValue(0.5)--float 0.4 is default bad level 1.
        moodle:setChevronCount(0)--unsigned int
    end
end

function RicksMLC_EarDamage:HandlePossibleDeafness(currentEarDamage)
    if not self:StartDeafness(currentEarDamage) then
        self:ShowDeafWarning(currentEarDamage["totalVolume"])
    end
end

function RicksMLC_EarDamage:ShowDeafWarning(experiencedVolume)
    if MF and getPlayer() then
        -- badness: 0.5 > n > 0
        local volRatio = experiencedVolume / deafTriggerVolume
        local badness = 0.5 - (0.5 * (volRatio))

        if badness > 0.4 then return end
        local chevronLevel = PZMath.roundToInt(5 * volRatio)
        local moodle = MF.getMoodle(RicksMLC_EarDamageMoodle)
        moodle:setValue(badness)--float 0.4 is default bad level 1.
        moodle:setChevronCount(chevronLevel)--unsigned int
        moodle:setChevronIsUp(true)--bool
    end
end

function RicksMLC_EarDamage:SetEffectTime(timeInSeconds)
    self.timerEndSeconds = timeInSeconds
end

function RicksMLC_EarDamage:StartDeafness(currentEarDamage)
    --DebugLog.log(DebugType.Mod, "RicksMLC_EarDamage:StartDeafness()")

    if currentEarDamage["totalVolume"] <= deafTriggerVolume then
        return false
    end
    
    Events.OnWorldSound.Remove(RicksMLC_EarDamage.OnWorldSound)

    local deafTime = SandboxVars.RicksMLC_EarDamage.DeafTime

    -- TODO: Make deafness more permanent if it happens too often
    --player:getModData()[RicksMLC_EarDamageRecord]["numDeafEvents"] { numDeafEvents = 0, dateTimeLastEvent = 0 }
    -- player:getModData()[RicksMLC_EarDamageRecord]["numDeafEvents"] 
    --     = player:getModData()[RicksMLC_EarDamageRecord]["numDeafEvents"] + 1

    -- player:getModData()[RicksMLC_EarDamageRecord]["dateTimeLastEvent"] 
    --     = getGameTime():getCalendar():getTime() -- getTime() returns a java dateTime instance
        

    self:SetEffectTime(deafTime)

    self:ApplyDeafTraits()

    if MF and getPlayer() then
        local moodle = MF.getMoodle(RicksMLC_EarDamageMoodle)
        moodle:setValue(0.0)
        moodle:setChevronCount(0)
    end

    self:StartTimer()
    return true
end

function RicksMLC_EarDamage:EndDeafness()
    --DebugLog.log(DebugType.Mod, "RicksMLC_EarDamage:EndDeafness()")
    self:CancelTimer()
    self:RestoreTraits()
    RicksMLC_EarDamage.ClearMoodles()
    Events.OnWorldSound.Add(RicksMLC_EarDamage.OnWorldSound)
end

function RicksMLC_EarDamage:ApplyDeafTraits()
    --DebugLog.log(DebugType.Mod, "RicksMLC_EarDamage:ApplyDeafTraits()")
    if getPlayer():HasTrait("Deaf") then return end

    getPlayer():getTraits():add("Deaf")
end

function RicksMLC_EarDamage:RestoreTraits()
    --DebugLog.log(DebugType.Mod, "RicksMLC_EarDamage:RestoreTraits()")
    getPlayer():getTraits():remove("Deaf")
end

function RicksMLC_EarDamage:IsTimerOn()
    return self.isTimerOn
end

function RicksMLC_EarDamage:HandleUpdateTimer()
	self.elapsedTime = self.elapsedTime + GameTime.getInstance():getRealworldSecondsSinceLastUpdate() -- getGametimeTimestamp()

	if self.elapsedTime >= self.timerEndSeconds then
        self:EndDeafness()
	end
end

function RicksMLC_EarDamage:CancelTimer()
    Events.OnTick.Remove(RicksMLC_EarDamage.UpdateTimer)
    self.isTimerOn = false
    self:SetEffectTime(0)
end

function RicksMLC_EarDamage:StartTimer()
	if (not self.isTimerOn) then
		self.isTimerOn = true
		self.elapsedTime = 0
		Events.OnTick.Add(RicksMLC_EarDamage.UpdateTimer)
	end
end

function RicksMLC_EarDamage.UpdateTimer()
	if (RicksMLC_EarDamageInstance) then
		RicksMLC_EarDamageInstance:HandleUpdateTimer()
	end
end

function RicksMLC_EarDamage.OnCreatePlayer(playerIndex, player)
    --DebugLog.log(DebugType.Mod, "RicksMLC_EarDamage.CreatePlayer()")

    if not SandboxVars.RicksMLC_EarDamage.Enable then return end
    volumeThreshold = SandboxVars.RicksMLC_EarDamage.VolumeThreshold
    timespanThresholdSeconds = SandboxVars.RicksMLC_EarDamage.TimespanThresholdSeconds
    deafTriggerVolume = SandboxVars.RicksMLC_EarDamage.DeafTriggerVolume
    
    if player ~= getPlayer() then return end
    -- FIXME: How to handle multiplayer?

    local instance = RicksMLC_EarDamage.Instance()

    -- local earDamageRecord = player:getModData()[RicksMLC_EarDamageRecord]
    -- if not earDamageRecord then
    --     -- This is a new player
    --     player:getModData()[RicksMLC_EarDamageRecord] = { numDeafEvents = 0, dateTimeLastEvent = 0 }
    -- end

    local currentEarDamage = player:getModData()[RicksMLC_EarDamageModKey]
    if not currentEarDamage and player:HasTrait("Deaf") then
        Events.OnWorldSound.Remove(RicksMLC_EarDamage.OnWorldSound)
        --DebugLog.log(DebugType.Mod, "RicksMLC_EarDamage.CreatePlayer() player is already deaf - do not subscribe to sound events")
        return
    end

    Events.OnWorldSound.Add(RicksMLC_EarDamage.OnWorldSound)
    if currentEarDamage then
        --DebugLog.log(DebugType.Mod, "RicksMLC_EarDamage.CreatePlayer() player has current ear damage")
        instance:RestoreTraits()
        currentEarDamage["firstTimeStamp"] = getTimestamp()
        instance:HandlePossibleDeafness(currentEarDamage)
    end
end

function RicksMLC_EarDamage.OnGameStart()
    Events.EveryOneMinute.Add(RicksMLC_EarDamage.OnEveryOneMinute)
end

function RicksMLC_EarDamage.OnSave()
    --DebugLog.log(DebugType.Mod, "RicksMLC_EarDamage.OnSave()")
    local instance = RicksMLC_EarDamage.Instance()
    if instance:IsTimerOn() then
        instance:RestoreTraits()
    end
end

function RicksMLC_EarDamage.OnPostSave()
    --DebugLog.log(DebugType.Mod, "RicksMLC_EarDamage.OnPostSave()")
    local instance = RicksMLC_EarDamage.Instance()
    if instance:IsTimerOn() then
        instance:ApplyDeafTraits()
    end
end

Events.OnCreatePlayer.Add(RicksMLC_EarDamage.OnCreatePlayer)
Events.OnGameStart.Add(RicksMLC_EarDamage.OnGameStart)
Events.OnSave.Add(RicksMLC_EarDamage.OnSave)
Events.OnPostSave.Add(RicksMLC_EarDamage.OnPostSave)