

local Ykz_Debug = false -- Enable when you have issues or when asked by Pastor Staff

RegisterNetEvent('Pastor:Ykz_logs:Debug')
AddEventHandler('Pastor:Ykz_logs:Debug', log)

RegisterNetEvent('Pastor:Ykz_logs:errorLog')
AddEventHandler('Pastor:Ykz_logs:errorLog', errorLog)

function debugLog(x)
	if Ykz_Debug then
		print("^5[Ykz_logs]^0 " .. x)
	end
end

function errorLog(x)
	print("^5[Ykz_logs]^1 " .. x .."^0")
end

RegisterNetEvent("Pastor:discordLogs")
AddEventHandler("Pastor:discordLogs", function(message, color, channel)
    discordLog(message, color, channel)
end)

RegisterNetEvent("Pastor:ClientUploadScreenshot")
AddEventHandler("Pastor:ClientUploadScreenshot", function(args)
	ServerFunc.CreateLog(args)
end)

exports('discord', function(msg, player_1, player_2, color, channel)
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
	ServerFunc.CreateLog(args)
	local resource = GetInvokingResource()
	debugLog('Server Old Export from '.. resource)
end)

exports('createLog', function(args)
	if args.screenshot then
		if GetResourceState('screenshot-basic') == "started" then
			local webhooksLaodFile = LoadResourceFile(GetCurrentResourceName(), "./config/webhooks.json")
			local webhooksFile = json.decode(webhooksLaodFile)
			args['url'] = webhooksFile['imageStore'].webhook
			TriggerClientEvent('Pastor:ClientCreateScreenshot', args.player_id, args)
		else
			errorLog('You need to have screenshot-basic to use screenshot logs.')
		end
	else
		ServerFunc.CreateLog(args)
	end
	local resource = GetInvokingResource()
	debugLog('Server New Export from: '..resource)
end)

-- Event Handlers
-- Send message when Player connects to the server.
AddEventHandler("playerConnecting", function(name, setReason, deferrals)
	ServerFunc.CreateLog({EmbedMessage = '**' ..GetPlayerName(source).. '** is connecting to the server.', player_id = source, channel = 'joins'})
end)

AddEventHandler("playerJoining", function(source, oldID)
	local loadFile = LoadResourceFile(GetCurrentResourceName(), "./json/names.json")
	local loadedFile = json.decode(loadFile)
	local configFile = LoadResourceFile(GetCurrentResourceName(), "./config/config.json")
	local cfgFile = json.decode(configFile)
    local ids = ExtractIdentifiers(source)

	if ids.steam then
		if loadedFile[ids.steam] ~= nil then 
			if loadedFile[ids.steam] ~= GetPlayerName(source) then 
				for _, i in ipairs(GetPlayers()) do
					if IsPlayerAceAllowed(i, cfgFile.nameChangePerms) then 
						TriggerClientEvent('chat:addMessage', i, {
							template = '<div style="background-color: rgba(90, 90, 90, 0.9); text-align: center; border-radius: 0.5vh; padding: 0.7vh; font-size: 1.7vh;"><b>Player ^1{0} ^0used to be named ^1{1}</b></div>',
							args = { GetPlayerName(source), loadedFile[ids.steam] }
						})
					end
				end
				ServerFunc.CreateLog({EmbedMessage = 'Player **' .. GetPlayerName(source) .. '** used to be named **' ..loadedFile[ids.steam]..'**', player_id = source, channel = 'nameChange'})
			end
		end
		loadedFile[ids.steam] = GetPlayerName(source)
		SaveResourceFile(GetCurrentResourceName(), "./json/names.json", json.encode(loadedFile), -1)
	else
		if cfgFile.forceSteam then
			ServerFunc.CreateLog({EmbedMessage = 'Disonnected player **' .. GetPlayerName(source) .. '** for not having steam active.', player_id = source, channel = 'nameChange'})
			DropPlayer(source, "Please start steam and reconnect to the server.")
		else
			for _, i in ipairs(GetPlayers()) do
				if IsPlayerAceAllowed(i, cfgFile.nameChangePerms) then 
					TriggerClientEvent('chat:addMessage', i, {
						template = '<div style="background-color: rgba(90, 90, 90, 0.9); text-align: center; border-radius: 0.5vh; padding: 0.7vh; font-size: 1.7vh;"><b>Player ^1{0} ^0is connecting wihout a steam id.</b></div>',
						args = { GetPlayerName(source) }
					})
				end
			end
			ServerFunc.CreateLog({EmbedMessage = 'Player **' .. GetPlayerName(source) .. '** does not have steam active and we can\'t log their name.', player_id = source, channel = 'nameChange'})
		end
	end
end)

