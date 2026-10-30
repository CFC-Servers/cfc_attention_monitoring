local HasFocus = system.HasFocus
local Entity = Entity
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
    local hours = math_floor( time / 3600 )
    local minutes = math_floor( ( time % 3600 ) / 60 )

    if hours ~= 0 then
        timeStr = timeStr .. hours .. "h"
    end

    if minutes ~= 0 then
        if hours ~= 0 then
            timeStr = timeStr .. " "
        end

        timeStr = timeStr .. minutes .. "m"
    end

    return timeStr
end

local function drawIcon( index, plyTbl, eyePos, angle )
    local ply = Entity( index )
    if not isValid( ply ) then return end

    if ply == LocalPlayer() then return end
    if not isAlive( ply ) then return end
    if isDormant( ply ) then return end
    if getRenderMode( ply ) == RENDERMODE_TRANSALPHA then return end

    -- Position
    local headBone = lookupBone( ply, "ValveBiped.Bip01_Head1" ) or 0
    local matrix = getBoneMatrix( ply, headBone )
    if not matrix then return end

    local pos = matrix:GetTranslation()
    pos:Add( spriteBoneOffset )

    -- Fade, checked before screen projection so distant players get skipped early
    local dist = pos:DistToSqr( eyePos )
    if dist > fadeEnd then return end

    local screenPos = pos:ToScreen()
    if not screenPos.visible then return end

    local x = screenPos.x
    if x < 0 or x > scrW then return end
    local y = screenPos.y
    if y < 0 or y > scrH then return end

    if dist > fadeStart then
        fadeColor.a = 255 * ( 1 - ( dist / fadeEnd ) )
    else
        fadeColor.a = 255
    end

    local icon = CFCAttentionMonitor.Icons[plyTbl.type]

    cam_Start3D2D( pos, angle, 0.05 )
        render_PushFilterMag( TEXFILTER_POINT )
        surface_SetMaterial( icon )
        surface_SetDrawColor( fadeColor )
        surface_DrawTexturedRect( -iconSize / 2, -iconSize / 2, iconSize, iconSize )
        render_PopFilterMag()

        local afktime = CurTime() - plyTbl.statusTime
        if afktime > 60 then
            local minutes = math_floor( afktime / 60 )
            if plyTbl.afkMinutes ~= minutes then
                plyTbl.afkMinutes = minutes
                plyTbl.timeStr = formatAfkTime( afktime )
            end

            draw_SimpleTextOutlined( plyTbl.timeStr, timeFont, 0, 60, fadeColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, fadeColor )
        end
    cam_End3D2D()
end

local function drawIcons( _, _, skybox3d )
    if skybox3d then return end
    if not next( trackedPlayers ) then return end

    local eyePos = EyePos()
    local angle = EyeAngles()
    angle:RotateAroundAxis( angle:Right(), 90 )

    local up = angle:Up()
    up:Negate()
    angle:RotateAroundAxis( up, 90 )

    for index, plyTbl in pairs( trackedPlayers ) do
        drawIcon( index, plyTbl, eyePos, angle )
    end
end

hook.Add( "PostDrawTranslucentRenderables", "CFC_AttentionMonitor_AfkRenderElements", drawIcons )

net.Receive( "cfc_attentionmonitor", function()
    local index = net.ReadUInt( MAX_PLAYER_BITS )
    local statusType = net.ReadUInt( 3 )

    if statusType == 0 then
        trackedPlayers[index] = nil
        return
    end

    local statusTime = net.ReadFloat()

    local plyTbl = trackedPlayers[index]
    if not plyTbl then
        trackedPlayers[index] = { type = statusType, statusTime = statusTime }
        return
    end

    plyTbl.type = statusType
    plyTbl.statusTime = statusTime
end )

-- Tabbed out detection
local lastTabbedOut = false
local lastMainmenu = false
timer.Create( "CFC_AttentionMonitor_TabNetTimer", 0.2, 0, function()
    local hasFocus = HasFocus()
    if lastTabbedOut ~= hasFocus then
        net.Start( "cfc_attentionmonitor" )
            net.WriteUInt( CFCAttentionMonitor.Enums.TabbedOut, 3 )
            net.WriteBool( not hasFocus )
        net.SendToServer()
        lastTabbedOut = hasFocus
        return
    end

    local gameUIVisible = gui.IsGameUIVisible()
    if lastMainmenu ~= gameUIVisible then
        net.Start( "cfc_attentionmonitor" )
            net.WriteUInt( CFCAttentionMonitor.Enums.Mainmenu, 3 )
            net.WriteBool( gameUIVisible )
        net.SendToServer()
        lastMainmenu = gameUIVisible
        return
    end
end )

-- Spawnmenu detection
hook.Add( "SpawnMenuOpened", "CFC_AttentionMonitor_SpawnMenuOpen", function()
    net.Start( "cfc_attentionmonitor" )
        net.WriteUInt( CFCAttentionMonitor.Enums.Spawnmenu, 3 )
        net.WriteBool( true )
    net.SendToServer()
end )

hook.Add( "OnSpawnMenuClose", "CFC_AttentionMonitor_SpawnMenuClose", function()
    net.Start( "cfc_attentionmonitor" )
        net.WriteUInt( CFCAttentionMonitor.Enums.Spawnmenu, 3 )
        net.WriteBool( false )
    net.SendToServer()
end )

-- Chatbox detection
hook.Add( "StartChat", "CFC_AttentionMonitor_ChatboxOpen", function()
    net.Start( "cfc_attentionmonitor" )
        net.WriteUInt( CFCAttentionMonitor.Enums.Chatbox, 3 )
        net.WriteBool( true )
    net.SendToServer()
end )

hook.Add( "FinishChat", "CFC_AttentionMonitor_ChatboxClose", function()
    net.Start( "cfc_attentionmonitor" )
        net.WriteUInt( CFCAttentionMonitor.Enums.Chatbox, 3 )
        net.WriteBool( false )
    net.SendToServer()
end )
