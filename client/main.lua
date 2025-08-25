API = Tunnel.getInterface("API")
cAPI = Proxy.getInterface("API")
NPCService = Proxy.getInterface("NPCS")

AddEventHandler('law:client:GetDutyPlayers', function()
	TriggerServerEvent('law:GetDutyPlayers')
end)

AddEventHandler('law:client:toggleDuty', function()
	TriggerServerEvent('business.setOnDuty', "police")
end)


AddEventHandler('doctor:client:GetDutyPlayers', function()
	TriggerServerEvent('doctor:GetDutyPlayers')
end)

local isWhistling = false

RegisterNetEvent("law:whistle:item", function()
    if isWhistling then
        return
    end

    local playerPed = PlayerPedId()
    
    local _, weaponHash = GetCurrentPedWeapon(playerPed, false, 0, false)

    SetCurrentPedWeapon(playerPed, `WEAPON_UNARMED`, true)

    local whistleObj = createObject('p_whistle01x')

    attachEntityToBoneName("IK_R_HAND", whistleObj, playerPed)

    taskPlayAnim(playerPed, 'amb_rest@world_human_smoke_cigar@male_a@idle_a', "idle_b", 16 | 24, 4, -2, 0.4, 1000)

    Wait(100)

    TriggerServerEvent("law:whistle:replicatedSound")
    
    Wait(1000)

    DeleteEntity(whistleObj)

    SetCurrentPedWeapon(playerPed, weaponHash, true)

    isWhistling = false
end)


RegisterNetEvent("law:whistle:replicatedSound", function(serverId)
    local playerId = GetPlayerFromServerId( serverId )
    local playerPed = GetPlayerPed( playerId )

    Citizen.InvokeNative(0xD9130842D7226045, "NBD1_Sounds", false)
    if DoesEntityExist( playerPed ) then
        
        if playerPed == PlayerPedId() then
            Citizen.InvokeNative(0x6FB1DA3CA9DA7D90, 'POLICE_WHISTLE_MULTI', playerPed, 'NBD1_Sounds', false, 0, 0)
        else
            local coords = GetEntityCoords(playerPed)
            Citizen.InvokeNative(0xCCE219C922737BFA, 'POLICE_WHISTLE_MULTI',  coords.x,coords.y,coords.z, 'NBD1_Sounds', false, 0, 0)
        end
    end
end)

function attachEntityToBoneName(boneName, object, ped)
    local _, bone = GetEntityBoneIndexByName(ped, boneName)    

    AttachEntityToEntity(object, ped, 334, -0.1, 0, 0, 0, 90.0, 0, false, true, false, false, 2, true)
end


function taskPlayAnim(ped, dict, anim, flags, blendInSpeed, blendOutSpeed, delta, duraction)

    RequestAnimDict(dict)    

    while not HasAnimDictLoaded(dict)  do 
        Citizen.Wait(100)
    end

    TaskPlayAnim(ped, dict, anim, blendInSpeed, blendOutSpeed, duraction, flags, delta, true, 0, false, 0, false)
end 
function createObject(stringObj)        

    local objHash = GetHashKey(stringObj)

    RequestModel(objHash)

    local i = 0

    while not HasModelLoaded(objHash) and i <= 300 do
        i = i + 1
        Citizen.Wait(0)
    end

    if HasModelLoaded(objHash) then
        return CreateObject(stringObj, GetEntityCoords(PlayerPedId()), true, true, false, false, true)
    end

    return false
end
