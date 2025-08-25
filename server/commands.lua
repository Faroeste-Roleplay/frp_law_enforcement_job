local function sendMessageOnChat( classe, onlyDuty, name, message, color )
    if not color then
        color = 'ADVERT'
    end
    Business.triggerEventByBusinessClass( classe, onlyDuty, 'chat:addMessage:fromCommand', {
        template = "<div class='chat-message " .. color .. "'><strong>"..name..":</strong> {0}</div>",
        args = {message}
    })
end

RegisterCommand("cchat", function(playerId, args)
    TriggerClientEvent("chat:clear", playerId)
end)

RegisterCommand("limparchat", function(playerId, args)
    TriggerClientEvent("chat:clear", playerId)
end)

RegisterCommand("co", function(source, args)
    local playerId =  tonumber(source)
    local User = API.GetUserFromSource( playerId )

    local Character = User:GetCharacter()
    local charName = Character:GetFullName()

    if Business.hasClassePermission(playerId, "police") then
        sendMessageOnChat( 'police', false, ("<strong>Oficial - %s</strong>"):format(charName),  table.concat(args," "))
    end
end)

RegisterCommand("cd", function(source, args) 
    local playerId =  tonumber(source)
    local User = API.GetUserFromSource( playerId )
    local Character = User:GetCharacter()

    local charName = Character:GetFullName()

    if Business.hasClassePermission(playerId, "doctor") then
        sendMessageOnChat( 'doctor', false, ("<strong>Médico - %s</strong>"):format(charName),  table.concat(args," "))
    end
end)

RegisterCommand("cm", function(source, args)
    local playerId =  tonumber(source)
    local User = API.GetUserFromSource( playerId )
    local Character = User:GetCharacter()
    local charName = Character:GetFullName()

    if Business.hasClassePermission(playerId, "doctor") then
        sendMessageOnChat( 'police', false, ("<strong>Médico - %s</strong>"):format(charName),  table.concat(args," "), 'JORNAL')
        sendMessageOnChat( 'doctor', false, ("<strong>Médico - %s</strong>"):format(charName),  table.concat(args," "), 'JORNAL')
    end

    if Business.hasClassePermission(playerId, "police") then
        sendMessageOnChat( 'police', false, ("<strong>Oficial - %s</strong>"):format(charName),  table.concat(args," "), 'JORNAL')
        sendMessageOnChat( 'doctor', false, ("<strong>Oficial - %s</strong>"):format(charName),  table.concat(args," "), 'JORNAL')
    end
end)

RegisterCommand("fv", function(source, args)
    local playerId =  tonumber(source)
    local User = API.GetUserFromSource( playerId )
    local Character = User:GetCharacter()
    local charName = Character:GetFullName()

    local color = 'NOEMERGENCY'

    if Business.hasClassePermission(playerId, "police") then
        TriggerClientEvent('chat:addMessage:fromCommand', -1, {
            template = "<div class='chat-message " .. color .. "'><strong>"..("<strong>Ferrovia - %s</strong>"):format(charName)..":</strong> {0}</div>",
            args = { table.concat(args," ") }
        })
    end
end)

RegisterCommand("anuncio", function(source, args) 
    local playerId =  tonumber(source)

    local User = API.GetUserFromSource( playerId )
    local Character = User:GetCharacter()
    local charName = Character:GetFullName()

    local canSend = false

    local name = ""
    local color = ""

    if Business.hasClassePermission(playerId, "doctor") and Business.getOnDutyStatus(playerId, "doctor") then
        name = ("Médico - %s"):format(charName)
        canSend = true
        color = "emergency"
    end

    if Business.hasClassePermission(playerId, "police") and Business.getOnDutyStatus(playerId, "police") then
        name = ("Oficial - %s"):format(charName)
        canSend = true
        color = "warning"
    end

    if canSend then
        TriggerClientEvent("chat:addMessage:fromCommand", -1,  {
            template = "<div class='chat-message ".. color .."'><strong>"..name..":</strong> {0}</div>",
            args = {table.concat(args," ")}
        })
    end
end)

