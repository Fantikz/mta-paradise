--[[
Copyright (c) 2010 MTA: Paradise

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
]]

addEventHandler( "onResourceStart", resourceRoot,
	function( )
		if not exports.sql:create_table( 'phones',
			{
				{ name = 'phoneNumber', type = 'int(10) unsigned', primary_key = true, auto_increment = 100000 },
			} ) then cancelEvent( ) return end
	end
)

-- we need to export a function to generate a new (unused) phone number, really
function createPhone( number )
	if not number then
		number = exports.sql:query_insertid( "INSERT INTO phones VALUES ()" );
	else
		-- we create a row for the one that didn't exist yet but where we have the number for.
		local highestNumber = exports.sql:query_assoc_single( "SELECT MAX(phoneNumber) AS max FROM phones" )
		if highestNumber then
			if highestNumber.max == nil or number == highestNumber.max + 1 then
				-- no current phones OR the new phone number is the new max.
				return createPhone( )
			elseif number < highestNumber.max then
				-- we have a phone number that's below the maximum
				if not exports.sql:query_free( "INSERT INTO phones (phoneNumber) VALUES (" .. number .. ")" ) then
					 -- if this fails, the phone number does exist
					return false
				end
			else
				-- number is too high, ignore
				return false
			end
		else
			return createPhone( )
		end
	end
	return number -- we don't want to return the MySQL error if that failed
end

--

local function findFromPhoneBook( number, name )
	for number, content in pairs( services ) do
		for _, serviceName in ipairs( services.names ) do
			if name:lower( ) == serviceName:lower( ) then
				return number
			end
		end
	end
	-- TODO: this should once in near future return the number associated to a certain name in the phone book - implies we have a phone book
	return false
end

local function findInPhoneBook( number, otherNumber )
	if services[ otherNumber ] then
		return services[ otherNumber ].names[1]
	end
	-- TODO: this should once in near future return the name of the phonebook entry assigned to that number - implies we have a phone book
	return false
end

--

local p = { }

--[[
Quick Guide
-----------
	type		effect
	
	function	executes the function, uses the first return value to determinate whetever to continue the call (true) or not (false),
				all return values beyond that are messages shown to the player.
				parameters for this are the player who calls, his phone number and the past input of this call.
	bool(true)	waits for the player input (/p)
	text		Show that message to the player

]]

local function getTaxiDrivers( )
	if getResourceFromName( "job-taxi" ) and getResourceState( getResourceFromName( "job-taxi" ) ) then
		return exports["job-taxi"]:getDrivers( ) or { }
	end
	return { }
end

local function getEmergencyServices( )
	local personnel = { }
	for i,player in ipairs( getElementsByType( "player" ) ) do
		if exports.factions:isPlayerInFactionType( player, "police" ) or exports.factions:isPlayerInFactionType( player, "medical" ) then
			table.insert(personnel, player)
		end
	end
	return personnel
end

services =
{
	[222] =
	{
		names = {
			[1] = "Cab",
			[2] = "Taxi"
		},
		function( player, phoneNumber, input )
			local drivers = getTaxiDrivers( )
			if #drivers > 0 then
				return true, "SF Cab Operator says: Welcome to San Fierro Cabs! Please state your location."
			else
				return false, "SF Cab Operator says: There are currently no Taxis available. Call later!"
			end	
		end,
		true,
		function( player, phoneNumber, input )
			local drivers = getTaxiDrivers( )
			if #drivers > 0 then
				for key, value in ipairs( drivers ) do
					exports.chat:me( value, "receives a text message." )
					outputChatBox( "SMS from ((" .. getPlayerName( player ):gsub( "_", " " ) .. ")) SF Cabs: Fare - Phone #" .. phoneNumber .. " - Location: " .. input[1], value, 130, 255, 130 )
					triggerClientEvent( value, "gui:hint", value, "Your Job: Taxi Driver - New Fare", "Someone needs a Cab:\nPhone: #" .. phoneNumber .. " (( " .. getPlayerName( player ):gsub( "_", " " ) .. " ))\nLocation: " .. input[1] )
				end
				return false, "SF Cab Operator says: We've dispatched a cab to your location. It should arrive soon!"
			else
				return false, "SF Cab Operator says: There are currently no Taxis available. Call later!"
			end
		end
	},
	[911] =
	{
		names = {
			[1] = "Emergency",
			[2] = "Help",
			[3] = "Fire",
			[4] = "Police",
			[5] = "Ambulance",
			[6] = "Medic"
		},
		function( player, phoneNumber, input )
			local drivers = getEmergencyServices( )
			if #drivers > 0 then
				return true, "Emergency Operator says: 9-1-1, what's your emergency?"
			else
				return false, "Emergency Operator says: Our lines are currently flooded. Please try again later."
			end	
		end,
		true,
		function( player, phoneNumber, input )
			local drivers = getEmergencyServices( )
			if #drivers > 0 then
				return true, "Emergency Operator says: Could you tell me your location?"
			else
				return false, "Emergency Operator says: Our lines are currently flooded. Please try again later."
			end	
		end,
		true,
		function( player, phoneNumber, input )
			local drivers = getEmergencyServices( )
			if #drivers > 0 then
				for key, value in ipairs( drivers ) do
					outputChatBox( "[RADIO] This is dispatch, we've received an emergency call from #" .. phoneNumber .. " with these details.", value, 120, 140, 210, false )
					outputChatBox( "[RADIO] Description: " .. input[1], value, 120, 140, 210, false )
					outputChatBox( "[RADIO] Location: " .. input[2], value, 120, 140, 210, false )
					triggerClientEvent( value, "gui:hint", value, "Emergency Call Received", "Someone needs immediate assistance!\nLocation: " .. input[1] .. "\nDescription: " .. input[2] )
				end
				return false, "Emergency Operator Operator says: We've dispatched a unit to your location. It should arrive soon!"
			else
				return false, "Emergency Operator says: Our lines are currently flooded. Please try again later."
			end
		end
	}
}

