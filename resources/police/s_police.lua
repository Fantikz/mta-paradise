local jailTimers = {} -- just to make sure all timers are deleted (might be useless to table timers atm)
local jailDebug = true

local function setArrestTimer( jailPlayer, isFreshman )
	if not isElement( jailPlayer ) then
		return false, "Player not an element."
	end
	
	local jailJSON = getPlayerArrest( getPlayerName( jailPlayer ):gsub( "_", " " ) )
	if getArrestLeftTime( jailPlayer ) == jailJSON[3] then
		exports.sql:query_free( "UPDATE characters SET jail = '%s' WHERE characterName = '%s'", toJSON( { 0, "", 0, 0, 0, 0, 0 } ), getPlayerName( jailPlayer ):gsub( "_", " ") )
		setElementPosition( jailPlayer, jails[ jailJSON[1] ].relX, jails[ jailJSON[1] ].relY, jails[ jailJSON[1] ].relZ )
		setElementInterior( jailPlayer, jails[ jailJSON[1] ].interiorR )
		setElementDimension( jailPlayer, jails[ jailJSON[1] ].dimensionR )
		setElementRotation( jailPlayer, 0, 0, jails[ jailJSON[1] ].rotZR )
		removeElementData( jailPlayer, "police:jail" )
		
		if jailTimers[ jailPlayer ] then
			if isTimer( jailTimers[ jailPlayer ] ) then
				killTimer( jailTimers[ jailPlayer ] )
			end
			jailTimers[ jailPlayer ] = nil
		end
		
		outputChatBox( " You have served your time in prison.", jailPlayer, 20, 245, 20, false )
	else
		local updateJSON = toJSON( { jailJSON[1], jailJSON[2], jailJSON[3], jailJSON[4], jailJSON[5], jailJSON[6], isFreshman and jailJSON[7] or jailJSON[7]+1 } )
		exports.sql:query_free( "UPDATE characters SET jail = '%s' WHERE characterName = '%s'", updateJSON, getPlayerName( jailPlayer ):gsub( "_", " ") )
		setElementData( jailPlayer, "police:jail", updateJSON, false )
		
		if jailTimers[ jailPlayer ] then
			if isTimer( jailTimers[ jailPlayer ] ) then
				killTimer( jailTimers[ jailPlayer ] )
			end
			jailTimers[ jailPlayer ] = nil
		end
		
		jailTimers[ jailPlayer ] = setTimer( setArrestTimer, 60000, 1, jailPlayer )
		outputChatBox( getArrestLeftTime( jailPlayer ), jailPlayer )
	end
	
	return true
end

addEventHandler("onResourceStart", resourceRoot,
	function( )
		local query = exports.sql:query_assoc( "SELECT jail, characterName FROM characters ORDER BY characterID ASC" )
		if query then
			local count = 0
			for _, row in ipairs( query ) do
				for _, player in ipairs( getElementsByType ( "player" ) ) do
					if getPlayerName( player ):gsub( "_", " " ) == row.characterName then
						local jailID = fromJSON( row.jail )[1]
						if jailID ~= 0 then
							count = count+1
							setElementPosition( player, jails[ jailID ].posX2, jails[ jailID ].posY2, jails[ jailID ].posZ2, true )
							setElementInterior( player, jails[ jailID ].interior2 )
							setElementDimension( player, jails[ jailID ].dimension2 )
							setElementRotation( player, 0, 0, jails[ jailID ].rotZ2 )
							setElementData( player, "police:jail", row.jail, false )
							setArrestTimer( player, true )
							outputChatBox( " Your jail session was refreshed and your position has been reset.", player, 20, 245, 20, false )
						end
					end
				end
			end
			
			if jailDebug then
				outputDebugString( "Loaded and refreshed jailed characters from database (jailed " .. count .. " characters).", 3 )
			end
		else
			if jailDebug then
				outputDebugString( "Couldn't load jailed characters from database.", 2 )
			end
		end
	end
)

function setPlayerArrested( jailPlayer, jailID, jailReason, jailTime, jailFine, jailSource )
	local jailID, jailTime, jailFine, jailSource = tonumber( jailID ), tonumber( jailTime ), tonumber( jailFine )
	
	if not isElement( jailPlayer ) or not jailID or not jailReason or not jailTime or not jailFine then
		return false, "Invalid data passed in."
	end
	
	if not jails[ jailID ] then
		return false, "Invalid jail ID passed in, got \"" .. tostring( jailID ) .. "\"."
	end
	
	local jailTime, jailFine = math.max( jailTime, 0 ), math.max( jailFine, 0 )
	local jailJSON = toJSON( { jailID, jailReason, jailTime, jailFine, isElement( jailSource ) and getCharacterID( jailSource ) or 0, exports.players:getTimestamp( ) } )
	
	if exports.sql:query_free( "UPDATE characters SET jail = '%s' WHERE id = '%s'", jailJSON, exports.players:getCharacterID( jailPlayer )) then
		setElementPosition( jailPlayer, jails[ jailID ].posX2, jails[ jailID ].posY2, jails[ jailID ].posZ2, true )
		setElementInterior( jailPlayer, jails[ jailID ].interior2 )
		setElementDimension( jailPlayer, jails[ jailID ].dimension2 )
		setElementRotation( jailPlayer, 0, 0, jails[ jailID ].rotZ2 )
		setElementData( jailPlayer, "police:jail", jailJSON, false )
		setArrestTimer( jailPlayer, true )
		return true
	end
	
	return false, "Database query failed when arresting."
end

function isPlayerArrested( character )
	if not character then
		return false, "Invalid character name/player element passed in."
	end
	
	local info = exports.sql:query_assoc_single( "SELECT jail FROM characters WHERE characterName = '%s'", isElement( character ) and getPlayerName( character ):gsub( "_", " " ) or tostring( character ) )
	local characterName = tostring( character )
	
	if isElement( character ) then
		characterName = getPlayerName( character ):gsub( "_", " " )
	end
	
	if info then
		local jailJSON = fromJSON( info )
		if jailJSON[1] ~= 0 then
			for _, player in ipairs( getElementsByType( "player" ) ) do
				if getPlayerName( player ):gsub( "_", " " ) == characterName then
					return true, true
				end
			end
			return true, false
		end
	end
	
	return false, "Character not found."
end

function getPlayerArrest( character )
	if not character then
		return false, "Invalid character name/player element passed in."
	end
	
	local info = exports.sql:query_assoc_single( "SELECT jail FROM characters WHERE characterName = '%s'", isElement( character ) and getPlayerName( character ):gsub( "_", " " ) or tostring( character ) )
	if info then
		local jailJSON = fromJSON( info.jail )
		if jailJSON[1] ~= 0 then
			return jailJSON
		end
	end
	
	return false, "Character not found."
end

function getArrestLeftTime( character )
	if not character then
		return false, "Invalid character name/player element passed in."
	end
	
	local arrestData = getPlayerArrest( character )
	if arrestData then
		return arrestData[3] - arrestData[7]
	end
	
	return false, "Data not found or isn't jailed."
end