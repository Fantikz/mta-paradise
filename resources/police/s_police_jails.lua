jails =
{
	{
		posX  = 219.49,   posY  = 113.18, posZ  = 999.01, interior  = 10, dimension  = 1, rotZ  = 0,
		posX2 = 219.52,   posY2 = 110.91, posZ2 = 999.01, interior2 = 10, dimension2 = 1, rotZ2 = 0,
		relX  = -1605.49, relY  = 718.34, relZ  = 11.97,  interiorR = 0,  dimensionR = 0, rotZR = 0
	}
}

jailSettings =
{
	mintime = get( 'mintime' ) or 5,
	minfine = get( 'minfine' ) or 0,
	maxtime = get( 'maxtime' ) or 120,
	maxfine = get( 'maxfine' ) or 10000,
	maxdist = get( 'maxdist' ) or 1.3,
	_debug	= get( 'debug' ) or false
}

function getJails( )
	return jails
end

function getJailSettings( )
	return jailSettings
end

function setJailSettings( setting, value )
	if setting and value then
		if jailSettings[ setting ] then
			jailSettings[ setting ] = value
			return true
		else
			return false, "Invalid setting key passed in."
		end
	end
	return false, "Invalid arguments passed in."
end