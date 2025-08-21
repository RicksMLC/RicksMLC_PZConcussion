-- RicksMLC_ConcussionModOptions.lua
-- Mod options for the Concussion mod:
--  [+] Enable/Disable ear damage: Set to Off if you are experiencing the Spamming Deafness issue.

RicksMLC_ConcussionModOptions = {
    options = nil,
    earDamageOption = nil
}

function RicksMLC_ConcussionModOptions:init()
    DebugLog.log(DebugType.Mod, "RicksMLC_ConcussionModOptions.init()")
    self.options = PZAPI.ModOptions:create("RicksMLC_ConcussionModOptions", "Rick's MLC Concussion")
    self.earDamageOption = self.options:addTickBox("0", getText("UI_RicksMLCSConcussion_Options_EnableEarDamage"), true, getText("UI_RicksMLCSConcussion_Options_EnableEarDamage_Tooltip"))
end

function RicksMLC_ConcussionModOptions:IsEarDamageOn()
    return self.earDamageOption:getValue()
end

RicksMLC_ConcussionModOptions:init()
