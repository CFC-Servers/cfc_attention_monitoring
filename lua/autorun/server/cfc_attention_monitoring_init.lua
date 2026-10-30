util.AddNetworkString( "cfc_attentionmonitor" )

CFCAttentionMonitor = CFCAttentionMonitor or {}
CFCAttentionMonitor.PlayerStatuses = CFCAttentionMonitor.PlayerStatuses or {}

-- Get the highest priority active status for a player
local function getHighestStatus( statuses )
    for i = 1, CFCAttentionMonitor.EnumCount do
        if statuses[i] then return i, statuses[i] end
    end

    return 0, 0
end

local function broadcastStatus( ply, statusType, statusTime )
    net.Start( "cfc_attentionmonitor" )
        net.WriteUInt( ply:EntIndex(), MAX_PLAYER_BITS )
        net.WriteUInt( statusType, 3 )
        if statusType ~= 0 then
            net.WriteFloat( statusTime )
        end
    net.Broadcast()
end

local function sync( ply )
    local plyStatusTable = CFCAttentionMonitor.PlayerStatuses[ply]
    local plyStatuses = plyStatusTable.statuses

    local newType, startTime = getHighestStatus( plyStatuses )
    if newType == plyStatusTable.lastSentType then return end
    plyStatusTable.lastSentType = newType

    if newType == 0 then
        broadcastStatus( ply, 0, 0 )
        return
    end

    broadcastStatus( ply, newType, startTime )
end

hook.Add( "PlayerInitialSpawn", "CFC_AttentionMonitor_SendSnapshot", function( joiningPly )
    for ply, plyTable in pairs( CFCAttentionMonitor.PlayerStatuses ) do
        local plyStatuses = plyTable.statuses
        local newType, _startTime = getHighestStatus( plyStatuses )

        net.Start( "cfc_attentionmonitor" )
            net.WriteUInt( ply:EntIndex(), MAX_PLAYER_BITS )
            net.WriteUInt( newType, 3 )
            if newType ~= 0 then
                net.WriteFloat( _startTime )
            end
        net.Send( joiningPly )
    end
end )

hook.Add( "PlayerDisconnected", "CFC_AttentionMonitor_CleanupPlayerData", function( ply )
    broadcastStatus( ply, 0, 0 )

    CFCAttentionMonitor.PlayerStatuses[ply] = nil
end )

-- Leaky bucket rate limiting
local buffer = 50 -- total in the bucket
local refill = 8 -- per second
local function rateLimit( ply )
    if not ply.CFC_AM_RateLimitBucket then ply.CFC_AM_RateLimitBucket = buffer end

    local curTime = CurTime()
    if not ply.CFC_AM_RatelimitTime then ply.CFC_AM_RatelimitTime = curTime end

    local dripSize = curTime - ply.CFC_AM_RatelimitTime
    ply.CFC_AM_RatelimitTime = curTime

    local drip = dripSize * refill
    local newVal = ply.CFC_AM_RateLimitBucket + drip

    ply.CFC_AM_RateLimitBucket = math.Clamp( newVal, 0, buffer )

    if ply.CFC_AM_RateLimitBucket >= 1 then
        ply.CFC_AM_RateLimitBucket = ply.CFC_AM_RateLimitBucket - 1
        return true
    else
        return false
    end
end

net.Receive( "cfc_attentionmonitor", function( _, ply )
    if not rateLimit( ply ) then return end

    local eventType = net.ReadUInt( 3 )
    if not CFCAttentionMonitor.EnumsReverse[eventType] then return end

    local plyTable = CFCAttentionMonitor.PlayerStatuses[ply] or { lastSentType = 0, statuses = {} }
    CFCAttentionMonitor.PlayerStatuses[ply] = plyTable

    local active = net.ReadBool()
    local plyStatuses = plyTable.statuses

    if active then
        if plyStatuses[eventType] then return end
        plyStatuses[eventType] = CurTime()
    else
        if not plyStatuses[eventType] then return end
        plyStatuses[eventType] = nil
    end

    sync( ply )
end )
