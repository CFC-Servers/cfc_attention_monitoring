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
local scrH = ScrH()
local scrW = ScrW()

local plyMeta = FindMetaTable( "Player" )
local isAlive = plyMeta.Alive

local entMeta = FindMetaTable( "Entity" )
local isDormant = entMeta.IsDormant
local getRenderMode = entMeta.GetRenderMode
local lookupBone = entMeta.LookupBone
local getBoneMatrix = entMeta.GetBoneMatrix
local isValid = entMeta.IsValid

local spriteBoneOffset = Vector( 0, 0, 15 )
local fadeColor = Color( 255, 255, 255, 255 )
local fadeStart = 1250 ^ 2
local fadeEnd = 1750 ^ 2
local iconSize = 128

local timeFont = "CFC_AM_FONT"
local RENDERMODE_TRANSALPHA = RENDERMODE_TRANSALPHA

CFCAttentionMonitor.TrackedPlayers = CFCAttentionMonitor.TrackedPlayers or {}
local trackedPlayers = CFCAttentionMonitor.TrackedPlayers

surface.CreateFont( timeFont, {
        font = "Arial",
        size = 65,
        antialiasing = true,
        weight = 1
    }
)

hook.Add( "OnScreenSizeChanged", "CFC_AttentionMonitor", function()
    scrH = ScrH()
    scrW = ScrW()
end )

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

local function drawIcon( ply, iconType )
    if not isValid( ply ) then
        table.RemoveByValue( trackedPlayers, ply )
        return
    end

    if not isAlive( ply ) then return end
    if isDormant( ply ) then return end
    if getRenderMode( ply ) == RENDERMODE_TRANSALPHA then return end

    -- Position
    local headBone = lookupBone( ply, "ValveBiped.Bip01_Head1" ) or 0
    local matrix = getBoneMatrix( ply, headBone )
    if not matrix then return end

    local pos = matrix:GetTranslation()
    pos = pos + spriteBoneOffset

    local screenPos = pos:ToScreen()
    if not screenPos.visible then return end

    local x = screenPos.x
    if x < 0 or x > scrW then return end
    local y = screenPos.y
    if y < 0 or y > scrH then return end

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

    local icon = CFCAttentionMonitor.Icons[iconType]

    cam_Start3D2D( pos, angle, 0.05 )
        render_PushFilterMag( TEXFILTER_POINT )
        surface_SetMaterial( icon )
        surface_SetDrawColor( fadeColor )
        surface_DrawTexturedRect( -iconSize / 2, -iconSize / 2, iconSize, iconSize )
        render_PopFilterMag()

        local afktime = CurTime() - ply:GetNW2Int( "CFC_AM_Time" )
        if afktime > 60 then
            draw_SimpleTextOutlined( formatAfkTime( afktime ), "CFC_AM_FONT", 0, 60, fadeColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, fadeColor )
        end
    cam_End3D2D()
end

local function drawIcons( _, _, skybox3d )
    if skybox3d then return end

    for _, plyTbl in ipairs( trackedPlayers ) do
        drawIcon( plyTbl.ply, plyTbl.type )
    end
end

hook.Add( "PostDrawTranslucentRenderables", "CFC_AttentionMonitor_AfkRenderElements", drawIcons )

hook.Add( "EntityNetworkedVarChanged", "CFC_AttentionMonitor", function( ent, name, _, newVal )
    if name ~= "CFC_AM_Type" then return end
    if ent == LocalPlayer() then return end

    if newVal == 0 then
        for i, plyTbl in ipairs( trackedPlayers ) do
            if plyTbl.ply == ent then
                table.remove( trackedPlayers, i )
                return
            end
        end
        return
    end

    for _, plyTbl in ipairs( trackedPlayers ) do
        if plyTbl.ply == ent then
            plyTbl.type = newVal
            return
        end
    end

    table.insert( trackedPlayers, { ply = ent, type = newVal } )
end )

gameevent.Listen( "OnRequestFullUpdate" )
hook.Add( "OnRequestFullUpdate", "CFC_AttentionMonitor", function( data )
    if Player( data.userid ) ~= LocalPlayer() then return end

    trackedPlayers = {}
end )

-- Tabbed out detection
local lastTabbedOut = false
local lastMainmenu = false
timer.Create( "CFC_AttentionMonitor_TabNetTimmer", 0.2, 0, function()
    local hasFocus = HasFocus()
    if lastTabbedOut ~= hasFocus then
        net.Start( "CFC_AttentionMonitor" )
            net.WriteUInt( CFCAttentionMonitor.Enums.TabbedOut, 3 )
            net.WriteBool( not hasFocus )
        net.SendToServer()
        lastTabbedOut = hasFocus
        return
    end

    if lastMainmenu ~= gui.IsGameUIVisible() then
        net.Start( "CFC_AttentionMonitor" )
            net.WriteUInt( CFCAttentionMonitor.Enums.Mainmenu, 3 )
            net.WriteBool( gui.IsGameUIVisible() )
        net.SendToServer()
        lastMainmenu = gui.IsGameUIVisible()
        return
    end
end )

-- Spawnmenu detection
hook.Add( "SpawnMenuOpened", "CFC_AttentionMonitor_SpawnMenuOpen", function()
    net.Start( "CFC_AttentionMonitor" )
        net.WriteUInt( CFCAttentionMonitor.Enums.Spawnmenu, 3 )
        net.WriteBool( true )
    net.SendToServer()
end )

hook.Add( "OnSpawnMenuClose", "CFC_AttentionMonitor_SpawnMenuClose", function()
    net.Start( "CFC_AttentionMonitor" )
        net.WriteUInt( CFCAttentionMonitor.Enums.Spawnmenu, 3 )
        net.WriteBool( false )
    net.SendToServer()
end )

-- Chatbox detection
hook.Add( "StartChat", "CFC_AttentionMonitor_ChatboxOpen", function()
    net.Start( "CFC_AttentionMonitor" )
        net.WriteUInt( CFCAttentionMonitor.Enums.Chatbox, 3 )
        net.WriteBool( true )
    net.SendToServer()
end )

hook.Add( "FinishChat", "CFC_AttentionMonitor_ChatboxClose", function()
    net.Start( "CFC_AttentionMonitor" )
        net.WriteUInt( CFCAttentionMonitor.Enums.Chatbox, 3 )
        net.WriteBool( false )
    net.SendToServer()
end )
