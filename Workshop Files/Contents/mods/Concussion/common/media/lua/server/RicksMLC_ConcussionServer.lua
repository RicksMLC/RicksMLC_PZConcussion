-- RicksMLC_ConcussionServer.lua

require "RicksMLC_ConcussionShared"

Events.OnClientCommand.Add(function(module, command, player, args)
    -- if module == "vehicle" then
    --     if command == "crash" then
    --         RicksMLC_SharedUtils.DumpArgs(args, lvl, "RicksMLC_ConcussionServer.OnClientCommand(): vehicle crash")
    --         return
    --     end
    --     -- Let vehicle module handle its own commands
    --     return
    -- end
    if module ~= "RicksMLC_Concussion" then return end

    if command == "AccidentalDischarge" then
        RicksMLC_ConcussionShared.AccidentalDischarge(player)
    end
    if command == "AddHardOfHearing" then
        player:getCharacterTraits():add(CharacterTrait.HARD_OF_HEARING)
        player:sync()
    end
    if command == "RemoveHardOfHearing" then
        player:getCharacterTraits():remove(CharacterTrait.HARD_OF_HEARING)
        player:sync()
    end
    if command == "AddDeaf" then
        player:getCharacterTraits():add(CharacterTrait.DEAF)
        player:sync()
    end
    if command == "RemoveDeaf" then
        player:getCharacterTraits():remove(CharacterTrait.DEAF)
        player:sync()
    end
end)