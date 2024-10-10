util.AddNetworkString( "CFC_AttentionMonitor" )

CFCAttentionMonitor = CFCAttentionMonitor or {}
CFCAttentionMonitor.PlayerStatuses = {}

hook.Add( "PlayerDisconnected", "CFC_AttentionMonitor_CleanupPlayerData", function( ply )
    CFCAttentionMonitor.PlayerStatuses[ply] = nil
end )

local function sync( ply )
    local plyTable = CFCAttentionMonitor.PlayerStatuses[ply]
    local hasStatus = false
    for i = 1, CFCAttentionMonitor.EnumCount do
        if plyTable[i] then
            ply:SetNW2Int( "CFC_AM_Type", i )
            ply:SetNW2Int( "CFC_AM_Time", CurTime() )
            hasStatus = true

            break
        end
    end

    if not hasStatus then
        ply:SetNW2Int( "CFC_AM_Type", 0 )
    end
end

net.Receive( "CFC_AttentionMonitor", function( _, ply )
    local eventType = net.ReadUInt( 3 )
    if not CFCAttentionMonitor.EnumsReverse[eventType] then return end

    local active = net.ReadBool()
    if not active then
        if not CFCAttentionMonitor.PlayerStatuses[ply] then return end
        CFCAttentionMonitor.PlayerStatuses[ply][eventType] = nil
        sync( ply )
        return
    end

    CFCAttentionMonitor.PlayerStatuses[ply] = CFCAttentionMonitor.PlayerStatuses[ply] or {}
    CFCAttentionMonitor.PlayerStatuses[ply][eventType] = true
    sync( ply )
end )
