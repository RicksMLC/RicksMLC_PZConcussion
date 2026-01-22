-- RicksMLC_ConcussionServer.lua

require "RicksMLC_ConcussionShared"

RicksMLC_ConcussionServer = {}
function RicksMLC_ConcussionServer.HandleVehicleCrash(player, args)
    local vehicle = VehicleManager.instance:getVehicleByID(args.vehicle)
    if not vehicle or not vehicle:hasPassenger() then return end

    for seat=0, vehicle:getMaxPassengers()-1 do
        local passenger = vehicle:getCharacter(seat)
        if passenger then
            RicksMLC_ConcussionShared.AccidentalDischarge(passenger)
        end
    end
end

Events.OnClientCommand.Add(function(module, command, player, args)
    if module == "vehicle" then
        if command == "crash" then
            RicksMLC_ConcussionServer.HandleVehicleCrash(player, args)        
        end
        return
    end
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