-- 3rd party support for items in other mods.
--Janek 10 minutes ago 
-- Any chance ear protectors from other mods such as brita's armor pack and kattaj1 military pack could be supported? ^^ There are some active earpros, which could negate the deafness effect, while not compromising the hearing as much as the normal ear protectors do.

require "RicksMLC_WPHS"

local overrideIsWearingHearingProtection = RicksMLC_WPHS.IsWearingHearingProtection
function RicksMLC_WPHS.IsWearingHearingProtection(self)
    if overrideIsWearingHearingProtection(self) then return true end



    local hat = getPlayer():getWornItem(ItemBodyLocation.HAT)
    if hat and hat:getType():find("Hat_EarMuff_Protectors") ~= nil then return true end

    -- AuthenticZ compatibility: The Hat_EarMuff_Protectors_AZ are on HeadExtra (or will be when AuthenticZ update is pushed)
    if RicksMLC_WPHS.Instance().isAuthenticZ then
        local headExtra = getPlayer():getWornItem(ItemBodyLocation.HEAD_EXTRA)
        if headExtra and headExtra:getType():find("Hat_EarMuff_Protectors") ~= nil  then return true end

        -- AuthenticZ at 18/02/2023 has incorrect body part "Necklace" - backward compatibility:
        local necklace = getPlayer():getWornItem(ItemBodyLocation.NECKLACE)
        if necklace and necklace:getType():find("Hat_EarMuff_Protectors") ~= nil  then return true end
    end

    -- Compatibility for MufflesEarsSlot
    if getActivatedMods():contains("MufflesEarsSlot") then 
        local ears = getPlayer():getWornItem(ItemBodyLocation.EARS)
        if ears and ears:getType():find("Hat_EarMuff_Protectors") ~= nil then return true end
    end

    return false
end