local requestsAwaiting = {}
local requestsAccepted = {}

local function getRequestById( requestId )
    for index, request in pairs( requestsAwaiting ) do
        if request.id == requestId then
            return request
        end
    end
end

local function getAcceptedRequestByRequesterId( playerId )
    for index, request in pairs( requestsAccepted ) do
        if request.requesterId == playerId then
            return request
        end
    end
end

local function getAcceptedRequestByCitizenId( citizenId )
    for index, request in pairs( requestsAccepted ) do
        if request.acceptedBy == citizenId then
            return request
        end
    end
end

local function generateRequest( requesterId, group )
    local playerPed = GetPlayerPed( requesterId )
    local request = {}

    local hasActive = getRequestById( requesterId ) 

    if hasActive then
        return cAPI.Notify(requesterId, "error", "Não é possível fazer um chamado mais de uma vez")
    end

    if playerPed then
        local playerCoords = GetEntityCoords( playerPed )

        request.time = os.time()

        math.randomseed( request.time )
        request.id = RandomStr(10)
        request.requesterId = requesterId
        request.coords = playerCoords
        request.group = group

        table.insert(requestsAwaiting, request)
        return request
    end

    return false
end

local coolDownCalls = {}

RegisterCommand("sos", function(source, args) 
    local playerId =  tonumber(source)

    local hasRequest = getAcceptedRequestByRequesterId( playerId )

    if hasRequest then
        return cAPI.Notify(playerId, "error", "Já possuo um chamado ativo.")
    end

    local request = generateRequest( playerId, 'doctor' )
    local currentTime = os.time()

    local citizenIds = Business.getOnlineByBusinessClass( "doctor", 'table', true )

    if #citizenIds < 1 then
        return cAPI.NotifyToast(playerId, "info", "Não há médicos para lhe atender no momento")
    end 

    local playerLastCall = coolDownCalls[playerId]
    
    if playerLastCall then
        local diffTime = (currentTime - coolDownCalls[playerId])
        if diffTime <= 120 then
            return cAPI.Notify(playerId, "error", ("Só posso efetuar um novo chamado em %s segundos"):format( 120 - diffTime ))
        end
    end

    if request then
        --## Adicionar mensagem caso não tenha medico
        Business.triggerEventByBusinessClass( 'doctor', true, 'law:common:addRequestOnList', request)
        cAPI.Notify(playerId, "success", "O chamado foi efetuado")

        coolDownCalls[playerId] = os.time()
        
        local playerPed = GetPlayerPed( playerId )
        local playerCoords = GetEntityCoords( playerPed )
        lib.logger(playerId, ("Chamou os medicos  - %s - %s "):format( GetPlayerName(playerId), json.encode(playerCoords) ))
    end
end)

RegisterCommand("oficiaisOnline", function(source, args) 
    local playerId =  tonumber(source)
    local emServico = args[1] ~= nil

    if API.IsPlayerAceAllowedGroup(playerId, "staff")
        or Business.hasClassePermission(playerId, "police")
        or Business.hasClassePermission(playerId, "doctor")
    then
        local citizenIds = Business.getOnlineByBusinessClass( "police", 'table', emServico )
        local online = "Oficiais : <br>"

        local count = 0

        for _, citizenId in pairs( citizenIds ) do 
            local user = API.GetUserFromCitizenId( citizenId )
            if user then
                online = online .. "<b>".. user:GetId() .. "</b><br>"
                count += 1
            end
        end

        online = online .. "<b> Total online: " .. count .." </b>"
        TriggerClientEvent('texas:notify:simple', playerId, online, 7000)
    else
        local citizenIds = Business.getOnlineByBusinessClass( "police", 'table', true )

        local online = "<b> Oficiais em serviço: " .. #citizenIds .." </b>"
        TriggerClientEvent('texas:notify:simple', playerId, online, 7000)
    end
end)


