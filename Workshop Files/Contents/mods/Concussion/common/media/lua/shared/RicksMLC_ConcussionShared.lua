-- RicksMLC_ConcussionShared.lua

RicksMLC_ConcussionShared = {}

function RicksMLC_ConcussionShared.GetPlayer(userName, verbose)
    local player = getPlayerFromUsername(userName)
    if not player then
        if verbose then DebugLog.log(DebugType.Mod, "RicksMLC_ConcussionShared.GetPlayer() Error: player username '" .. userName .. "' not found.  Current users:") end
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

Events.OnServerCommand.Add(function(module, command, args)
    if module ~= "RicksMLC_Concussion" then return end

    if command == "PlayWeaponSound" then
        local character = RicksMLC_ConcussionShared.GetPlayer(args.username, false)
        RicksMLC_ConcussionShared.PlayWeaponSound(character, args.soundName)
    end        
end)

function RicksMLC_ConcussionShared.PlayWeaponSound(character, soundName)
    character:playSound(soundName);
end

function RicksMLC_ConcussionShared.AccidentalDischarge(character)
    --DebugLog.log(DebugType.Mod, "RicksMLC_ConcussionShared.AccidentalDischarge() called for '" .. character:getUsername() .. "'")
    local weapon = character:getPrimaryHandItem()
    --Copied from ISReloadWeaponAction.attackHook = function(character, chargeDelta, weapon)
    if ISReloadWeaponAction.canShoot(character, weapon) then
        local radius = weapon:getSoundRadius();
        if isClient() or isServer() then -- limit sound radius in MP
            radius = radius / 1.8
        end
        character:addWorldSoundUnlessInvisible(radius, weapon:getSoundVolume(), false);
        -- FIXME: Remove when tested for duplicate sound issue
        if isServer() then
            sendServerCommand('RicksMLC_Concussion', 'PlayWeaponSound', { playerID = character:getOnlineID(), username = character:getUsername(), soundName = weapon:getSwingSound() })
        else
            RicksMLC_ConcussionShared.PlayWeaponSound(character, weapon:getSwingSound())
        end
        if weapon:haveChamber() then
            weapon:setRoundChambered(false)
        end

        ISReloadWeaponAction.onShoot(character, weapon) -- Handles the weapon discharge ammunition
        syncHandWeaponFields(character, weapon)

        chance = ZombRand(100)
        if chance <= SandboxVars.RicksMLC_Concussion.AccidentalDischargeDeafnessChance and not RicksMLC_WPHS.IsWearingHearingProtection() then
            if isServer() then
                sendServerCommand(character, 'RicksMLC_Concussion', 'StartImmediateDeafness', { playerID = character:getOnlineID(), username = character:getUsername() })
            else
                RicksMLC_EarDamage.Instance():StartImmediateDeafness()
            end
        end

        -- Probability to hit:
        --  Base chance is 60% with 20% chance of hitting a zombie
        --  Unlucky is 85% shoot self, with 10% shoot zombie
        --  Lucky is 10% self, with 90% chance of hitting a zombie
        local baseChance = SandboxVars.RicksMLC_Concussion.ShootSelfBaseChance
        local zombieChance = SandboxVars.RicksMLC_Concussion.ShootZombieChance
        -- FIXME: Remove as Lucky/Unlucky traits are not in PZ B42
        -- if character:HasTrait("Lucky") then
        --     baseChance = SandboxVars.RicksMLC_Concussion.ShootSelfLuckyChance
        --     zombieChance = SandboxVars.RicksMLC_Concussion.ShootZombieLuckyChance
        -- elseif character:HasTrait("Unlucky") then
        --     baseChance = SandboxVars.RicksMLC_Concussion.ShootSelfUnluckyChance
        --     zombieChance = SandboxVars.RicksMLC_Concussion.ShootZombieUnluckyChance
        -- end
        local n = ZombRand(100)
        if n <= baseChance then
            -- Shot yourself
            character:Hit(weapon, character, 0, false, 0)
            character:sync()
        else
            local z = ZombRand(100)
            if z <= zombieChance then
                -- Shoot a zombie
                local zombie = getCell():getNearestVisibleZombie(character:getPlayerNum())
                if zombie then
                    local distance = IsoUtils.DistanceToSquared(zombie:getX(), zombie:getY(), zombie:getZ(),
                                                                character:getX(), character:getY(), character:getZ())
                    if distance <= (weapon:getMaxRange() * weapon:getMaxRange()) then
                        zombie:Hit(weapon, character, 0, false, 0)
                        zombie:knockDown(false)
                        zombie:sync()
                    end
                end
            end
        end
    else
        character:playSound(weapon:getClickSound())
    end
end
