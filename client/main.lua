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
                    icon = "fa-sharp fa-solid fa-arrow-up-from-bracket",
                    canInteract = function()
                        return true
                    end,
                },
            },
            distance = 3,
        })
    end
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
        --[[
        prop = {
            model = 'prop_tool_shovel',
            bone = 60309,
            pos = { x = 0.1, y = -0.02, z = -0.02 },
            rot = { x = 90.0, y = 180.0, z = 270.0 }
        }
        ]]
    }) then
        -- If the progress bar completes
        TriggerServerEvent('ant-gangsystem:server:GravestoneRobbed', gravestone)
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