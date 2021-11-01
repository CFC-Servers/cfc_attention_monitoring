local tabbedOutPlys = {}
local hasDataChanged = false

util.AddNetworkString( "CFC_AttentionMonitor_GameHasFocus" )
util.AddNetworkString( "CFC_AttentionMonitor_SendData" )

hook.Add( "PlayerDisconnected", "CFC_AttentionMonitor_PlayerLeave", function(ply)
    if not tabbedOutPlys[ply] then return end
    hasDataChanged = true
    tabbedOutPlys[ply] = nil
end)

local function gameHasFocusCallback( _, ply )
    local hasFocus = net.ReadBool()
    hasDataChanged = true
    tabbedOutPlys[ ply ] = not hasFocus or nil
end

timer.Create( "CFC_AttentionMonitor_DataTimmer", 1.2, 0, function()
    if not hasDataChanged then return end
    net.Start( "CFC_AttentionMonitor_SendData" ) -- Sends the list of players to the client
        net.WriteTable( tabbedOutPlys )
    net.Broadcast()
    hasDataChanged = false
end)

net.Receive( "CFC_AttentionMonitor_GameHasFocus", gameHasFocusCallback )  -- Gets the player that tabbed out
