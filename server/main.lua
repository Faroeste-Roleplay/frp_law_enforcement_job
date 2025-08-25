

API = Proxy.getInterface("API")
cAPI = Tunnel.getInterface("API")

Business = Proxy.getInterface("business")

-- Variables
local Objects = {}

function SendWebhookMessage(webhook,message)
	if webhook ~= nil and webhook ~= "" then
		PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({content = message}), { ['Content-Type'] = 'application/json' })
	end
end

local function CreateObjectId()
    if Objects then
        local objectId = math.random(10000, 99999)
        while Objects[objectId] do
            objectId = math.random(10000, 99999)
        end
        return objectId
    else
        local objectId = math.random(10000, 99999)
        return objectId
    end
end

local function GetCurrentCops()
    local amount = 0

    for _, playerId in pairs(GetPlayers()) do

        playerId = tonumber(playerId)
        local User = API.GetUserFromSource( playerId )
        local Character = User:GetCharacter()
    
        local citizenId = Character.citizenId
        local isOnDuty = Business.getOnDutyStatus(citizenId, "police")
            
        if Business.hasClassePermission(citizenId, "police") and isOnDuty then
            amount = amount + 1
        end
    end
    return amount
end

RegisterServerCallback('police:GetCops', function(source, cb)
    return GetCurrentCops()
end)

RegisterNetEvent('police:server:SetPlayerOutVehicle', function(playerId)
    local src = source
    local EscortPlayer = playerId

    if EscortPlayer then
        TriggerClientEvent("police:client:SetOutVehicle", EscortPlayer)
    end
end)

RegisterNetEvent('police:server:PutPlayerInVehicle', function(playerId)
    local src = source
    local EscortPlayer = playerId
    if EscortPlayer then
        TriggerClientEvent("police:client:PutInVehicle", EscortPlayer)
    end
end)

RegisterNetEvent('police:server:spawnObject', function(type)
    local src = source
    local objectId = CreateObjectId()
    Objects[objectId] = type
    TriggerClientEvent("police:client:spawnObject", src, objectId, type, src)
end)

RegisterNetEvent('police:server:deleteObject', function(objectId)
    TriggerClientEvent('police:client:removeObject', -1, objectId)
end)

RegisterNetEvent('evidence:server:UpdateStatus', function(data)
    local src = source
    PlayerStatus[src] = data
end)

RegisterNetEvent('police:server:UpdateCurrentCops', function()
    local amount = GetCurrentCops()
    TriggerClientEvent("police:SetCopCount", -1, amount)
end)

RegisterNetEvent("law:GetDutyPlayers", function()
    local _source = source
	local copName = ""

    local User = API.GetUserFromSource( _source )
    local Character = User:GetCharacter()

    local citizenId = Character:GetCitizenId()

    if not Business.hasClassePermission(citizenId, "police") then
        return
    end

    local copsOnline = exports.outlaw_activity_lock:GetOnlineLawMans('table')

    for i = 1, #copsOnline do
        local copSource = copsOnline[i]				

        local User = API.GetUserFromSource(copSource)
        local Character = User:GetCharacter()
        local charName = Character:GetFullName()
        local targetCitizenId = Character:GetCitizenId()

        -- if API.IsPlayerAceAllowedGroup(copSource, 'law') then
        if Business.hasClassePermission(targetCitizenId, "police") then
            local isOnDuty = Business:onDuty(targetCitizenId, "police")

            if isOnDuty then
                local personaName = charName
                copName = copName .. "<b>".. personaName .. "</b><br>"
            end
        end
    end

    TriggerClientEvent('texas:notify:simple', _source, copName, 3000)	
end)

RegisterNetEvent("law:whistle:replicatedSound", function()
    local playerId = source

    TriggerClientEvent("law:whistle:replicatedSound", -1, playerId)
end)