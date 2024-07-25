QBCore = exports['qb-core']:GetCoreObject()
RobbedGravestones = {}

function GiveReward(playerId)
    local givenRewards = 0
    local maxRewards = 2
    local Player = QBCore.Functions.GetPlayer(playerId)
    
    while givenRewards < maxRewards do
        for _, reward in ipairs(Config.Rewards) do
            if givenRewards >= maxRewards then
                break
            end
            
            local chance = math.random(1, 100)
            if chance <= reward.chance then
                local amount = math.random(reward.min, reward.max)
                if Player.Functions.AddItem(reward.item, amount) then
                    TriggerClientEvent('inventory:client:ItemBox', playerId, QBCore.Shared.Items[reward.item], "add", amount)
                    givenRewards = givenRewards + 1

                    -- Notify the player about the reward
                    TriggerClientEvent('ox_lib:notify', playerId, {
                        type = 'success',
                        title = 'Gravestone Robbed',
                        description = ('You received %d x %s'):format(amount, reward.item)
                    })
                end
            end
        end

        -- Ensure at least one reward is given
        if givenRewards == 0 then
            local guaranteedReward = Config.Rewards[math.random(1, #Config.Rewards)]
            local amount = math.random(guaranteedReward.min, guaranteedReward.max)
            if Player.Functions.AddItem(guaranteedReward.item, amount) then
                TriggerClientEvent('inventory:client:ItemBox', playerId, QBCore.Shared.Items[guaranteedReward.item], "add", amount)
                givenRewards = givenRewards + 1

                -- Notify the player about the guaranteed reward
                TriggerClientEvent('ox_lib:notify', playerId, {
                    type = 'success',
                    title = 'Gravestone Robbed',
                    description = ('You received %d x %s'):format(amount, guaranteedReward.item)
                })
            end
        end

        -- If at least one reward has been given and we're in the second iteration, break the loop
        if givenRewards > 0 then
            break
        end
    end
end

RegisterNetEvent('ant-gangsystem:server:GravestoneRobbed', function(gravestone)
    local src = source
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    RobbedGravestones[gravestone] = true
    if Config.SpawnZombies then
        local chance = math.random(1, 100)
        if chance <= Config.ChanceForZombie then
            TriggerClientEvent('ant-gravedigging:client:SpawnZombie', src, playerCoords, src)
        else
            -- Give Reward
            GiveReward(src)
        end
    else
        -- Give Reward
        GiveReward(src)
    end
end)

RegisterNetEvent('ant-gravedigging:server:SyncZombie', function(netId)
    -- Notify all clients to make the ped persistent
    TriggerClientEvent('ant-gravedigging:client:SyncZombie', -1, netId)
end)

QBCore.Functions.CreateCallback('ant-gravedigging:server:IsGravestoneRobbed', function(source, cb, gravestone)
    local gravestoneRobbed = RobbedGravestones[gravestone]
    print(gravestoneRobbed)
    if gravestoneRobbed then
        cb(false)
    else
        cb(true)
    end
end)