-- Send message when Player disconnects from the server
AddEventHandler('playerDropped', function(reason)
	ServerFunc.CreateLog({EmbedMessage = '**' ..GetPlayerName(source).. '** has left the server. (Reason: ' .. reason .. ')', player_id = source, channel = 'leaving'})
end)

-- Send message when Player creates a chat message (Does not show commands)
AddEventHandler('chatMessage', function(source, name, msg)
	ServerFunc.CreateLog({EmbedMessage = '**'..GetPlayerName(source) .. '**: `' .. msg..'`', player_id = source, channel = 'chat'})
end)

-- Send message when Player died (including reason/killer check) (Not always working)
RegisterServerEvent('Pastor:playerDied')
AddEventHandler('Pastor:playerDied',function(args)
	if args.weapon == nil then _Weapon = "" else _Weapon = ""..args.weapon.."" end
	if args.type == 1 then  -- Suicide/died
		ServerFunc.CreateLog({
			EmbedMessage = '**'..GetPlayerName(source) .. '** `'..args.death_reason..'` '.._Weapon, 
			player_id = source,
			channel = 'deaths'
		})
	elseif args.type == 2 then -- Killed by other player
		ServerFunc.CreateLog({
			EmbedMessage = '**' .. GetPlayerName(args.player_2_id) .. '** '..args.death_reason..' **' .. GetPlayerName(source).. '** `('.._Weapon..')`', 
			player_id = source,
			player_2_id = args.player_2_id,
			channel = 'deaths'
		})
	else -- When gets killed by something else
		ServerFunc.CreateLog({
			EmbedMessage = '**'..GetPlayerName(source) .. '** `'..args.death_reason..'` '.._Weapon, 
			player_id = source,
			channel = 'deaths'
		})
	end
end)

-- Send message when Player fires a weapon
RegisterServerEvent('Pastor:playerShotWeapon')
AddEventHandler('Pastor:playerShotWeapon', function(weapon)
	local configLoadFile = LoadResourceFile(GetCurrentResourceName(), "./config/config.json")
	local configFile = json.decode(configLoadFile)
	if configFile['weaponLog'] then
		ServerFunc.CreateLog({EmbedMessage = '**' .. GetPlayerName(source)  .. '** fired a `' .. weapon .. '`', player_id = source, channel = 'shooting'})
    end
end)

