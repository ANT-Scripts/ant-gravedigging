QBCore = exports['qb-core']:GetCoreObject()

CreateThread(function()
    for k, v in pairs(Config.Gravestones) do
        exports['qb-target']:AddBoxZone("gravestone"..k, v.coords, 1, 1, {
            name = "gravestone"..k,
            heading = v.coords.w,
            minZ = v.coords.z - 1,
            maxZ = v.coords.z + 1,
            debugpoly = false,
        }, {
            options = {
                {
                    type = "client",
                    action = function()
                        local p = promise.new()
                        QBCore.Functions.TriggerCallback('ant-gravedigging:server:IsGravestoneRobbed', function(allowed)
                            p:resolve(allowed)
                        end, k)
                        local allowed = Citizen.Await(p)
                        if allowed then
                            TriggerEvent('ant-gravedigging:client:RobGravestone', k)
                        else
                            lib.notify({
                                type = 'error',
                                title = 'Gravestone Robbed',
                                description = 'This gravestone has already been robbed!'
                            })
                        end
                    end,
                    label = "Rob Gravestone",
                    icon = "fa-solid fa-skull-crossbones",
                    canInteract = function()
                        return true
                    end,
                },
            },
            distance = 1,
        })
    end
    for k, v in pairs(Config.Tombstones) do
        exports['qb-target']:AddBoxZone("tombstone"..k, v.coords, 1, 1, {
            name = "tombstone"..k,
            heading = v.coords.w,
            minZ = v.coords.z - 1,
            maxZ = v.coords.z + 1,
            debugpoly = false,
        }, {
            options = {
                {
                    type = "client",
                    action = function()
                        local p = promise.new()
                        QBCore.Functions.TriggerCallback('ant-gravedigging:server:IsTombstoneRobbed', function(allowed)
                            p:resolve(allowed)
                        end, k)
                        local allowed = Citizen.Await(p)
                        if allowed then
                            TriggerEvent('ant-gravedigging:client:RobTombstone', k)
                        else
                            lib.notify({
                                type = 'error',
                                title = 'Tombstone Robbed',
                                description = 'This tombstone has already been robbed!'
                            })
                        end
                    end,
                    label = "Rob Tombstone",
                    icon = "fa-solid fa-skull-crossbones",
                    canInteract = function()
                        return true
                    end,
                },
            },
            distance = 1,
        })
    end
end)

CreateThread(function()
    if Config.UseCursedItems then
        while true do
            Citizen.Wait(1000 * 60 * Config.TimeUntilGhostAttack)
            local hasCursedItem = false
            for k, v in pairs(Config.CursedItems) do
                local hasItem = QBCore.Functions.HasItem(v)
                if hasItem then
                    hasCursedItem = true
                    break
                else
                    hasCursedItem = false
                end
            end
            if hasCursedItem then
                lib.notify({
                    type = 'error',
                    title = 'Cursed',
                    description = 'You are cursed! The ghosts are coming after you!'
                })
                GhostAttack()
            end
        end
    end
end)

RegisterNetEvent('ant-gravedigging:client:GhostAttack', function()
    GhostAttack()
    QBCore.Functions.Progressbar("ghostattack", "Recovering From Ghost Attack...", Config.GhostAttackRecoveryTime, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = "missarmenian2",
        anim = "drunk_loop",
        flags = 1,
    }, {}, {}, function() -- Done 
        ClearPedTasks(PlayerPedId())
        StopScreenEffect("DrugsMichaelAliensFightIn")
        StopScreenEffect("DrugsMichaelAliensFight")
        StopScreenEffect("DrugsMichaelAliensFightOut")
    end)
end)

RegisterNetEvent('ant-gravedigging:client:RobGravestone', function(gravestone)
    -- Start the progress bar with the shoveling animation
    if lib.progressBar({
        duration = Config.Progressbar.duration,
        label = "Robbing Gravestone",
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = true,
            sprint = true
        },
        anim = {
            dict = Config.Progressbar.animDict,
            clip = Config.Progressbar.animClip
        },
        --[[ WORKING ON THIS BUT THE PLACEMENT IS OFF
        prop = {
            model = 'prop_tool_shovel',
            bone = 60309,
            pos = { x = 0.1, y = -0.02, z = -0.02 },
            rot = { x = 90.0, y = 180.0, z = 270.0 }
        }
        ]]
    }) then
        -- If the progress bar completes
        local chance = math.random(1, 100)
        if chance <= Config.LockCoffinChance then
            local hasItem = QBCore.Functions.HasItem(Config.LockpickItem)
            if hasItem then
                if Config.Minigames.BDMinigames.Enabled then
                    local unlocks = Config.Minigames.BDMinigames.Unlocks
                    local rows = Config.Minigames.BDMinigames.Rows
                    local time = Config.Minigames.BDMinigames.Time
                    local success = exports['bd-minigames']:Lockpick(unlocks, rows, time)
                    if success then
                        TriggerServerEvent('ant-gangsystem:server:GravestoneRobbed', gravestone)
                    else
                        TriggerServerEvent('ant-gangsystem:server:FailedGravestoneRobbery', gravestone)
                        lib.notify({
                            type = 'error',
                            title = 'Failed Lockpick',
                            description = 'You failed to break the lockpick on the coffin!'
                        })
                    end
                end
            else
                lib.notify({
                    type = 'error',
                    title = 'Missing Item',
                    description = 'You have nothing to pick the lock with!'
                })
            end
        else
            TriggerServerEvent('ant-gangsystem:server:GravestoneRobbed', gravestone)
        end
    else
        -- If the progress bar is cancelled
        lib.notify({
            type = 'error',
            title = 'Action Cancelled',
            description = 'You have cancelled robbing the gravestone.'
        })
    end
