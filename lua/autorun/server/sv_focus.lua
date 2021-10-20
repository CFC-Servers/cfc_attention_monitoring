local tabbedOutPlys = {}
local tabbedKeyValue = nil

util.AddNetworkString( "CFC_AttentionMonitor_gameHasFocus" )
util.AddNetworkString( "CFC_AttentionMonitor_sendData" )

net.Receive( "CFC_AttentionMonitor_gameHasFocus", function( _, pl ) -- Gets the player that tabbed out
	hasFocus = net.ReadBool()
	if not hasFocus and not tabbedOutPlys[pl] then
		table.insert( tabbedOutPlys, pl )
		tabbedKeyValue = table.KeyFromValue( tabbedOutPlys, pl )
	elseif tabbedOutPlys then
		tabbedOutPlys[ tabbedKeyValue ] = nil
	end

	net.Start( "CFC_AttentionMonitor_sendData" ) -- Sends the list of players to the client
		net.WriteTable( tabbedOutPlys )
	net.Broadcast()
end)