QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('ant-gravedigging:client:Notify', function(label, message, notifyType)
    if Config.Notify == "ox" then
        if notifyType == "info" then
            lib.notify({
                title = label,
                description = message,
                duration = 7500,
                position = 'center-right',
                icon = 'circle-info',
                iconColor = '#0000FF'
            })
        elseif notifyType == "success" then
            lib.notify({
                title = label,
                description = message,
                duration = 7500,
                position = 'center-right',
                icon = 'circle-check',
                iconColor = '#008000'
            })
        elseif notifyType == "error" then
            lib.notify({
                title = label,
                description = message,
                duration = 7500,
                position = 'center-right',
                icon = 'ban',
                iconColor = '#C53030'
            })
        end
    elseif Config.Notify == "qb" then
        QBCore.Functions.Notify(message, notifyType, 7500)
    elseif Config.Notify == "okok" then
        exports['okokNotify']:Alert(label, message, 7500, notifyType, true)
    elseif Config.Notify == "other" then
        -- Place your custom notify event here
    end
end)

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
                            TriggerEvent('ant-gravedigging:client:Notify', "Gravestone Robbed", "This gravestone has already been robbed", "error")
                        end
                    end,
                    label = "Rob Gravestone",
                    icon = "fa-solid fa-skull-crossbones",
                    canInteract = function()
                        local hour = GetClockHours()
                        if hour >= 20 or hour < 6 then
                            return true
                        else
                            return false
                        end
                    end,
                },
            },
            distance = 1,
        })
    end
    for k, v in pairs(Config.Tombstones) do
        exports['qb-target']:AddBoxZone("tombstone"..k, v.coords, 1.5, 1.5, {
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
                            TriggerEvent('ant-gravedigging:client:Notify', "Tombstone Robbed", "This tombstone has already been robbed", "error")
                        end
                    end,
                    label = "Rob Tombstone",
                    icon = "fa-solid fa-skull-crossbones",
                    canInteract = function()
                        local hour = GetClockHours()
                        if hour >= 20 or hour < 6 then
                            return true
                        else
                            return false
                        end
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
                TriggerEvent('ant-gravedigging:client:Notify', "Cursed", "You are cursed! The ghosts are coming after you!", "error")
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
    local playerPedId = PlayerPedId()
    TaskStartScenarioInPlace(playerPedId, "CODE_HUMAN_MEDIC_TEND_TO_DEAD", 0, true)
    FreezeEntityPosition(playerPedId, true)
    local animPlaying = true
    Citizen.CreateThread(function()
        Citizen.Wait(15000)
        animPlaying = false
    end)
    while animPlaying do
        Citizen.Wait(0)
    end
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
                    TriggerEvent('ant-gravedigging:client:Notify', "Failed Lockpick", "You failed to break the lockpick on the coffin!", "error")
                end
            end
        else
            TriggerEvent('ant-gravedigging:client:Notify', "Missing Item", "You have nothing to pick the lock with!", "error")
        end
    else
        TriggerServerEvent('ant-gangsystem:server:GravestoneRobbed', gravestone)
    end
    ClearPedTasks(playerPedId)
    FreezeEntityPosition(playerPedId, false)
end)

RegisterNetEvent('ant-gravedigging:client:RobTombstone', function(tombstone)
    local playerPedId = PlayerPedId()
    TaskStartScenarioInPlace(playerPedId, "CODE_HUMAN_MEDIC_TEND_TO_DEAD", 0, true)
    FreezeEntityPosition(playerPedId, true)
    local animPlaying = true
    Citizen.CreateThread(function()
        Citizen.Wait(15000)
        animPlaying = false
    end)
    while animPlaying do
        Citizen.Wait(0)
    end
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
                    TriggerServerEvent('ant-gangsystem:server:FailedTombstoneRobbery', tombstone)
                    TriggerEvent('ant-gravedigging:client:Notify', "Failed Lockpick", "You failed to break the lockpick on the coffin!", "error")
                end
            end
        else
            TriggerEvent('ant-gravedigging:client:Notify', "Missing Item", "You have nothing to pick the lock with!", "error")
        end
    else
        TriggerServerEvent('ant-gangsystem:server:TombstoneRobbed', tombstone)
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