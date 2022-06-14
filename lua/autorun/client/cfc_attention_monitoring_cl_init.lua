local HasFocus = system.HasFocus
local IsValid = IsValid
local cam_Start3D2D = cam.Start3D2D
local cam_End3D2D = cam.End3D2D

local render_PushFilterMag = render.PushFilterMag
local surface_SetMaterial = surface.SetMaterial
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawTexturedRect = surface.DrawTexturedRect
local render_PopFilterMag = render.PopFilterMag

local isTabbedOut = false
local icon = Material( "icon16/monitor.png", "3D mips" )

local spriteBoneOffset = Vector( 0, 0, 15 )
local spriteOffset = Vector( 0, 0, 75 )
local fadeColor = Color( 255, 255, 255, 255 )
local fadeStart = 1000 ^ 2
local fadeEnd = 1750 ^ 2

local function drawIcon( ply )
    if not IsValid( ply ) then return end
    if ply == LocalPlayer() then return end
    if not ply:Alive() then return end

    -- Position
    local pos
    local eyes = ply:LookupAttachment( "eyes" )
    local attachment = ply:GetAttachment( eyes )

    if attachment then -- checks if it got the bone
        pos = attachment.Pos + spriteBoneOffset
    else
        pos = ply:GetPos() + spriteOffset
    end

    -- Angle
    local angle = EyeAngles()
    angle:RotateAroundAxis( angle:Right(), 90 )
    angle:RotateAroundAxis( -angle:Up(), 90 )

    -- Fade
    local dist = pos:DistToSqr( EyePos() )
    if dist > fadeEnd then return end
    if dist > fadeStart then
        fadeColor.a = 255 * ( 1 - ( dist / fadeEnd ) )
    else
        fadeColor.a = 255
    end

    cam_Start3D2D( pos, angle, 1 )
        render_PushFilterMag( TEXFILTER.POINT )
        surface_SetMaterial( icon )
        surface_SetDrawColor( fadeColor )
        surface_DrawTexturedRect( -7, -7, 14, 14 )
        render_PopFilterMag()
    cam_End3D2D()
end

local function drawIcons()
    for _, ply in ipairs( player.GetAll() ) do
        if true or ply:GetNW2Bool( "IsTabbedOut" ) then
            drawIcon( ply )
        end
    end
end

hook.Add( "PostDrawTranslucentRenderables", "CFC_AttentionMonitor_AfkRenderElements", drawIcons )

timer.Create( "CFC_AttentionMonitor_TabNetTimmer", 0.25, 0, function()
    local hasFocus = HasFocus()
    if isTabbedOut == hasFocus then return end

    net.Start( "CFC_AttentionMonitor_GameHasFocus" )
        net.WriteBool( hasFocus )
    net.SendToServer()

    isTabbedOut = hasFocus
end )
