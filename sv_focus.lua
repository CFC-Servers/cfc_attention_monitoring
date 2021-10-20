tabbedOutPlys = {}

util.AddNetworkString( "tabbedOut" )
util.AddNetworkString( "tabbedIn" )
util.AddNetworkString( "sendData" )

net.Receive( "tabbedOut", function( len, pl ) -- Gets the player that tabbed out
	if table.HasValue( tabbedOutPlys, pl ) then return end
	table.insert( tabbedOutPlys, pl ) -- Adds the player that tabbed out once

	net.Start( "sendData" ) -- Sends the list of players to the client
		net.WriteTable( tabbedOutPlys )
	net.Broadcast()
end)

net.Receive("tabbedIn", function( len, pl ) -- Gets the player that tabbed in
	if not table.HasValue( tabbedOutPlys, pl ) then return end
	table.RemoveByValue( tabbedOutPlys, pl ) -- Removes the player that tabbed back in

	net.Start( "sendData" ) -- Sends the list of players to the client
		net.WriteTable( tabbedOutPlys )
	net.Broadcast()
end)