RegisterCommand("medicosOnline", function(source, args) 
    local playerId =  tonumber(source)
    local emServico = args[1] ~= nil

    if API.IsPlayerAceAllowedGroup(playerId, "staff") 
        or Business.hasClassePermission(playerId, "doctor") 
        or Business.hasClassePermission(playerId, "police") 
    then
        local citizenIds = Business.getOnlineByBusinessClass( "doctor", 'table', emServico )
        local online = "Médicos : <br>"

        local count = 0

        for _, citizenId in pairs( citizenIds ) do 
            local user = API.GetUserFromCitizenId( citizenId )
            if user then
                online = online .. "<b>".. user:GetId() .. "</b><br>"
                count += 1
            end
        end

        online = online .. "<b> Total online: " .. count .." </b>"
        TriggerClientEvent('texas:notify:simple', playerId, online, 7000)
    else
        local citizenIds = Business.getOnlineByBusinessClass( "doctor", 'table', true )

        local online = "<b> Medicos em serviço: " .. #citizenIds .." </b>"
        TriggerClientEvent('texas:notify:simple', playerId, online, 7000)
    end
end)


RegisterNetEvent("law:common:acceptRequest", function( requestId )
    local playerId = source

    local User = API.GetUserFromSource( playerId )
    local Character = User:GetCharacter()

    local alreadyAccepted = requestsAccepted[requestId]

    if alreadyAccepted then
        return cAPI.Notify(playerId, "error", "Essa solicitação já foi atendida por outra pessoa")
    end

    local request = getRequestById( requestId )

    if not request then
        return cAPI.Notify(playerId, "error", "Essa solicitação não existe")
    end

    request.acceptedBy = Character.citizenId

    requestsAccepted[request.id] = request

    TriggerClientEvent("law:common:setMission", playerId, request.coords)
    TriggerClientEvent("law:common:setMissionResponse", request.requesterId)

    Business.triggerEventByBusinessClass( request.group, true, 'core:client:responseRequest' )
end)

CreateThread(function()

    Wait(1500)

    while true do 

        local currentTime = os.time()

        for index, req in ipairs( requestsAwaiting ) do
            local time = req.time
            local diffTime = currentTime - time

            if diffTime >= 1200 then
                table.remove(requestsAwaiting, index)
            end
        end

        for index, req in ipairs( requestsAccepted ) do 
            local time = req.time
            local diffTime = currentTime - time

            if diffTime >= 1200 then
                requestsAccepted[req.id] = nil
            end
        end

        Wait( 30000 )
    end
end)

RegisterNetEvent("law:common:currentMissionHasBeenResolved", function()
    local playerId = source

    local User = API.GetUserFromSource( playerId )
    local Character = User:GetCharacter()

    if Character then
        local citizenId = Character.citizenId
        local request = getAcceptedRequestByCitizenId( citizenId )

        if request then
            TriggerClientEvent("law:common:setMission", playerId)
            TriggerClientEvent("law:common:setMissionResponse", request.requesterId, true)
            requestsAccepted[request.id] = nil
        end
    end
end)

AddEventHandler('FRP:onCharacterLoaded', function(User, CharacterId)
    local Character = User:GetCharacter()
    local citizenId = Character.citizenId

    local request = getAcceptedRequestByCitizenId( citizenId )

    if request then
        TriggerClientEvent("law:common:setMission", User:GetSource(), request.coords)
    end
end)

AddEventHandler('playerDropped', function( playerId )
    local request = getAcceptedRequestByRequesterId( playerId )
    
    if request then
        local citizenId = request.acceptedBy
        local User = API.GetUserFromCitizenId( citizenId )
        if User then
            local targetId =  User:GetSource()
            TriggerClientEvent("law:common:setMission",targetId)
            cAPI.Notify(targetId, "error", "A pessoa desistiu do chamado")
        end

        requestsAccepted[request.id] = nil
    end
end)