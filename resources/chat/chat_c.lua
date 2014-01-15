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
					fn( player, ... )
				end
			)
		end
	end
end

-- /clearchat
addCommandHandler( { "clear", "clearchat" },
	function( commandName )
		if exports.players:isLoggedIn( localPlayer ) then
			for i = 1, getChatboxLayout( )[ "chat_lines" ] do
				outputChatBox( " " )
			end
		end
	end
)