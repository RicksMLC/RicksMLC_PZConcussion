-- RicksMLC_WPHS.lua
-- Workplace Health and Safety.
-- Ear Protectors: Set the player to have the Hard of Hearing trait when worn.

require "ISBaseObject"

RicksMLC_WPHS = ISBaseObject:derive("RicksMLC_WPHS")

RicksMLC_WPHSInstance = nil
function RicksMLC_WPHS.Instance() 
    if not RicksMLC_WPHSInstance then
        RicksMLC_WPHSInstance = RicksMLC_WPHS:new()
    end
    return RicksMLC_WPHSInstance
end

function RicksMLC_WPHS:new()
    local o = {}
	setmetatable(o, self)
	self.__index = self
    
    if getPlayer() then
        local wphsData = getPlayer():getModData()["RicksMLC_WPHS"]
        if wphsData then
            o.isAlreadyHardOfHearing = wphsData["IsAlreadyHardOfHearing"]
            --DebugLog.log(DebugType.Mod, "RicksMLC_WPHS:new(): has wphsData. Already: " .. ((o.isAlreadyHardOfHearing and "true") or "false"))
        else
            o.isAlreadyHardOfHearing = getPlayer():HasTrait("HardOfHearing")
            getPlayer():getModData()["RicksMLC_WPHS"] = { IsAlreadyHardOfHearing = o.isAlreadyHardOfHearing }
            --DebugLog.log(DebugType.Mod, "RicksMLC_WPHS:new(): no wphsData. Already: " .. ((o.isAlreadyHardOfHearing and "true") or "false"))
        end
    else
        --DebugLog.log(DebugType.Mod, "RicksMLC_WPHS:new(): no getPlayer()")
        o.isAlreadyHardOfHearing = false
    end

    o.isAuthenticZ = RicksMLC_WPHS.IsAuthenticZ()

    return o
end

function RicksMLC_WPHS.IsAuthenticZ()
    local group = BodyLocations.getGroup("Human")
    return group:getLocation("HeadExtra") ~= nil
end

function RicksMLC_WPHS.IsWearingHearingProtection()
    if not getPlayer() then return false end

    local hat = getPlayer():getWornItem("Hat")
    if hat and hat:getType():find("Hat_EarMuff_Protectors") ~= nil then return true end

    -- AuthenticZ compatibility: The Hat_EarMuff_Protectors_AZ are on HeadExtra (or will be when AuthenticZ update is pushed)
    if RicksMLC_WPHS.Instance().isAuthenticZ then
        local headExtra = getPlayer():getWornItem("HeadExtra")
        if headExtra and headExtra:getType():find("Hat_EarMuff_Protectors") ~= nil  then return true end

        -- AuthenticZ at 18/02/2023 has incorrect body part "Necklace" - backward compatibility:
        local necklace = getPlayer():getWornItem("Necklace")
        if necklace and necklace:getType():find("Hat_EarMuff_Protectors") ~= nil  then return true end
    end

    -- Compatibility for MufflesEarsSlot
    if getActivatedMods():contains("MufflesEarsSlot") then 
        local ears = getPlayer():getWornItem("Ears")
        if ears and ears:getType():find("Hat_EarMuff_Protectors") ~= nil then return true end
    end

    return false
end

function RicksMLC_WPHS.Dump()
    local wornItems = getPlayer():getWornItems()
    for i = 0, wornItems:size()-1 do
        local item = wornItems:get(i):getItem()
        local itemName = item:getName()
        local itemLoc = wornItems:get(i):getLocation()
        DebugLog.log(DebugType.Mod, "  Item: '" .. itemName .. "' on '" .. itemLoc .. "'")
    end
end

function RicksMLC_WPHS:ApplyTraits()
    if getPlayer():HasTrait("HardOfHearing") then return end

    getPlayer():getTraits():add("HardOfHearing")
end

function RicksMLC_WPHS:RestoreTraits()
    if not self.isAlreadyHardOfHearing then
        getPlayer():getTraits():remove("HardOfHearing")
    end
end

function RicksMLC_WPHS:HandleClothingUpdate()
    if self:IsWearingHearingProtection() then
        self:ApplyTraits()
    else
        self:RestoreTraits()
    end
end

function RicksMLC_WPHS.OnClothingUpdated(character)
    if character ~= getPlayer() then return end

    RicksMLC_WPHS.Instance():HandleClothingUpdate()
end

function RicksMLC_WPHS.OnCreatePlayer(playerNum, player)
    if player ~= getPlayer() then return end

    -- Always start a new instance on create player
    RicksMLC_WPHSInstance = nil
    RicksMLC_WPHS.Instance():HandleClothingUpdate()
end

Events.OnClothingUpdated.Add(RicksMLC_WPHS.OnClothingUpdated)
Events.OnCreatePlayer.Add(RicksMLC_WPHS.OnCreatePlayer)
