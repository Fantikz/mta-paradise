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

local remoteAddress = get( 'weather' )

--

local celsius = 20
local weather =
{
	-- not all weathers make sense/look good at all times, this should prolly be fixed (alternative suggestion: make a table and make the weather occurences managable via admin/clicks (never - seldom - average - more than usual - often)
	sunny = { 0, 1, 10, 11, 17, 18 },
	clouds = { 2, 3, 4, 5, 6, 7 },
	fog = { 9 },
	stormy = { 8 },
	rainy = { 16 },
	dull = { 12, 13, 14, 15 },
}

local details =
{
	-- could've been made easily with just the opposite way, but whatever really
	["sky is clear"] = { "sunny" },
	["few clouds"] = { "sunny" },
	["scattered clouds"] = { "sunny" },
	["broken clouds"] = { "sunny" },
	["cold"] = { "sunny" },
	["hot"] = { "sunny" },
	["overcast clouds"] = { "clouds" },
	["light rain"] = { "rainy", 0.8, 0.07 },
	["moderate rain"] = { "rainy", 1.0, 0.1, 0.8 },
	["hail"] = { "rainy", 1.0, 0.1, 0.8 },
	["heavy intensity rain"] = { "rainy", 1.2, 0.35, 1.0 },
	["very heavy rain"] = { "rainy", 1.4, 1.0, 1.6 },
	["extreme rain"] = { "rainy", 1.6, 2.5, 2.0 },
	["freezing rain"] = { "rainy", 1.8, 4.0, 2.3 },
	["light intensity shower rain"] = { "rainy", 0.75 },
	["shower rain"] = { "rainy", 0.7 },
	["heavy intensity shower rain"] = { "rainy", 0.87 },
	["light intensity drizzle"] = { "rainy", 0.1 },
	["drizzle"] = { "rainy", 0.2 },
	["heavy intensity drizzle"] = { "rainy", 0.35 },
	["drizzle rain"] = { "rainy", 0.4 },
	["heavy intensity drizzle rain"] = { "rainy", 0.55 },
	["shower drizzle"] = { "rainy", 0.62 },
	["thunderstorm with light rain"] = { "stormy", 0.66, 0.2, 0.8 },
	["thunderstorm with rain"] = { "stormy", 1.0, 0.4, 1.2 },
	["thunderstorm with heavy rain"] = { "stormy", 1.2, 0.75, 1.4 },
	["light thunderstorm"] = { "stormy" },
	["thunderstorm"] = { "stormy" },
	["heavy thunderstorm"] = { "stormy" },
	["ragged thunderstorm"] = { "stormy" },
	["thunderstorm with light drizzle"] = { "stormy", 0.1 },
	["thunderstorm with drizzle"] = { "stormy", 0.2 },
	["thunderstorm with heavy drizzle"] = { "stormy", 0.35 },
	["mist"] = { "fog" },
	["smoke"] = { "fog" },
	["fog"] = { "fog" },
	["Sand/Dust Whirls"] = { "dull", 0.2, 2.1 },
	["haze"] = { "dull", 0.2, 2.1 },
	["tornado"] = { "dull", 0.2, 2.1 },
	["windy"] = { "dull", 0.2, 2.1 }
}

--

local function setWeatherEx( str, rain, level, wave )
	setWeather( weather[str][ math.random( #weather[str] ) ] )
	
	setRainLevel( rain or 0 )
	setWaterLevel( level or 0 )
	setWaveHeight( wave or 0.5 )
end

local function setWeatherFromRemote( data )
	if not data or not data[1] or not data[2] or not data[3] or not data[4] then
		outputDebugString( "Weather: " .. remoteAddress .. " returned no usable data.", 2 )
	else
		local _weather, _celsius, _wind, _direction = unpack( data )
		celsius = _celsius
		
		if details[_weather] then
			setWeatherEx( details[_weather][1], details[_weather][2] or 0, details[_weather][3] or 0, details[_weather][4] or 0 )
		else
			setWeatherEx( "sunny", 0, 0, 0 )
		end
		
		if _direction == "SSE" or _direction == "SE" then
			setWindVelocity( _wind, -_wind, _wind )
		elseif _direction == "NNE" or _direction == "NE" then
			setWindVelocity( _wind, _wind, _wind )
		elseif _direction == "NNW" or _direction == "NW" then
			setWindVelocity( -_wind, _wind, _wind )
		elseif _direction == "SSW" or _direction == "SW" then
			setWindVelocity( -_wind, -_wind, _wind )
		elseif _direction == "S" then
			setWindVelocity( 0.1, -_wind, _wind )
		elseif _direction == "N" then
			setWindVelocity( 0.1, _wind, _wind )
		elseif _direction == "E" then
			setWindVelocity( _wind, 0.1, _wind )
		elseif _direction == "W" then
			setWindVelocity( 0.1, _wind, _wind )
		else
			setWindVelocity( 0.3, 0.3, 0.3 )
		end
	end
end

local function updateWeather( )
	if remoteAddress then
		-- find a new weather
		callRemote( remoteAddress, setWeatherFromRemote )
	end
end

addEventHandler( "onResourceStart", resourceRoot,
	function( )
		if remoteAddress then
			-- create an initial weather
			updateWeather( )
			
			-- change it after three hours
			setTimer( updateWeather, 180 * 60000, 0 )
		end
	end
)
