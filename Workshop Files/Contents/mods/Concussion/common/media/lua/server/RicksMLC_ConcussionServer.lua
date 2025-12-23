-- RicksMLC_ConcussionServer.lua

require "RicksMLC_ConcussionShared"

Events.OnClientCommand.Add(function(module, command, player, args)
    if module ~= "RicksMLC_Concussion" then return end

    if command == "AccidentalDischarge" then
        RicksMLC_ConcussionShared.AccidentalDischarge(player)
    end
end)