end)

RegisterNetEvent('ant-gravedigging:client:RobTombstone', function(tombstone)
    -- Start the progress bar with the shoveling animation
    if lib.progressBar({
        duration = Config.Progressbar.duration,
        label = "Robbing Tombstone",
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = true,
            sprint = true
        },
        anim = {
            dict = Config.Progressbar.animDict,
            clip = Config.Progressbar.animClip
        },
        --[[ WORKING ON THIS BUT THE PLACEMENT IS OFF
        prop = {
            model = 'prop_tool_shovel',
            bone = 60309,
            pos = { x = 0.1, y = -0.02, z = -0.02 },
            rot = { x = 90.0, y = 180.0, z = 270.0 }
        }
        ]]
    }) then
        -- If the progress bar completes
        local chance = math.random(1, 100)
        if chance <= Config.LockCoffinChance then
            local hasItem = QBCore.Functions.HasItem(Config.LockpickItem)
            if hasItem then
                if Config.Minigames.BDMinigames.Enabled then
                    local unlocks = Config.Minigames.BDMinigames.Unlocks
                    local rows = Config.Minigames.BDMinigames.Rows
                    local time = Config.Minigames.BDMinigames.Time
                    local success = exports['bd-minigames']:Lockpick(unlocks, rows, time)
                    if success then
                        if Config.GhostAttack then
                            local chance = math.random(1, 100)
                            if chance <= Config.GhostAttackChance then
                                TriggerServerEvent('ant-gangsystem:server:TombstoneRobbed', tombstone)
                                TriggerEvent('ant-gravedigging:client:GhostAttack')
                            else
                                TriggerServerEvent('ant-gangsystem:server:TombstoneRobbed', tombstone)
                            end
                        end
                    else
                        TriggerServerEvent('ant-gangsystem:server:FailedGravestoneRobbery', tombstone)
                        lib.notify({
                            type = 'error',
                            title = 'Failed Lockpick',
                            description = 'You failed to break the lockpick on the coffin!'
                        })
                    end
                end
            else
                lib.notify({
                    type = 'error',
                    title = 'Missing Item',
                    description = 'You have nothing to pick the lock with!'
                })
            end
        else
            TriggerServerEvent('ant-gangsystem:server:TombstoneRobbed', tombstone)
        end
    else
        -- If the progress bar is cancelled
        lib.notify({
            type = 'error',
            title = 'Action Cancelled',
            description = 'You have cancelled robbing the gravestone.'
        })
    end
end)


RegisterNetEvent('ant-gravedigging:client:SpawnZombie', function(coords, targetPlayer)
    local zombieModel = `u_m_y_zombie_01`
    
    -- Load zombie model
    RequestModel(zombieModel)
    while not HasModelLoaded(zombieModel) do
        Wait(0)
    end
    
    -- Spawn zombie
    local zombiePed = CreatePed(4, zombieModel, coords.x + 2, coords.y + 2, coords.z, 0.0, true, true)
    
    -- Make zombie attack the player
    TaskCombatPed(zombiePed, GetPlayerPed(GetPlayerFromServerId(targetPlayer)), 0, 16)
    
    -- Clean up model
    SetModelAsNoLongerNeeded(zombieModel)
end)

RegisterNetEvent('ant-gravedigging:client:SyncZombie', function(netId)
    local zombiePed = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(zombiePed) then
        SetEntityAsMissionEntity(zombiePed, true, false)
        SetPedAsEnemy(zombiePed, true)
        SetPedRelationshipGroupHash(zombiePed, `HATES_PLAYER`)
        TaskCombatHatedTargetsAroundPed(zombiePed, 20.0)
    end
end)

function GhostAttack()
    StartScreenEffect("DrugsMichaelAliensFightIn", 3.0, 0)Wait(math.random(5000, 8000))
    Wait(math.random(500, 1000))
    StartScreenEffect("DrugsMichaelAliensFight", 3.0, 0)
    local Rand = math.random(1, 5)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "ghostattack",
        rand = Rand,
    })
    LoadAnimDict("random@drunk_driver_1")
    TaskPlayAnim(PlayerPedId(), "random@drunk_driver_1", "drunk_fall_over", 2.0, 2.0, -1, 0, 0, false, false, false)
    Wait(math.random(500, 1000))
    StartScreenEffect("DrugsMichaelAliensFightOut", 3.0, 0)
    Wait(6000)
end

RegisterNuiCallback("close", function()
    SetNuiFocus(false, false)
end)

function LoadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(5)
    end
end