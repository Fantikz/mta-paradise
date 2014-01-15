<?php
// We don't need any stupid error messages
ob_start( );

// Load the Weather data
$xml = simplexml_load_file( 'http://api.openweathermap.org/data/2.5/weather?q=Los+Angeles&mode=xml&units=metric&APPID=e648971715d8148ded25c9f7fedb884b' );

// current weather
$value = array( );
$value[] = strtolower( $xml->weather['value'] );
$value[] = strtolower( number_format( $xml->temperature['value'], 2 ) );
$value[] = strtolower( number_format( $xml->wind->speed['value'], 2 ) );
$value[] = strtolower( $xml->wind->direction['code'] );

// clear everything outputted until now & output our data
ob_end_clean( );
echo json_encode( $value );

?>
