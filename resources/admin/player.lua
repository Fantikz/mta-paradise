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

--

addCommandHandler( "setskin",
	function( player, commandName, otherPlayer, skin )
		skin = tonumber( skin )
		if otherPlayer and skin then
			local other, name = exports.players:getFromName( player, otherPlayer )
			if other then
				local oldSkin = getElementModel( other )
				local characterID = exports.players:getCharacterID( other )
				if oldSkin == skin then
					outputChatBox( name .. " is already using that skin.", player, 255, 255, 0 )
				elseif characterID and setElementModel( other, skin ) then
					if exports.sql:query_free( "UPDATE characters SET skin = " .. skin .. " WHERE characterID = " .. characterID ) then
						outputChatBox( "Set " .. name .. "'s skin to " .. skin, player, 0, 255, 153 )
						exports.players:updateCharacters( other )
					else
						outputChatBox( "Failed to save skin.", player, 255, 0, 0 )
						setElementModel( other, oldSkin )
					end
				else
					outputChatBox( "Skin " .. skin .. " is invalid.", player, 255, 0, 0 )
				end
			end
		else
			outputChatBox( "Syntax: /" .. commandName .. " [player] [skin]", player, 255, 255, 255 )
		end
	end,
	true
)

--

local function teleport( player, x, y, z, interior, dimension )
	if isPedInVehicle( player ) and getPedOccupiedVehicleSeat( player ) == 0 then
		local vehicle = getPedOccupiedVehicle( player )
		
		setElementPosition( vehicle, x, y, z )
		setElementInterior( vehicle, interior )
		setElementDimension( vehicle, dimension )
		
		for i = 0, getVehicleMaxPassengers( vehicle ) do
			local p = getVehicleOccupant( vehicle, i )
			if p then
				setElementInterior( p, interior )
				setElementDimension( p, dimension )
			end
		end
		
		setVehicleTurnVelocity( vehicle, 0, 0, 0 )
		setElementVelocity( vehicle, 0, 0, 0 )
		return true
	else
		if isPedInVehicle( player ) then
			removePedFromVehicle( player )
		end
		
		setElementPosition( player, x, y, z )
		setElementInterior( player, interior )
		setElementDimension( player, dimension )
		return true
	end
end


addCommandHandler( "get",
	function( player, commandName, otherPlayer )
		if otherPlayer then
			local other, name = exports.players:getFromName( player, otherPlayer )
			if other then
				if other ~= player then
					-- if the vehicle ain't locked, try to put the player into a seat
					local teleported = false
					local vehicle = getPedOccupiedVehicle( player )
					if vehicle and not isVehicleLocked( vehicle ) then
						for i = 0, getVehicleMaxPassengers( vehicle ) do
							local p = getVehicleOccupant( vehicle, i )
							if not p then
								setElementInterior( other, getElementInterior( vehicle ) )
								setElementDimension( other, getElementDimension( vehicle ) )
								warpPedIntoVehicle( other, vehicle, i )
								teleported = true
								break
							end
						end
					end
					
					local x, y, z = getElementPosition( player )
					if teleported or teleport( other, x + 1, y, z, getElementInterior( player ), getElementDimension( player ) ) then
						outputChatBox( "You teleported " .. name .. " to you.", player, 0, 255, 153 )
						outputChatBox( getPlayerName( player ):gsub( "_", " " ) .. " teleported you to them.", other, 0, 255, 153 )
					end
				else
					outputChatBox( "You can't teleport yourself to yourself.", player, 255, 0, 0 )
				end
			end
		else
			outputChatBox( "Syntax: /" .. commandName .. " [player]", player, 255, 255, 255 )
		end
	end,
	true
)

addCommandHandler( "goto",
	function( player, commandName, otherPlayer )
		if otherPlayer then
			local other, name = exports.players:getFromName( player, otherPlayer )
			if other then
				if other ~= player then
					-- if the vehicle ain't locked, try to put the player into a seat
					local teleported = false
					local vehicle = getPedOccupiedVehicle( other )
					if vehicle and not isVehicleLocked( vehicle ) then
						for i = 0, getVehicleMaxPassengers( vehicle ) do
							local p = getVehicleOccupant( vehicle, i )
							if not p then
								setElementInterior( player, getElementInterior( vehicle ) )
								setElementDimension( player, getElementDimension( vehicle ) )
								warpPedIntoVehicle( player, vehicle, i )
								teleported = true
								break
							end
						end
					end
					
					local x, y, z = getElementPosition( other )
					if teleported or teleport( player, x + 1, y, z, getElementInterior( other ), getElementDimension( other ) ) then
						outputChatBox( "You teleported to " .. name .. ".", player, 0, 255, 153 )
						outputChatBox( getPlayerName( player ):gsub( "_", " " ) .. " teleported to you.", other, 0, 255, 153 )
					end
				else
					outputChatBox( "You can't teleport to yourself.", player, 255, 0, 0 )
				end
			end
		else
			outputChatBox( "Syntax: /" .. commandName .. " [player]", player, 255, 255, 255 )
		end
	end,
	true
)