local function advanceService( player, text )
	local call = p[ player ]
	if call.service then
		local state = services[ call.service ][ call.serviceState ]
		if state then
			if text then
				if type( state ) == "boolean" then
					exports.chat:localizedMessage( player, " [Cellphone] " .. getPlayerName( player ):gsub( "_", " " ) .. " says: ", text, 255, 255, 255)
					table.insert( call.input, text )
					call.serviceState = call.serviceState + 1
					advanceService( player )
				end
			else
				if type( state ) == "function" then
					local ret = { state( player, call.number, call.input ) }
					if #ret >= 2 then
						for i = 2, #ret do
							outputChatBox( ret[ i ], player, 180, 255, 180 )
						end
					end
					if ( #ret >= 1 and ret[1] == false ) or #ret == 0 then
						outputChatBox( "They hung up.", player, 180, 255, 180 )
						p[ player ] = nil
						return
					end
				elseif type( state ) == "string" then
					outputChatBox( state, player, 180, 255, 180 )
				elseif type( state ) == "boolean" then
					return -- we need to stop here to prevent us from getting too far.
				end
				call.serviceState = call.serviceState + 1
				advanceService( player )
			end
		else
			outputChatBox( "They hung up.", player, 180, 255, 180 )
			p[ player ] = nil
			return
		end
	end
end

--

addCommandHandler( "call",
	function( player, commandName, ownNumber, otherNumber )
		if exports.players:isLoggedIn( player ) then
			if tonumber( ownNumber ) and otherNumber and exports.items:has( player, 7, tonumber( ownNumber ) ) then
				ownNumber = tonumber( ownNumber )
			else
				local has, key, item = exports.items:has( player, 7 )
				if has then
					otherNumber = ownNumber
					ownNumber = item.value
				else
					outputChatBox( "(( You do not have a phone. ))", player, 255, 0, 0 )
				end
			end
			
			local otherNumber = tonumber( otherNumber ) or findFromPhoneBook( ownNumber, otherNumber )
			if ownNumber and otherNumber then
				if ownNumber == otherNumber then
					outputChatBox( "You can't call yourself.", player, 255, 0, 0 )
				else
					local ownPhone = { exports.items:has( player, 7, ownNumber ) }
					exports.chat:me( player, "takes out a " .. ( ownPhone[3].name or "cellphone" ) .. " and taps a few buttons on it." )
					
					if services[ otherNumber ] then
						p[ player ] = { other = false, service = otherNumber, number = ownNumber, state = 2, input = { }, serviceState = 1 }
						advanceService( player )
						return
					else
						for key, value in ipairs( getElementsByType( "player" ) ) do
							if value ~= player then
								local otherPhone = { has( value, 7, otherNumber ) }
								if otherPhone and otherPhone[1] then
									p[ player ] = { other = value, number = ownNumber, state = 0 }
									p[ value ] = { other = player, number = otherNumber, state = 0 }
								
									exports.chat:me( value, "'s " .. ( otherPhone[3].name or "phone" ) .. " starts to ring." )
									outputChatBox( "The phone's display shows " .. ( findInPhoneBook( otherNumber, ownNumber ) or ( "#" .. ownNumber ) ) .. ". (( /pickup to pick up. ))", value, 180, 255, 180 )
									return
								end
							end
						end
					end
					-- TODO: if the phone is a dropped item, a menu for picking up/hanging up would be nice. and an actual check if it is
					
					outputChatBox( "You hear a dead tone.", player, 255, 0, 0 )
				end
			else
				outputChatBox( "Syntax: /call [number] or /call [your number] [other number]", player, 255, 255, 255 )
			end
		end
	end
)

addCommandHandler( "pickup" ,
	function( player )
		if p[ player ] and p[ player ].state == 0 then
			exports.chat:me( player, "answers their phone." )
			outputChatBox( "They picked up. (( /p to talk ))", p[ player ].other, 180, 255, 180 )
			
			p[ p[ player ].other ].state = 1
			p[ player ].state = 1
		else
			outputChatBox( "You are not on a call.", player, 255, 0, 0 )
		end
	end
)

addCommandHandler( "p" ,
	function( player, commandName, ... )
		if ( ... ) then
			if p[ player ] then
				local message = table.concat( { ... }, " " )
				if p[ player ].state == 1 then
					outputChatBox( "((You)) " .. ( findInPhoneBook( p[ player ].number, p[ p[ player ].other ].number ) or ( "#" .. p[ p[ player ].other ].number ) ) .. " said: " .. message, player, 180, 255, 180 )
					outputChatBox( "((" .. getPlayerName( player ):gsub( "_", " " ) .. ")) " .. ( findInPhoneBook( p[ p[ player ].other ].number, p[ player ].number ) or ( "#" .. p[ player ].number ) ) .. " says: " .. message, p[ player ].other, 180, 255, 180 )
				elseif p[ player ].state == 2 then
					advanceService( player, message )
				end
			else
				outputChatBox( "You are not on a call.", player, 255, 0, 0 )
			end
		else
			outputChatBox( "Syntax: /" .. commandName .. " [text] - talks into your phone.", player, 255, 255, 255 )
		end
	end
)

addCommandHandler( "hangup" ,
	function( player )
		if p[ player ] then
			outputChatBox( "You hung up.", player, 180, 255, 180 )
			outputChatBox( "They hung up.", p[ player ].other, 180, 255, 180 )
			
			p[ p[ player ].other ] = nil
			p[ player ] = nil
		else
			outputChatBox( "You are not on a call.", player, 255, 0, 0 )
		end
	end
)

addEventHandler( "onPlayerQuit", root,
	function( )
		if p[ source ] then
			outputChatBox( "Your phone lost the connection...", player, 255, 0, 0 )
			p[ p[ source ].other ] = nil
			p[ source ] = nil
		end
	end
)
addEventHandler( "onCharacterLogout", root,
	function( )
		if p[ source ] then
			outputChatBox( "Your phone lost the connection...", player, 255, 0, 0 )
			p[ p[ source ].other ] = nil
			p[ source ] = nil
		end
	end
)

--

addCommandHandler( "sms",
	function( player, commandName, ownNumber, other, ... )
		if exports.players:isLoggedIn( player ) then
			local args = { ... }
			local ownNumber = tonumber( ownNumber )
			local otherNumber = tonumber( other ) or findFromPhoneBook( ownNumber, other )
			if ownNumber and otherNumber and exports.items:has( player, 7, ownNumber ) then
				-- do nothing?
			else
				local has, key, item = exports.items:has( player, 7 )
				if has then
					table.insert( args, 1, other )
					
					otherNumber = ownNumber
					ownNumber = item.value
				else
					outputChatBox( "(( You do not have a phone. ))", player, 255, 0, 0 )
				end
			end
			
			local message = table.concat( args, " " )
			if ownNumber and otherNumber and message then
				if ownNumber == otherNumber then
					outputChatBox( "You can't write messages to yourself.", player, 255, 0, 0 )
				else
					exports.chat:me( player, "writes a text message." )
					outputChatBox( "SMS to " .. ( findInPhoneBook( ownNumber, otherNumber ) or ( "#" .. otherNumber ) ) .. ": " .. message, player, 130, 255, 130 )
					
					for key, value in ipairs( getElementsByType( "player" ) ) do
						local otherPhone = { has( value, 7, otherNumber ) }
						if otherPhone and otherPhone[1] then
							exports.chat:me( value, "receives a text message." )
							outputChatBox( "SMS from ((" .. getPlayerName( player ):gsub( "_", " " ) .. ")) " .. ( findInPhoneBook( otherNumber, ownNumber ) or ( "#" .. ownNumber ) ) .. ": " .. message, value, 130, 255, 130 )
							return
						end
					end
					
					outputChatBox( "((Automated Message)) The recipient is currently not available.", player, 130, 255, 130 )
				end
			else
				outputChatBox( "Syntax: /sms [number] [text] or /call [your number] [other number] [text]", player, 255, 255, 255 )
			end
		end
	end
)

--

addEventHandler( "onResourceStop", resourceRoot,
	function( )
		for player, data in pairs( p ) do
			if data.state == 1 or data.state == 2 then -- on a call
				outputChatBox( "Your phone lost the connection...", player, 255, 0, 0 )
			end
		end
		p = { }
	end
)
