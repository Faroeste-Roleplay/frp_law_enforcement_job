
local function loadAnimDict(dict) -- interactions, job,
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Citizen.Wait(10)
    end
end

local onDuty = false

AddEventHandler("law:dutyToggle", function ()
    onDuty = not onDuty
    TriggerServerEvent("business.setOnDuty", "police", onDuty)
end)

AddEventHandler("doctor:dutyToggle", function ()
    onDuty = not onDuty
    TriggerServerEvent("business.setOnDuty", "doctor", onDuty)
end)

AddEventHandler("police:client:openMdt", function()
    ExecuteCommand("mdt")
end)


local badge = nil
local usingBadge = false
local usingBadgeHash = nil

enum 'eWearableBadges'
{
    ['s_badgesherif01x']    = 1,
    ['s_badgeusmarshal01x'] = 2,
    ['s_badgepolice01x']    = 3,
    ['s_badgedeputy01x']    = 4,
    ['s_badgepinkerton01x'] = 5,
}

--[[ Entitidade local das badges de outros players, talvez até o nosso? ]]
local gRemoteWearableBadgeEntities = { }

function WearBadge(badgeModelName)
    local wearableBadgeEnum = eWearableBadges[badgeModelName]

    if not wearableBadgeEnum then return end

    local hasUnknownComponent = exports.frp_lib:getPedComponentAtIndexCategory({ -529714994, 107129908 }, PlayerPedId()) ~= nil

    local wearableAttachOffset = hasUnknownComponent and 0.055 or 0.020

    LocalPlayer.state:set('wearingBadge', { wearableBadgeEnum, wearableAttachOffset }, true)
end

function IsWearingBadge()
    return LocalPlayer.state.wearingBadge ~= nil
end

function UnwearBadge()
    LocalPlayer.state:set('wearingBadge', nil, true)
end

AddStateBagChangeHandler('wearingBadge', nil, function(bagName, key, value, reserved, replicated)
    if replicated then
        --[[ Ignorar update local, para não duplicar as entidades. ]]
        return
    end

    local playerServerId = tonumber(string.match(bagName, "player:(%d+)"))

    if gRemoteWearableBadgeEntities[playerServerId] then
        local entity = gRemoteWearableBadgeEntities[playerServerId]

        DeleteEntity(entity)

        gRemoteWearableBadgeEntities[playerServerId] = nil
    end

    if playerServerId ~= GetPlayerServerId(PlayerId()) then
        -- Caso não seja o nosso player local.
        while GetPlayerFromServerId(playerServerId) == -1 do
            Wait(0)
        end
    end

    local playerId = GetPlayerFromServerId(playerServerId)

    while GetPlayerPed(playerId) == 0 do
        Wait(0)
    end

    local playerPed = GetPlayerPed(playerId)

    if value == nil then
        return
    end

    local wearableBadgeEnum, wearableAttachOffset = table.unpack(value)

    local badgeModelName = eWearableBadges[wearableBadgeEnum]

    local badgeModelHash = GetHashKey(badgeModelName)

    RequestModel(badgeModelHash)
    
    while not HasModelLoaded(badgeModelHash) do
        Citizen.Wait(0)
    end

    local forward = GetEntityForwardVector(playerPed)

    local position = GetEntityCoords(playerPed) + forward * 0.7

    local entity = CreateObject(badgeModelHash, position, false, false, false)
    SetEntityCompletelyDisableCollision(entity, true, false)

    gRemoteWearableBadgeEntities[playerServerId] = entity

    local boneIndex = IsPedMale( playerPed ) and 419 or 464

    AttachEntityToEntity(entity, playerPed, boneIndex, -0.040, -0.12, wearableAttachOffset, -75.0, 90.0, 0.0, false, true, false, false, 2, true)
end)

RegisterNetEvent('police:client:applyBadgeInPlayer', function(badgeModelName)
    if IsWearingBadge() then
        UnwearBadge()
    else
        WearBadge(badgeModelName)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if IsWearingBadge() then
            UnwearBadge()
        end

        for _, remoteWearableBadgeEntity in pairs(gRemoteWearableBadgeEntities) do
            DeleteEntity(remoteWearableBadgeEntity)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(1000)

        --[[ Remover as entidades caso não estejam attacheds a nenhum ped/player ]]

        for playerServerId, remoteWearableBadgeEntity in pairs(gRemoteWearableBadgeEntities) do
            if not IsEntityAttached(remoteWearableBadgeEntity) then
                DeleteEntity(remoteWearableBadgeEntity)

                gRemoteWearableBadgeEntities[playerServerId] = nil
            end
        end
    end
end)

RegisterNetEvent("police:client:SendToJail", function()
    
    local nearbyPlayers = GetPersonaInfoClosestPlayers()

    local dialogOptions = { }

    for _, player in pairs ( nearbyPlayers ) do
        table.insert( dialogOptions, { value = player.userId, label = ("%s"):format(player.userId) })
    end

    local input = lib.inputDialog('Enviar para Prisão', {
        -- { type = "input", label = "ID do Player", placeholder = "1" },
        { type = 'multi-select', label = "Jogadores", options = dialogOptions },
        { type = "input", min = 1, max = 50, label = "Tempo de prisão (minutos)", placeholder = "10" },
    })

    if input then
        local playerIds = input[1]
        local timeToPrison = tonumber(input[2])

        for _, playerId in pairs( playerIds ) do 
            TriggerServerEvent('JAIL:sendToJail', playerId, timeToPrison)
        end
    end
end)

RegisterNetEvent("law:interaction:requestSendToJail", function( data )
    local entity = data.entity 

    local input = lib.inputDialog('Enviar para Prisão', {
        { type = "input", min = 1, max = 30, label = "Tempo de prisão (minutos)", placeholder = "10" },
    })

    local state = Entity(entity).state
    local userId = state.userId

    if input and userId then
        local timeToPrison = tonumber(input[1])
        TriggerServerEvent('JAIL:sendToJail', userId, timeToPrison)
    end
end)