--

addCommandHandler( "setname",
	function( player, commandName, otherPlayer, ... )
		if otherPlayer and ( ... ) then
			local newName = table.concat( { ... }, " " ):gsub( "_", " " )
			local other, name = exports.players:getFromName( player, otherPlayer )
			if other then
				if name == newName then
					outputChatBox( name .. " is already using that name.", player, 255, 0, 0 )
				elseif newName:lower( ) == name:lower( ) or not exports.sql:query_assoc_single( "SELECT characterID FROM characters WHERE characterName = '%s'", newName ) then
					-- check if another player uses that name
					if exports.sql:query_free( "UPDATE characters SET characterName = '%s' WHERE characterID = " .. exports.players:getCharacterID( other ), newName ) then
						if setPlayerName( other, newName:gsub( " ", "_" ) ) then
							exports.players:updateNametag( other )
							triggerClientEvent( other, "updateCharacterName", other, exports.players:getCharacterID( other ), newName )
							outputChatBox( "You changed " .. name .. "'s name to " .. newName .. ".", player, 0, 255, 0 )
						else
							exports.sql:query_free( "UPDATE characters SET characterName = '%s' WHERE characterID = " .. exports.players:getCharacterID( other ), name )
							outputChatBox( "Failed to change " .. name .. "'s name to " .. newName .. ".", player, 255, 0, 0 )
						end
					else
						outputChatBox( "Failed to change " .. name .. "'s name to " .. newName .. ".", player, 255, 0, 0 )
					end
				else
					outputChatBox( "Another player already uses that name.", player, 255, 0, 0 )
				end
			end
		else
			outputChatBox( "Syntax: /" .. commandName .. " [player] [new name]", player, 255, 255, 255 )
		end
	end,
	true
)

--

addCommandHandler( { "freeze", "unfreeze" },
	function( player, commandName, otherPlayer )
		if otherPlayer then
			local other, name = exports.players:getFromName( player, otherPlayer )
			if other then
				if player == other or not hasObjectPermissionTo( other, "command.freeze", false ) then
					local frozen = isElementFrozen( other )
					if frozen then
						outputChatBox( "You've unfrozen " .. name .. ".", player, 0, 255, 153 )
						if player ~= other then
							outputChatBox( "You have been unfrozen by " .. getPlayerName( player ) .. ".", other, 0, 255, 153 )
						end
					else
						outputChatBox( "You froze " .. name .. ".", player, 0, 255, 153 )
						if player ~= other then
							outputChatBox( "You have been frozen by " .. getPlayerName( player ) .. ".", other, 0, 255, 153 )
						end
					end
					toggleAllControls( other, frozen, true, false )
					setElementFrozen( other, not frozen )
					local vehicle = getPedOccupiedVehicle( other )
					if vehicle then
						setElementFrozen( vehicle, not frozen )
					end
				else
					outputChatBox( "You can't freeze this player.", player, 255, 0, 0 )
				end
			end
		else
			outputChatBox( "Syntax: /" .. commandName .. " [player]", player, 255, 255, 255 )
		end
	end,
	true
)

addCommandHandler( { "sethealth", "sethp" },
	function( player, commandName, otherPlayer, health )
		local health = tonumber( health )
		if otherPlayer and health and health >= 0 and health <= 100 then
			local other, name = exports.players:getFromName( player, otherPlayer )
			if other then
				local oldHealth = getElementHealth( other )
				if player == other or oldHealth < health or not hasObjectPermissionTo( other, "command.sethealth", false ) then
					if health < 1 then
						if killPed( other ) then
							outputChatBox( "You've killed " .. name .. ".", player, 0, 255, 153 )
						end
					elseif setElementHealth( other, health ) then
						outputChatBox( "You've set " .. name .. "'s health to " .. health .. ".", player, 0, 255, 153 )
					end
				else
					outputChatBox( "You can't change this player's health to a smaller value.", player, 255, 0, 0 )
				end
			end
		else
			outputChatBox( "Syntax: /" .. commandName .. " [player] [health]", player, 255, 255, 255 )
		end
	end,
	true
)

