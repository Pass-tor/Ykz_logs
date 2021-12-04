

Citizen.CreateThread(function()
	local DeathReason, Killer, DeathCauseHash, Weapon

	while true do
		Citizen.Wait(0)
		if IsEntityDead(GetPlayerPed(PlayerId())) then
			Citizen.Wait(0)
			local PedKiller = GetPedSourceOfDeath(GetPlayerPed(PlayerId()))
			local killername = GetPlayerName(PedKiller)
			DeathCauseHash = GetPedCauseOfDeath(GetPlayerPed(PlayerId()))
			Weapon = ClientWeapons.WeaponNames[tostring(DeathCauseHash)]

			if IsEntityAPed(PedKiller) and IsPedAPlayer(PedKiller) then
				Killer = NetworkGetPlayerIndexFromPed(PedKiller)
			elseif IsEntityAVehicle(PedKiller) and IsEntityAPed(GetPedInVehicleSeat(PedKiller, -1)) and IsPedAPlayer(GetPedInVehicleSeat(PedKiller, -1)) then
				Killer = NetworkGetPlayerIndexFromPed(GetPedInVehicleSeat(PedKiller, -1))
			end

			if (Killer == PlayerId()) then
				DeathReason = 'committed suicide'
			elseif (Killer == nil) then
				DeathReason = 'died'
			else
				if ClientFunc.IsMelee(DeathCauseHash) then
					DeathReason = 'murdered'
				elseif ClientFunc.IsTorch(DeathCauseHash) then
					DeathReason = 'torched'
				elseif ClientFunc.IsKnife(DeathCauseHash) then
					DeathReason = 'knifed'
				elseif ClientFunc.IsPistol(DeathCauseHash) then
					DeathReason = 'pistoled'
				elseif ClientFunc.IsSub(DeathCauseHash) then
					DeathReason = 'riddled'
				elseif ClientFunc.IsRifle(DeathCauseHash) then
					DeathReason = 'rifled'
				elseif ClientFunc.IsLight(DeathCauseHash) then
					DeathReason = 'machine gunned'
				elseif ClientFunc.IsShotgun(DeathCauseHash) then
					DeathReason = 'pulverized'
				elseif ClientFunc.IsSniper(DeathCauseHash) then
					DeathReason = 'sniped'
				elseif ClientFunc.IsHeavy(DeathCauseHash) then
					DeathReason = 'obliterated'
				elseif ClientFunc.IsMinigun(DeathCauseHash) then
					DeathReason = 'shredded'
				elseif ClientFunc.IsBomb(DeathCauseHash) then
					DeathReason = 'bombed'
				elseif ClientFunc.IsVeh(DeathCauseHash) then
					DeathReason = 'mowed over'
				elseif ClientFunc.IsVK(DeathCauseHash) then
					DeathReason = 'flattened'
				else
					DeathReason = 'killed'
				end
			end

			if DeathReason == 'committed suicide' or DeathReason == 'died' then
				TriggerServerEvent('Pastor:playerDied', {
					type = 1, 
					player_id = GetPlayerServerId(PlayerId()), 
					death_reason = DeathReason, 
					weapon = Weapon
				})
			else
				TriggerServerEvent('Pastor:playerDied', {
					type = 2, 
					player_id = GetPlayerServerId(PlayerId()), 
					player_2_id = GetPlayerServerId(Killer), 
					death_reason = DeathReason, 
					weapon = Weapon
				})
			end
			Killer = nil
			DeathReason = nil
			DeathCauseHash = nil
			Weapon = nil
		end
		while IsEntityDead(PlayerPedId()) do
			Citizen.Wait(0)
		end
	end
end)

RegisterNetEvent('Pastor:ClientCreateScreenshot')
AddEventHandler('Pastor:ClientCreateScreenshot', function(args)
    exports['screenshot-basic']:requestScreenshotUpload(args.url, 'files[]', function(data)
        local resp = json.decode(data)
		args['responseUrl'] = resp.attachments[1].url
        TriggerServerEvent('Pastor:ClientUploadScreenshot', args)
    end)
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local playerped = GetPlayerPed(PlayerId())
		if IsPedShooting(playerped) then
			if ClientWeapons.WeaponNames[tostring(GetSelectedPedWeapon(playerped))] then
				local configFile = LoadResourceFile(GetCurrentResourceName(), "config/config.json")
				local cfgFile = json.decode(configFile)
				isLoggedWeapon = true
				for k,v in pairs(cfgFile['WeaponsNotLogged']) do
				   	if GetSelectedPedWeapon(playerped) == GetHashKey(v) then
						isLoggedWeapon = false
					end
				end
				if isLoggedWeapon then
					TriggerServerEvent('Pastor:playerShotWeapon', ClientWeapons.WeaponNames[tostring(GetSelectedPedWeapon(playerped))])
				end				
			else
				TriggerServerEvent('Pastor:playerShotWeapon', 'Undefined')
				TriggerServerEvent('Pastor:Ykz_logs:Debug', 'Weapon not defined.', "Weapon not listed: "..tostring(GetSelectedPedWeapon(playerped)))
			end
		end
	end
end)

exports('discord', function(message, id, id2, color, channel)
	args ={
		['EmbedMessage'] = msg,
		['color'] = color,
		['channel'] = channel
	}
	if player_1 ~= 0 then
		args['player_id'] = player_1
	end
	if player_2 ~= 0 then
		args['player_2_id'] = player_2
	end
	TriggerServerEvent('Pastor:ClientDiscord', args)
	local resource = GetInvokingResource()
	TriggerServerEvent('Pastor:Ykz_logs:Debug', 'Server Old Export from '..resource)
end)

exports('createLog', function(args)
	TriggerServerEvent('Pastor:ClientDiscord', args)	
	local resource = GetInvokingResource()
	TriggerServerEvent('Pastor:Ykz_logs:Debug', 'Server New Export from '..resource)
end)

local clientStorage = {}
RegisterNetEvent('Pastor:ClientLogStorage')
AddEventHandler('Pastor:ClientLogStorage', function(args)
    if tablelength(clientStorage) <= 4 then
		table.insert(clientStorage, args)
	else
		table.remove(clientStorage, 1)
		table.insert(clientStorage, args)
	end
end)

RegisterNetEvent('Pastor:getClientLogStorage')
AddEventHandler('Pastor:getClientLogStorage', function()
    TriggerServerEvent('Pastor:sendClientLogStorage', clientStorage)
end)

local eventsLoadFile = LoadResourceFile(GetCurrentResourceName(), "config/eventLogs.json")
local eventsFile = json.decode(eventsLoadFile)
if type(eventsFile) == "table" then
	for k,v in pairs(eventsFile) do
		if not v.Server then
			TriggerServerEvent('Pastor:Ykz_logs:Debug', 'Added Client Event Log: '..v.Event)
			AddEventHandler(v.Event, function()
				ServerFunc.CreateLog({EmbedMessage = 'EventLogger: '..v.Message, channel = v.Channel})
				TriggerServerEvent('Pastor:eventLoggerClient', {EmbedMessage = 'EventLogger: '..v.Message, channel = v.Channel})
			end)
		end
	end
end

function tablelength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

TriggerEvent("chat:addSuggestion", "/logs", "See the recent 5 logs of a player.", {
	{ name="id", help="The id of the player." }
});