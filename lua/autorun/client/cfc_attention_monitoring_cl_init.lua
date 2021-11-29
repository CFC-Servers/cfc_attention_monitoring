local tabbedOutList = {}
local isTabbedOut = false
local icon = Material( "icon16/monitor.png", "3D" )

local function renderables( ply )
    if not IsValid( ply ) then return end
    if ply == LocalPlayer() then return end

        local attachment = ply:GetAttachment( ply:LookupAttachment("eyes") ) -- gets the eye bone of the player

        if attachment then -- checks if it got the bone
            pos = ply:GetAttachment( ply:LookupAttachment( "eyes" ) ).Pos + Vector( 0, 0, 12 )
        else
            pos = ply:GetPos() + Vector( 0, 0, 73 )
        end

        render.SetMaterial( icon )
        render.DrawSprite( pos, 16, 16, Color( 225, 225, 225, 255 ) )
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

hook.Add( "PostPlayerDraw", "CFC_AttentionMonitor_AfkRenderElements", function()
    for ply in pairs( tabbedOutList ) do -- draws the icon for each tabbed out player
        renderables( ply )
    end
end )