addEventHandler( "onPlayerQuit", root,
	function( type, reason, player )
		if type == "Kicked" or type == "Banned" then
			outputChatBox( ( isElement( player ) and getElementType( player ) == "player" and getPlayerName( player ):gsub( "_", " " ) or "Console" ) .. " " .. type:lower( ) .. " " .. getPlayerName( source ):gsub( "_", " " ) .. "." .. ( reason and #reason > 0 and ( " Reason: " .. reason ) or "" ), root, 255, 0, 0 )
		end
	end
)

addCommandHandler( "kick",
	function( player, commandName, otherPlayer, ... )
		if otherPlayer then
			local other, name = exports.players:getFromName( player, otherPlayer, true )
			if other then
				if not hasObjectPermissionTo( other, "command.kick", false ) then
					local reason = table.concat( { ... }, " " )
					kickPlayer( other, player, #reason > 0 and reason )
				else
					outputChatBox( "You can't kick this player.", player, 255, 0, 0 )
				end
			end
		else
			outputChatBox( "Syntax: /" .. commandName .. " [player] [reason]", player, 255, 255, 255 )
		end
	end,
	true
)

addCommandHandler( "ban",
	function( player, commandName, otherPlayer, hours, ... )
		hours = tonumber( hours )
		if otherPlayer and hours and hours >= 0 and ( ... ) then
			local other, name = exports.players:getFromName( player, otherPlayer, true )
			if other then
				if not hasObjectPermissionTo( other, "command.ban", false ) then
					local reason = table.concat( { ... }, " " ) .. " (" .. ( hours == 0 and "Permanent" or ( hours < 1 and ( math.ceil( hours * 60 ) .. " minutes" ) or ( hours .. " hours" ) ) ) .. ")"
					
					if exports.sql:query_free( "UPDATE wcf1_user SET banned = 1, banReason = '%s', banUser = " .. exports.players:getUserID( player ) .. " WHERE userID = " .. exports.players:getUserID( other ), reason ) then 
						local serial = getPlayerSerial( other )
						
						banPlayer( other, true, false, false, player, reason, math.ceil( hours * 60 * 60 ) )
						if serial then
							addBan( nil, nil, serial, player, reason .. " (" .. name .. ")", math.ceil( hours * 60 * 60 ) )
						end
					end
				else
					outputChatBox( "You can't ban this player.", player, 255, 0, 0 )
				end
			end
		else
			outputChatBox( "Syntax: /" .. commandName .. " [player] [time in hours, 0 for infinite] [reason]", player, 255, 255, 255 )
		end
	end,
	true
)

addEventHandler( "onUnban", root,
	function( ban )
		if getBanReason( ban ) ~= "Too many login attempts." then -- that certainly qualifies as nice try.
			local ip = getBanIP( ban )
			if ip then
				outputDebugString( "IP " .. ip .. " was unbanned by script." )
				exports.sql:query_free( "UPDATE wcf1_user SET banned = 0 WHERE lastIP = '%s'", ip )
			end
			
			local serial = getBanIP( ban )
			if serial then
				outputDebugString( "Serial " .. serial .. " was unbanned by script." )
				exports.sql:query_free( "UPDATE wcf1_user SET banned = 0 WHERE lastSerial = '%s'", serial )
			end
		end
	end
)

--

local function containsRank( t, s )
	for key, value in pairs( t ) do
		if value.displayName == s then
			return s
		end
	end
	return false
end

addCommandHandler( { "staff", "admins", "mods" },
	function( player, commandName, ... )
		if exports.players:isLoggedIn( player ) then
			outputChatBox( "Staff: ", player, 0, 255, 153 )
			local count = 0
			for key, value in ipairs( getElementsByType( "player" ) ) do
				local groups = exports.players:getGroups( value )
				if groups and #groups >= 1 then
					local title = containsRank( groups, "Administrator" ) or containsRank( groups, "Moderator" )
					if title then
						local duty = exports.players:getOption( value, "staffduty" )
						outputChatBox( "  [ID " .. exports.players:getID( value ) .. "] " .. title .. " " .. getPlayerName( value ):gsub( "_", " " ) .. ( duty and " - On Duty" or "" ), player, duty and 0 or 255, 255, duty and 153 or 255 )
						count = count + 1
					end
				end
			end
			
			if count == 0 then
				outputChatBox( "  None.", player, 255, 255, 91 )
			end
		end
	end
)

--

addCommandHandler( { "staffduty", "adminduty", "modduty" },
	function( player, commandName )
		local old = exports.players:getOption( player, "staffduty" )
		if exports.players:setOption( player, "staffduty", old ~= true or nil ) then
			exports.players:updateNametag( player )
			local message = getPlayerName( player ):gsub( "_", " " ) .. " " .. ( old and "went off" or "came on" ) .. " duty."
			local groups = exports.players:getGroups( player )
			if groups and #groups >= 1 then
				message = groups[1].displayName .. " " .. message
			end
			
			for key, value in ipairs( getElementsByType( "player" ) ) do
				if hasObjectPermissionTo( value, "command.staffduty", false ) then
					outputChatBox( message, value, old and 255 or 0, old and 191 or 255, 0 )
				end
			end
		end
	end,
	true
)
