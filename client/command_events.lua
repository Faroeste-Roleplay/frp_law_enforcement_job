local gCurrentRequest
local gRequestList = {}

RegisterNetEvent("chat:addMessage:fromCommand", function(...)
	TriggerEvent("chat:addMessage", ...)
end)

local enabledBlip = false

function blipSonar( coords )
	local blipPattern = { name = 'Ajuda Solicitada', sprite = `blip_mp_gun_for_hire`, position = vec3(coords.x, coords.y, coords.z),  color = "BLIP_MODIFIER_MP_COLOR_2"}
    local blipMission = exports.frp_blips_manager:CreateBlip(blipPattern, true)

    local timeout = 120

    CreateThread(function()
        while enabledBlip do
            Wait(1500)

			if timeout <= 0 then
				break
			end	

            timeout = timeout - 1
        end

		exports.frp_blips_manager:DeleteBlip( blipMission )
    end)
end

local function displayRequest(request)
	PlaySoundFrontend("REWARD_NEW_GUN", "HUD_REWARD_SOUNDSET", true, 0)
	
	enabledBlip = true
	blipSonar( request.coords )
	local accepted = cAPI.Request("Há uma pessoa precisando de ajuda", 120)

	enabledBlip = false
	if accepted then
		TriggerServerEvent("law:common:acceptRequest", request.id)
	end

	-- Sempre limpa a request atual após a resposta (aceita ou não)
	TriggerEvent("core:client:responseRequest")
end

local function requestQueueCall()
	if gCurrentRequest ~= nil then
		return
	end

	gCurrentRequest = gRequestList[1]

	if not gCurrentRequest then
		return
	end

	displayRequest(gCurrentRequest)
end

RegisterNetEvent("core:client:responseRequest", function()
	if gCurrentRequest then 
		table.remove(gRequestList, 1)
		gCurrentRequest = nil
		enabledBlip = false
	end
	
	Wait(100)
	requestQueueCall()
end)

RegisterNetEvent("law:common:addRequestOnList", function(request)
	table.insert(gRequestList, request)

	Wait(100)
	requestQueueCall()
end)

---- mission

local currentMissionBlip
local blipPattern = { name = 'Ajuda', sprite = `blip_mp_playlist_freeforall`, position = vec3(0.0, 0.0, 0.0),  color = "BLIP_MODIFIER_MP_COLOR_4"}

local gRequestCoords

RegisterNetEvent("law:common:setMission", function( requestCoords )

	if not requestCoords then
		TriggerEvent("hud:hideMission")
		deleteBlip()
		return
	end

	if currentMissionBlip then 
		deleteBlip()
	end

	StartGpsMultiRoute(0xB2468351, true, true)

	TriggerEvent("hud:showMission", "Respondendo Chamado", "Vá até o local do chamado marcado em seu mapa de bolso para responder a ajuda solicitada")

    local liv = AddPointToGpsMultiRoute(requestCoords.x, requestCoords.y, requestCoords.z)
    SetGpsMultiRouteRender(true)

    blipPattern.position = requestCoords
	gRequestCoords = requestCoords
    currentMissionBlip = exports.frp_blips_manager:CreateBlip(blipPattern, true)

end)


function deleteBlip()
	exports.frp_blips_manager:DeleteBlip(currentMissionBlip)
    ClearGpsMultiRoute()

	TriggerEvent("hud:hideMission")

	gRequestCoords = nil
	currentMissionBlip = nil
end

RegisterNetEvent("law:common:setMissionResponse", function( deleteMode )
	if not deleteMode then
		TriggerEvent("coolDownToExitMsg")
		return TriggerEvent("hud:showMission", "Chamado aceito", "Uma pessoa aceitou seu chamado e já está à caminho.")
	end

	TriggerEvent("hud:hideMission")
end)

AddEventHandler("coolDownToExitMsg", function()
	Wait(60000 * 2)

	TriggerEvent("hud:hideMission")
end)

CreateThread(function()
	while true do
		local tickTimeout = 5000


		if currentMissionBlip and gRequestCoords then
			local requestCoords = gRequestCoords
			if requestCoords then
				local playerPed = PlayerPedId()
				local playerCoords = GetEntityCoords( playerPed )
				
				local dist = #(requestCoords - playerCoords)

				if dist <= 3 then
					TriggerServerEvent("law:common:currentMissionHasBeenResolved")
				end
			end
		end

		Wait( tickTimeout )
	end
end)

AddEventHandler("onResourceStop", function(resName)
    if resName == GetCurrentResourceName() then
		deleteBlip()
    end
end)