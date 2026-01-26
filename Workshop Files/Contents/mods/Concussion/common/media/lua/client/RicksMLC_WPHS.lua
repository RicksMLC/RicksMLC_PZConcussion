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
    
    if getPlayer() then
        local wphsData = getPlayer():getModData()["RicksMLC_WPHS"]
        if wphsData then
            o.isAlreadyHardOfHearing = wphsData["IsAlreadyHardOfHearing"]
            --DebugLog.log(DebugType.Mod, "RicksMLC_WPHS:new(): has wphsData. Already: " .. ((o.isAlreadyHardOfHearing and "true") or "false"))
        else
            o.isAlreadyHardOfHearing = getPlayer():hasTrait(CharacterTrait.HARD_OF_HEARING) --"HardOfHearing")
            getPlayer():getModData()["RicksMLC_WPHS"] = { IsAlreadyHardOfHearing = o.isAlreadyHardOfHearing }
            getPlayer():sync()
            --DebugLog.log(DebugType.Mod, "RicksMLC_WPHS:new(): no wphsData. Already: " .. ((o.isAlreadyHardOfHearing and "true") or "false"))
        end
    else
        --DebugLog.log(DebugType.Mod, "RicksMLC_WPHS:new(): no getPlayer()")
        o.isAlreadyHardOfHearing = false
    end

    return o
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
    if getPlayer():hasTrait(CharacterTrait.HARD_OF_HEARING) then return end

    getPlayer():getCharacterTraits():add(CharacterTrait.HARD_OF_HEARING)
    if isClient() then
        -- Inform the server to add the trait
        sendClientCommand(getPlayer(),"RicksMLC_Concussion", "AddHardOfHearing", {})
    end
end

function RicksMLC_WPHS:RestoreTraits()
    if self.isAlreadyHardOfHearing then return end

    if not getPlayer():hasTrait(CharacterTrait.HARD_OF_HEARING) then return end

    getPlayer():getCharacterTraits():remove(CharacterTrait.HARD_OF_HEARING)
    if isClient() then
        -- Inform the server to add the trait
        sendClientCommand(getPlayer(),"RicksMLC_Concussion", "RemoveHardOfHearing", {})
    end
end

function RicksMLC_WPHS:HandleClothingUpdate()
    if not getPlayer() then return end

    if RicksMLC_WPHSShared.IsWearingHearingProtection(getPlayer()) then
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

    -- Always start a new instance on create player.  This will detect if the player is already hard of hearing.
    local instance = RicksMLC_WPHS.Instance()
    -- Correct the isAlreadyHardOfHearing flag if the player trait does not match
    if instance.isAlreadyHardOfHearing and not player:hasTrait(CharacterTrait.HARD_OF_HEARING) then
        instance.isAlreadyHardOfHearing = false
        getPlayer():getModData()[RicksMLC_EarDamageModKey]["isAlreadyHardOfHearing"] = false
        getPlayer():sync()
    end

    RicksMLC_WPHS.Instance():HandleClothingUpdate()
end

Events.OnClothingUpdated.Add(RicksMLC_WPHS.OnClothingUpdated)
Events.OnCreatePlayer.Add(RicksMLC_WPHS.OnCreatePlayer)
