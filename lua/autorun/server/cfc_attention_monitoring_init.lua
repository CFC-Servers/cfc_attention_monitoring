util.AddNetworkString( "CFC_AttentionMonitor_GameHasFocus" )

CFCAttentionMonitor = { pendingFocusChanges = {} }
local pendingFocusChanges = CFCAttentionMonitor.pendingFocusChanges

hook.Add( "PlayerDisconnected", "CFC_AttentionMonitor_CleanupPlayerData", function( ply )
    pendingFocusChanges[ply] = nil
end )

local function focusCallback( _, ply )
    pendingFocusChanges[ply] = not net.ReadBool()
end

timer.Create( "CFC_AttentionMonitor_DataTimer", 0.25, 0, function()
    for ply, isTabbedOut in pairs( pendingFocusChanges ) do
        ply:SetNW2Bool( "CFC_AM_IsTabbedOut", isTabbedOut )
        ply:SetNW2Bool( "CFC_AM_TabbedOutTime", CurTime() )
        pendingFocusChanges[ply] = nil
    end
end )

net.Receive( "CFC_AttentionMonitor_GameHasFocus", focusCallback )
