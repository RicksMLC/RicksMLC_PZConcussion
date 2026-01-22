-- 3rd party support for items in other mods.
--Janek 10 minutes ago 
-- Any chance ear protectors from other mods such as brita's armor pack and kattaj1 military pack could be supported? ^^ There are some active earpros, which could negate the deafness effect, while not compromising the hearing as much as the normal ear protectors do.

require "RicksMLC_WPHSShared"

local function isAuthenticZ()
    -- local group = BodyLocations.getGroup("Human")
    -- return group:getLocation(ItemBodyLocation."HeadExtra") ~= nil
    -- FIXME: fix this when AuthenticZ is updated to B42
    return false
end

local overrideIsWearingHearingProtection = RicksMLC_WPHSShared.IsWearingHearingProtection
function RicksMLC_WPHSShared.IsWearingHearingProtection(player)
    if overrideIsWearingHearingProtection(player) then return true end

    local hat = player:getWornItem(ItemBodyLocation.HAT)
    if hat and hat:getType():find("Hat_EarMuff_Protectors") ~= nil then return true end

    -- AuthenticZ compatibility: The Hat_EarMuff_Protectors_AZ are on HeadExtra (or will be when AuthenticZ update is pushed)
    if isAuthenticZ() then
        local headExtra = player:getWornItem(ItemBodyLocation.HEAD_EXTRA)
        if headExtra and headExtra:getType():find("Hat_EarMuff_Protectors") ~= nil  then return true end

        -- AuthenticZ at 18/02/2023 has incorrect body part "Necklace" - backward compatibility:
        local necklace = player:getWornItem(ItemBodyLocation.NECKLACE)
        if necklace and necklace:getType():find("Hat_EarMuff_Protectors") ~= nil  then return true end
    end

    -- Compatibility for MufflesEarsSlot
    if getActivatedMods():contains("MufflesEarsSlot") then 
        local ears = player:getWornItem(ItemBodyLocation.EARS)
        if ears and ears:getType():find("Hat_EarMuff_Protectors") ~= nil then return true end
    end

    return false
end
