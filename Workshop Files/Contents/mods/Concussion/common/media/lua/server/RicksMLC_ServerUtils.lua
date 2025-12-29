-- RicksMLC_ServerUtils.lua
if not isServer() then return end


RicksMLC_ConcussionServerUtils = {}
function RicksMLC_ConcussionServerUtils.GetPlayer(userName, verbose)
    local player = getPlayerFromUsername(userName)
    if not player then
        if verbose then DebugLog.log(DebugType.Mod, "RicksMLC_ConcussionServerUtils.GetPlayer() Error: player username '" .. userName .. "' not found.  Current users:") end
        local playerList = getOnlinePlayers()
        for i = 0, playerList:size()-1 do
            if verbose then  DebugLog.log(DebugType.Mod, "  Username '" .. playerList:get(i):getUsername() .. "'")  end
            if playerList:get(i):getUsername() == userName then
                if verbose then DebugLog.log(DebugType.Mod, "  Username '" .. playerList:get(i):getUsername() .. "' found ¯\_(ツ)_/¯ ") end
                player = playerList:get(i)
                break
            end
        end
    end
    return player
end
