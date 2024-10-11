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

net.Receive( "CFC_AttentionMonitor", function( _, ply )
    if not rateLimit( ply ) then return end

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