local explosionTypes = {'GRENADE', 'GRENADELAUNCHER', 'STICKYBOMB', 'MOLOTOV', 'ROCKET', 'TANKSHELL', 'HI_OCTANE', 'CAR', 'PLANE', 'PETROL_PUMP', 'BIKE', 'DIR_STEAM', 'DIR_FLAME', 'DIR_WATER_HYDRANT', 'DIR_GAS_CANISTER', 'BOAT', 'SHIP_DESTROY', 'TRUCK', 'BULLET', 'SMOKEGRENADELAUNCHER', 'SMOKEGRENADE', 'BZGAS', 'FLARE', 'GAS_CANISTER', 'EXTINGUISHER', 'PROGRAMMABLEAR', 'TRAIN', 'BARREL', 'PROPANE', 'BLIMP', 'DIR_FLAME_EXPLODE', 'TANKER', 'PLANE_ROCKET', 'VEHICLE_BULLET', 'GAS_TANK', 'BIRD_CRAP', 'RAILGUN', 'BLIMP2', 'FIREWORK', 'SNOWBALL', 'PROXMINE', 'VALKYRIE_CANNON', 'AIR_DEFENCE', 'PIPEBOMB', 'VEHICLEMINE', 'EXPLOSIVEAMMO', 'APCSHELL', 'BOMB_CLUSTER', 'BOMB_GAS', 'BOMB_INCENDIARY', 'BOMB_STANDARD', 'TORPEDO', 'TORPEDO_UNDERWATER', 'BOMBUSHKA_CANNON', 'BOMB_CLUSTER_SECONDARY', 'HUNTER_BARRAGE', 'HUNTER_CANNON', 'ROGUE_CANNON', 'MINE_UNDERWATER', 'ORBITAL_CANNON', 'BOMB_STANDARD_WIDE', 'EXPLOSIVEAMMO_SHOTGUN', 'OPPRESSOR2_CANNON', 'MORTAR_KINETIC', 'VEHICLEMINE_KINETIC', 'VEHICLEMINE_EMP', 'VEHICLEMINE_SPIKE', 'VEHICLEMINE_SLICK', 'VEHICLEMINE_TAR', 'SCRIPT_DRONE', 'RAYGUN', 'BURIEDMINE', 'SCRIPT_MISSIL'}

AddEventHandler('explosionEvent', function(source, ev)
    if ev.explosionType < -1 or ev.explosionType > 77 then
        ev.explosionType = 'UNKNOWN'
    else
        ev.explosionType = explosionTypes[ev.explosionType + 1]
    end
    ServerFunc.CreateLog({EmbedMessage = '**' .. GetPlayerName(source)  .. '** created a explosion `' .. ev.explosionType .. '`', player_id = source, channel = 'explosion'})
end)

-- Getting exports from clientside
RegisterServerEvent('Pastor:ClientDiscord')
AddEventHandler('Pastor:ClientDiscord', function(args)
	if args.screenshot then
		if GetResourceState('screenshot-basic') == "started" then
			local webhooksLaodFile = LoadResourceFile(GetCurrentResourceName(), "./config/webhooks.json")
			local webhooksFile = json.decode(webhooksLaodFile)
			args['url'] = webhooksFile['imageStore'].webhook
			TriggerClientEvent('Pastor:ClientCreateScreenshot', args.player_id, args)
		else
			errorLog('You need to have screenshot-basic to use screenshot logs.')
		end
	else
		ServerFunc.CreateLog(args)
	end
end)

-- Send message when a resource is being stopped
AddEventHandler('onResourceStop', function (resourceName)
	ServerFunc.CreateLog({EmbedMessage = '**' .. resourceName .. '** has been stopped.', channel = 'resources'})
end)

-- Send message when a resource is being started
AddEventHandler('onResourceStart', function (resourceName)
    Citizen.Wait(100)
	ServerFunc.CreateLog({EmbedMessage = '**' .. resourceName .. '** has been started.', channel = 'resources'})
end)  

local storage = nil
RegisterNetEvent('Pastor:sendClientLogStorage')
AddEventHandler('Pastor:sendClientLogStorage', function(_storage)
	storage = _storage
end)

