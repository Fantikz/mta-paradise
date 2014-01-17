-- addCommandHandler supporting arrays as command names (multiple commands with the same function)
local addCommandHandler_ = addCommandHandler
      addCommandHandler  = function( commandName, fn, restricted, caseSensitive )
	-- add the default command handlers
	if type( commandName ) ~= "table" then
		commandName = { commandName }
	end
	for key, value in ipairs( commandName ) do
		if key == 1 then
			addCommandHandler_( value, fn, restricted, caseSensitive )
		else
			addCommandHandler_( value,
				function( player, ... )
					-- check if he has permissions to execute the command, default is not restricted (aka if the command is restricted - will default to no permission; otherwise okay)
					if hasObjectPermissionTo( player, "command." .. commandName[ 1 ], not restricted ) then
						fn( player, ... )
					end
				end
			)
		end
	end
end

addCommandHandler( "arrest",
	function( player, commandName, otherPlayer, jailTime, jailFine, ... )
		local isInFaction, factionID, _, _, leader = exports.factions:isPlayerInFactionType( player, "police" )
		if not isInFaction then
			outputChatBox( "You have to be part of a police faction in order to arrest someone.", player, 245, 20, 20, false )
			return
		end
		
		local jailTime = tonumber( jailTime )
		local jailFine = tonumber( jailFine )
		
		if not otherPlayer or not jailTime or jailTime < jailSettings.mintime or not jailFine or jailFine < jailSettings.minfine or not ( ... ) then
			outputChatBox( "Syntax: /" .. commandName .. " [player] [time] [fine] [reason]", player, 255, 255, 255, false )
			return
		end
		
		local jailTime = math.min( math.ceil( jailTime ), jailSettings.maxtime ) == 0 and 1 or math.min( math.ceil( jailTime ), jailSettings.maxtime )
		local jailFine = math.min( math.ceil( jailFine ), jailSettings.maxfine )
		local other, name = exports.players:getFromName( player, otherPlayer )
		
		if other then
			if other == player then
				local isInFaction2, factionID2, _, _, leader2 = exports.factions:isPlayerInFactionType( other, "police" )
				if isInFaction2 then -- and factionID2 == factionID -- to check if in the same faction as well
					if leader < leader2 then
						outputChatBox( "Only a police faction leader can arrest players within a police faction.", player, 245, 20, 20, false )
						return
					end
				end
				
				local x, y, z = getElementPosition( player )
				local interior, dimension = getElementInterior( player ), getElementDimension( player )
				
				local x2, y2, z2 = getElementPosition( other )
				local interior2, dimension2 = getElementInterior( other ), getElementDimension( other )
				
				if interior == interior2 and dimension == dimension2 and getDistanceBetweenPoints2D( x, y, x2, y2 ) < 2 then
					for jailID, jail in ipairs( jails ) do
						if jail.interior == interior and jail.dimension == dimension and getDistanceBetweenPoints2D( x, y, jail.posX, jail.posY ) < jailSettings.maxdist then
							local jailReason = table.concat({...}, " ")
							if arrestPlayer( other, jailID, jailReason, jailTime, jailFine, exports.players:getCharacterID( player ) ) then
								exports.factions:sendMessageToFaction( factionID, getPlayerName( player ):gsub( "_", " ") .. " arrested " .. name .. " (time to serve: " .. jailTime .. ", fine to pay: " .. jailFine .. ").", 110, 120, 210, false )
								exports.factions:sendMessageToFaction( factionID, "  Arrest reason: " .. jailReason, 110, 120, 210, false )
								return
							else
								outputChatBox( "Something went wrong.", player, 245, 20, 20, false )
								return
							end
						end
					end
					outputChatBox( "Get closer to a cell door to do that.", player, 245, 20, 20, false )
				else
					outputChatBox( "The arrestee has to be closer to you in order for you to arrest them.", player, 245, 20, 20, false )
				end
			else
				outputChatBox( "You cannot arrest yourself.", player, 245, 20, 20, false )
			end
		else
			outputChatBox( "Player not found.", player, 245, 20, 20, false )
		end
	end
)

addCommandHandler( "unjail",
	function( player, commandName, otherPlayer )
		local isInFaction, factionID, _, _, leader = exports.factions:isPlayerInFactionType( player, "police" )
		if not isInFaction then
			outputChatBox( "You have to be part of a police faction in order to unjail someone.", player, 245, 20, 20, false )
			return
		end
		
		if not otherPlayer then
			outputChatBox( "Syntax: /" .. commandName .. " [player]", player, 255, 255, 255, false )
			return
		end
		
		local other, name = exports.players:getFromName( player, otherPlayer )
		
		if other then
			if other == player then
				if isPlayerArrested( other ) then
					local isInFaction2, factionID2, _, _, leader2 = exports.factions:isPlayerInFactionType( other, "police" )
					if isInFaction2 then -- and factionID2 == factionID -- to check if in the same faction as well
						if leader < leader2 then
							outputChatBox( "Only a police faction leader can unjail players within a police faction.", player, 245, 20, 20, false )
							return
						end
					end
					
					local x, y, z = getElementPosition( player )
					local interior, dimension = getElementInterior( player ), getElementDimension( player )
					
					local x2, y2, z2 = getElementPosition( other )
					local interior2, dimension2 = getElementInterior( other ), getElementDimension( other )
					
					if interior == interior2 and dimension == dimension2 and getDistanceBetweenPoints2D( x, y, x2, y2 ) < 2 then
						for jailID, jail in ipairs( jails ) do
							if jail.interior == interior and jail.dimension == dimension and getDistanceBetweenPoints2D( x, y, jail.posX, jail.posY ) < jailSettings.maxdist then
								if unjailPlayer( other, jailID ) then
									exports.factions:sendMessageToFaction( factionID, getPlayerName( player ):gsub( "_", " ") .. " unjailed " .. name .. ".", 110, 120, 210, false )
									return
								else
									outputChatBox( "Something went wrong.", player, 245, 20, 20, false )
									return
								end
							end
						end
						outputChatBox( "Get closer to a cell door to do that.", player, 245, 20, 20, false )
					else
						outputChatBox( "The arrestee has to be closer to you in order for you to unjail them.", player, 245, 20, 20, false )
					end
				else
					outputChatBox( "That player isn't jailed.", player, 245, 20, 20, false )
				end
			else
				outputChatBox( "You cannot unjail yourself.", player, 245, 20, 20, false )
			end
		else
			outputChatBox( "Player not found.", player, 245, 20, 20, false )
		end
	end
)