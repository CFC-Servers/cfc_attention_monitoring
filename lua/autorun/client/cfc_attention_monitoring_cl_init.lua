local tabbedOutList = {}
local isTabbedOut = false
local icon = Material( "icon16/monitor.png", "$translucent" )

local function renderables( ply )
    if not IsValid( ply ) then return end
    if ply == LocalPlayer() then return end

    render.SetMaterial( icon ) -- Place Holder
    render.DrawSprite( ply:GetPos() + Vector( 0, 0, 75 ), 16, 16, Color( 225, 225, 225, 255 ) ) -- place Holder
end

timer.Create( "CFC_AttentionMonitor_TabNetTimmer", 0.5, 0, function()
    local hasFocus = system.HasFocus()

    if isTabbedOut == hasFocus then return end

    net.Start( "CFC_AttentionMonitor_GameHasFocus" )
        net.WriteBool( hasFocus )
    net.SendToServer()
    isTabbedOut = hasFocus
end )

net.Receive( "CFC_AttentionMonitor_SendData", function() -- receives the players that tabbed out
    tabbedOutList = net.ReadTable()
end )

hook.Add( "PostDrawTranslucentRenderables", "CFC_AttentionMonitor_AfkRenderElements", function()
    for ply in pairs( tabbedOutList ) do -- draws the icon for each tabbed out player
        renderables( ply )
    end
end )
