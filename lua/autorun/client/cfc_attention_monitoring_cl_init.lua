local ipairs = ipairs
local player_GetAll = player.GetAll

local isTabbedOut = false
local icon = Material( "icon16/monitor.png", "3D" )

local spriteColor = Color( 225, 225, 225, 225 )
local spriteBoneOffset = Vector( 0, 0, 12 )
local spriteOffset = Vector( 0, 0, 73 )

local function renderTabbedOut( ply )
    local eyes = ply:LookupAttachment( "eyes" )
    local attachment = ply:GetAttachment( eyes )

    if attachment then -- checks if it got the bone
        pos = attachment.Pos + spriteBoneOffset
    else
        pos = ply:GetPos() + spriteOffset
    end

    render.SetMaterial( icon )
    render.DrawSprite( pos, 16, 16, spriteColor )
end

timer.Create( "CFC_AttentionMonitor_TabNetTimmer", 0.5, 0, function()
    local hasFocus = system.HasFocus()
    if isTabbedOut == hasFocus then return end

    net.Start( "CFC_AttentionMonitor_GameHasFocus" )
        net.WriteBool( hasFocus )
    net.SendToServer()

    isTabbedOut = hasFocus
end )

hook.Add( "PostPlayerDraw", "CFC_AttentionMonitor_AfkRenderElements", function( ply )
    if ply ~= me and ply:GetNW2Bool( "IsTabbedOut" ) then
        pcall( renderTabbedOut, ply )
    end
end )
