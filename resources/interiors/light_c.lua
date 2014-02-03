local sx, sy = guiGetScreenSize( )
local darknessSource = false
local darknessDefault, darknessLevel, darknessSpeed = 0.82, 0, 1
local darknessLevels = {
	[0]  = 175,
	[1]  = 200,
	[2]  = 250,
	[3]  = 200,
	[4]  = 140,
	[5]  = 75,
	[6]  = 50,
	[7]  = 37,
	[8]  = 25,
	[9]  = 10,
	[10] = 7,
	[11] = 3,
	[12] = 0,
	[13] = 0,
	[14] = 0,
	[15] = 3,
	[16] = 7,
	[17] = 10,
	[18] = 25,
	[19] = 37,
	[20] = 50,
	[21] = 100,
	[22] = 125,
	[23] = 150
}

addEventHandler( "onClientResourceStart", resourceRoot,
	function( )
		darknessSource = dxCreateScreenSource( sx, sy )
	end
)

addEventHandler( "onClientHUDRender", root,
    function( )
		if ( not darknessSource ) then return end
		local hour, minute = getTime( )
		local dimension = getElementDimension( localPlayer )
		for key, colshape in ipairs ( getElementsByType( "colshape", resourceRoot ) ) do
			local level = tonumber( getElementData( colshape, "light" ) )
			if ( getElementDimension( colshape ) == dimension ) and ( level ) then
				for _hour, level in pairs( darknessLevels ) do
					if ( hour == _hour ) then
						if ( darknessLevel < level ) then
							darknessLevel = darknessLevel + darknessSpeed
						elseif ( darknessLevel > level ) then
							darknessLevel = darknessLevel - darknessSpeed
						end
					end
				end
				
				dxSetRenderTarget( )
				dxDrawImage( 0, 0, sx, sy, darknessSource, 0, 0, 0, tocolor( 255, 255, 255, ( level == 10 and 0 or ( darknessDefault * darknessLevel ) / ( level + 1 ) ) ) )
			end
		end
    end
)