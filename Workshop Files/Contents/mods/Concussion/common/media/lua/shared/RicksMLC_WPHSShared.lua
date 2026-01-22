-- RicksMLC_WPHSShared.lua
-- Workplace Health and Safety Shared Functions.
RicksMLC_WPHSShared = RicksMLC_WPHSShared or {}

function RicksMLC_WPHSShared.IsWearingHearingProtection(player)
    local hat = player:getWornItem(ItemBodyLocation.HAT)
    if hat and hat:getType():find("Hat_EarMuff_Protectors") ~= nil then return true end

    return false
end
