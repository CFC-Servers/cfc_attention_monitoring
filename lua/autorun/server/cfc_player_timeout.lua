timer.Create( "CFC_AttentionMonitor_TimingOut", 1, 0, function()
    local plys = player.GetAll()
    local plyCount = #plys

    for i = 1, plyCount do
        local ply = plys[i]
        ply:SetNW2Bool( "CFC_AttentionMonitor_TimingOut", ply:IsTimingOut() )
    end
end )
