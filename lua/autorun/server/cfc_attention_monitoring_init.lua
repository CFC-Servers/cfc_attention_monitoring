local tabbedOutPlys = {}
local lastTabbedOutPlys = {}

util.AddNetworkString( "CFC_AttentionMonitor_GameHasFocus" )
util.AddNetworkString( "CFC_AttentionMonitor_SendData" )

hook.Add( "PlayerDisconnected", "CFC_AttentionMonitor_PlayerLeave", function(ply)
    if not tabbedOutPlys[ply] then return end
    tabbedOutPlys[ply] = nil
end)

local function gameHasFocusCallback( _, ply )
    local hasFocus = net.ReadBool()
    tabbedOutPlys[ ply ] = not hasFocus or nil
end

local function compareTables( tab1, tab2 ) -- function made by redox
    for key, val in pairs( tab1 ) do
        if val ~= tab2[key] then
            return false
        end
    end
    return true
end

timer.Create( "CFC_AttentionMonitor_DataTimmer", 1.2, 0, function()
    if compareTables( tabbedOutPlys, lastTabbedOutPlys ) then return end

    net.Start( "CFC_AttentionMonitor_SendData" ) -- Sends the list of players to the client
        net.WriteTable( tabbedOutPlys )
    net.Broadcast()

    lastTabbedOutPlys = table.Copy(tabbedOutPlys)
end)

net.Receive( "CFC_AttentionMonitor_GameHasFocus", gameHasFocusCallback )  -- Gets the player that tabbed out
