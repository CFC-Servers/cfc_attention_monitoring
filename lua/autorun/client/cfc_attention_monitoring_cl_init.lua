local HasFocus = system.HasFocus
local EyePos = EyePos
local EyeAngles = EyeAngles
local cam_Start3D2D = cam.Start3D2D
local cam_End3D2D = cam.End3D2D
local math_floor = math.floor
local CurTime = CurTime
local draw_SimpleTextOutlined = draw.SimpleTextOutlined
local render_PushFilterMag = render.PushFilterMag
local surface_SetMaterial = surface.SetMaterial
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawTexturedRect = surface.DrawTexturedRect
local render_PopFilterMag = render.PopFilterMag
local TEXT_ALIGN_CENTER = TEXT_ALIGN_CENTER
local TEXT_ALIGN_TOP = TEXT_ALIGN_TOP
local TEXFILTER_POINT = TEXFILTER.POINT

local plyMeta = FindMetaTable( "Player" )
local isAlive = plyMeta.Alive

local entMeta = FindMetaTable( "Entity" )
local isDormant = entMeta.IsDormant
local getRenderMode = entMeta.GetRenderMode
local lookupAttachment = entMeta.LookupAttachment
local getAttachment = entMeta.GetAttachment
local getPos = entMeta.GetPos
local isValid = entMeta.IsValid

local isTabbedOut = false
local icon = Material( "icon16/monitor.png", "3D mips" )

local spriteBoneOffset = Vector( 0, 0, 15 )
local spriteOffset = Vector( 0, 0, 75 )
local fadeColor = Color( 255, 255, 255, 255 )
local fadeStart = 1250 ^ 2
local fadeEnd = 1750 ^ 2

local timeFont = "CFC_AM_FONT"
local RENDERMODE_TRANSALPHA = RENDERMODE_TRANSALPHA

local trackedPlayers = {}

surface.CreateFont( timeFont, {
        font = "Arial",
        size = 65,
        antialiasing = true,
        weight = 1
    }
)

local function formatAfkTime( rawTime )
    local timeStr = ""
    local time = math_floor( rawTime )
    local hours = math_floor( ( time % 86400 ) / 3600 )
    local minutes = math_floor( ( time % 3600 ) / 60 )

    if hours ~= 0 then
        timeStr = timeStr .. hours .. "h "
    end

    if minutes ~= 0 then
        timeStr = timeStr .. minutes .. "m"
    end

    return timeStr
end

local function drawIcon( ply )
    if not isValid( ply ) then
        table.RemoveByValue( trackedPlayers, ply )
        return
    end

    if not isAlive( ply ) then return end
    if isDormant( ply ) then return end
    if getRenderMode( ply ) == RENDERMODE_TRANSALPHA then return end

    -- Position
    local pos
    local eyes = lookupAttachment( ply, "eyes" )
    local attachment = getAttachment( ply, eyes )

    if attachment then -- checks if it got the bone
        pos = attachment.Pos + spriteBoneOffset
    else
        pos = getPos( ply ) + spriteOffset
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

    cam_Start3D2D( pos, angle, 0.05 )
        render_PushFilterMag( TEXFILTER_POINT )
        surface_SetMaterial( icon )
        surface_SetDrawColor( fadeColor )
        surface_DrawTexturedRect( -110, -110, 220, 220 )
        render_PopFilterMag()

        local afktime = CurTime() - ply:GetNW2Int( "CFC_AM_TabbedOutTime" )
        if afktime > 60 then
            draw_SimpleTextOutlined( formatAfkTime( afktime ), "CFC_AM_FONT", 0, 120, fadeColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, fadeColor )
        end
    cam_End3D2D()
end

local function drawIcons()
    for _, ply in ipairs( trackedPlayers ) do
        drawIcon( ply )
    end
end

hook.Add( "PostDrawTranslucentRenderables", "CFC_AttentionMonitor_AfkRenderElements", drawIcons )

hook.Add( "EntityNetworkedVarChanged", "CFC_AttentionMonitor", function( ent, name, _, newVal )
    if name ~= "CFC_AM_IsTabbedOut" then return end
    if ent == LocalPlayer() then return end

    if newVal and not table.HasValue( trackedPlayers, ent ) then
        table.insert( trackedPlayers, ent )
    else
        table.RemoveByValue( trackedPlayers, ent )
    end
end )

gameevent.Listen( "OnRequestFullUpdate" )
hook.Add( "OnRequestFullUpdate", "CFC_AttentionMonitor", function( data )
    if Player( data.userid ) ~= LocalPlayer() then return end

    trackedPlayers = {}
end )

timer.Create( "CFC_AttentionMonitor_TabNetTimmer", 0.25, 0, function()
    local hasFocus = HasFocus()
    if isTabbedOut == hasFocus then return end

    net.Start( "CFC_AttentionMonitor_GameHasFocus" )
        net.WriteBool( hasFocus )
    net.SendToServer()

    isTabbedOut = hasFocus
end )
