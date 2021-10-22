local tabbedOutPlys = {}

util.AddNetworkString( "CFC_AttentionMonitor_gameHasFocus" )
util.AddNetworkString( "CFC_AttentionMonitor_sendData" )

function gameHasFocusCallback( pl )
	local hasFocus = net.ReadBool()
	if not hasFocus and not tabbedOutPlys[ pl ] then -- Checks to see if it needs to add the player
		tabbedOutPlys[ pl ] = true
	else
		tabbedOutPlys[ pl ] = nil
	end

	net.Start( "CFC_AttentionMonitor_sendData" ) -- Sends the list of players to the client
		net.WriteTable( tabbedOutPlys )
	net.Broadcast()
end

net.Receive( "CFC_AttentionMonitor_gameHasFocus", function( _, pl )  -- Gets the player that tabbed out
	gameHasFocusCallback( pl )
end)