RegisterCommand('logs', function(source, args, RawCommand)
	local configFile = LoadResourceFile(GetCurrentResourceName(), "./config/config.json")
	local cfgFile = json.decode(configFile)
	if GetResourceState('Pastor_Notify') == "started" then
		if IsPlayerAceAllowed(source, cfgFile.logHistoryPerms) then
			if tonumber(args[1]) then
				TriggerClientEvent('Pastor:getClientLogStorage', args[1])
				Citizen.Wait(500)
				if tablelength(storage) == 0 then
					exports.Pastor_Notify:Notify({
						title = "Recent logs for: "..GetPlayerName(args[1]).." (0)",
						message = "No logs avalible.",
						color = "#93CAED",
						target = source,
						timeout = 15
					})
				else
					for k,v in pairs(storage) do
						exports.Pastor_Notify:Notify({
							title = "Recent logs for: "..GetPlayerName(args[1]).." ("..k..")",
							message = "Channel: "..v.Channel.."\nMessage: "..v.Message:gsub("**",""):gsub("`","").."\nTimeStamp: "..v.TimeStamp,
							color = "#93CAED",
							target = source,
							timeout = 15
						})
					end
				end
			else
				exports.Pastor_Notify:Notify({
					title = "Error!",
					message = "Invalid player ID",
					color = "#93CAED",
					target = source,
					timeout = 15
				})
			end
		else
			exports.Pastor_Notify:Notify({
				title = "Error!",
				message = "You don't have permission to use this command",
				color = "#93CAED",
				target = source,
				timeout = 15
			})
		end
	else
		errorLog('Pastor_Notify is not installed.')
	end
end)

RegisterCommand('screenshot', function(source, args, RawCommand)
	local configFile = LoadResourceFile(GetCurrentResourceName(), "./config/config.json")
	local cfgFile = json.decode(configFile)
	if GetResourceState('Pastor_Notify') == "started" then
		if IsPlayerAceAllowed(source, cfgFile.screenshotPerms) then
			if args[1] and has_val(GetPlayers(), args[1]) then
				if GetResourceState('screenshot-basic') == "started" then
					local webhooksLaodFile = LoadResourceFile(GetCurrentResourceName(), "./config/webhooks.json")
					local webhooksFile = json.decode(webhooksLaodFile)
					args['url'] = webhooksFile['imageStore'].webhook
					args['EmbedMessage'] = "**Screenshot of:** "..GetPlayerName(args[1]).." (ID: "..args[1]..")\n**Requested by:** "..GetPlayerName(source).." (ID: "..source..")"
					args['channel'] = "screenshot"
					TriggerClientEvent('Pastor:ClientCreateScreenshot', args[1], args)
					exports.Pastor_Notify:Notify({
						title = "Success!",
						message = "The screenshot of "..GetPlayerName(args[1]).." was posted on discord!",
						color = "#93CAED",
						target = source,
						timeout = 15
					})
				else
					errorLog('You need to have screenshot-basic to use screenshot logs.')
				end
			else
				exports.Pastor_Notify:Notify({
					title = "Error!",
					message = "The player ID provided is invalid or not a active player.",
					color = "#93CAED",
					target = source,
					timeout = 15
				})

			end
		else
			exports.Pastor_Notify:Notify({
				title = "Error!",
				message = "You don't have permission to use this command",
				color = "#93CAED",
				target = source,
				timeout = 15
			})
		end
	else
		errorLog('Pastor_Notify is not installed.')
	end
end)

function tablelength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

function has_val(tab, val)
	for k,v in pairs(tab) do
	   if v == val then
		return true
	   end
	end
	return false
end

local eventsLoadFile = LoadResourceFile(GetCurrentResourceName(), "config/eventLogs.json")
local eventsFile = json.decode(eventsLoadFile)
if type(eventsFile) == "table" then
	for k,v in pairs(eventsFile) do
		if v.Server then
			debugLog('Added Server Event Log: '..v.Event)
			AddEventHandler(v.Event, function()
				ServerFunc.CreateLog({EmbedMessage = '**EventLogger:** '..v.Message, channel = v.Channel})
			end)
		end
	end
end

RegisterServerEvent('Pastor:eventLoggerClient')
AddEventHandler('Pastor:eventLoggerClient', function(args)
	ServerFunc.CreateLog(args)
end)

if GetCurrentResourceName() ~= "Ykz_logs" then
    errorLog('This recource should be named "Ykz_logs" for the exports to work properly.')
end
