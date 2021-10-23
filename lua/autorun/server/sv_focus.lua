local tabbedOutPlys = {}

util.AddNetworkString( "CFC_AttentionMonitor_gameHasFocus" )
util.AddNetworkString( "CFC_AttentionMonitor_sendData" )

hook.Add( "PlayerDisconnected", "CFC_AttentionMonitor_playerleave", function(ply)
	if not tabbedOutPlys[ ply ] then return end
	tabbedOutPlys[ ply ] = nil
end)

function gameHasFocusCallback( _, pl )
	local hasFocus = net.ReadBool()
	if not hasFocus and not tabbedOutPlys[ pl ] then -- Checks to see if it needs to add the player
		tabbedOutPlys[ pl ] = true
	else
		tabbedOutPlys[ pl ] = nil
	end
end

timer.Create( "CFC_AttentionMonitor_dataTimmer", 1.2, 0, function()
	net.Start( "CFC_AttentionMonitor_sendData" ) -- Sends the list of players to the client
		net.WriteTable( tabbedOutPlys )
	net.Broadcast()
end)

net.Receive( "CFC_AttentionMonitor_gameHasFocus", gameHasFocusCallback )  -- Gets the player that tabbed out