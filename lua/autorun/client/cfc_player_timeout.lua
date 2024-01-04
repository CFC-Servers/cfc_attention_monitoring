local timingOut = {}
local timingOutLookup = {}
local startDrawing, stopDrawing

do
    local table_insert = table.insert

    timer.Create( "CFC_AttentionMonitor_Timeout", 1, 0, function()
        timingOut = {}
        timingOutLookup = {}

        local empty = true
        local plys = player.GetAll()
        local plyCount = #plys

        for i = 1, plyCount do
            local ply = plys[i]
            if ply:GetNW2Bool( "CFC_AttentionMonitor_TimingOut" ) then
                empty = false

                timingOutLookup[ply] = true
                table_insert( timingOut, ply )
            end
        end

        if empty then
            stopDrawing()
        else
            startDrawing()
        end
    end )
end

do
    local default = { ["$pp_colour_colour"] = 1, }
    local grayscale = { ["$pp_colour_colour"] = 0 }
    local icon = Material( "cfc_attention_monitoring/no-wifi.png", "noclamp smooth" )

    local EntityMeta = FindMetaTable( "Entity" )
    local DrawModel = EntityMeta.DrawModel
    local Entity_IsValid = EntityMeta.IsValid
    local GetAttachment = EntityMeta.GetAttachment
    local GetModelScale = EntityMeta.GetModelScale
    local LookupAttachment = EntityMeta.LookupAttachment

    local AngleMeta = FindMetaTable( "Angle" )
    local Up = AngleMeta.Up
    local Right = AngleMeta.Right
    local Forward = AngleMeta.Forward
    local RotateAroundAxis = AngleMeta.RotateAroundAxis

    local STENCIL_KEEP = STENCIL_KEEP
    local STENCIL_ALWAYS = STENCIL_ALWAYS
    local STENCIL_REPLACE = STENCIL_REPLACE
    local DrawColorModify = DrawColorModify

    local cam_End3D2D = cam.End3D2D
    local cam_Start3D2D = cam.Start3D2D
    local surface_SetMaterial = surface.SetMaterial
    local surface_SetDrawColor = surface.SetDrawColor
    local surface_DrawTexturedRect = surface.DrawTexturedRect

    local render_SetStencilEnable = render.SetStencilEnable
    local render_SetStencilTestMask = render.SetStencilTestMask
    local render_SetStencilWriteMask = render.SetStencilWriteMask
    local render_SetStencilPassOperation = render.SetStencilPassOperation
    local render_SetStencilFailOperation = render.SetStencilFailOperation
    local render_SetStencilZFailOperation = render.SetStencilZFailOperation
    local render_SetStencilReferenceValue = render.SetStencilReferenceValue
    local render_SetStencilCompareFunction = render.SetStencilCompareFunction

    local function DrawTimedOutPlayers()
        render_SetStencilEnable( true )
        render_SetStencilWriteMask( 255 )
        render_SetStencilTestMask( 255 )
        render_SetStencilReferenceValue( 15 )

        -- Only write to the stencil buffer where the player is rendered
        render_SetStencilPassOperation( STENCIL_REPLACE )
        render_SetStencilFailOperation( STENCIL_KEEP )
        render_SetStencilZFailOperation( STENCIL_KEEP )

        for i = 1, plyCount do
            local ply = plys[i]
            local validWeapon = ply:GetActiveWeapon()
            validWeapon = Entity_IsValid( validWeapon ) and validWeapon

            render_SetStencilCompareFunction( STENCIL_ALWAYS )

            -- Draw the player model to the stencil buffer
            DrawModel( ply )
            if validWeapon then DrawModel( validWeapon ) end

            -- Use the stencil buffer where the player was drawn
            render_SetStencilCompareFunction( STENCIL_EQUAL )

            -- Draw the player model with the grayscale material
            DrawColorModify( grayscale )
            DrawModel( ply )
            if validWeapon then DrawModel( validWeapon ) end

            DrawColorModify( default )
        end

        render_SetStencilEnable( false )

        local iconSize = 3
        local offset = -1 * (iconSize / 2)

        -- Draw the icons in front of their faces
        for i = 1, plyCount do
            local ply = plys[i]
            local attach_id = LookupAttachment( ply, "eyes" )
            local attach = attach_id and GetAttachment( ply, attach_id )

            if attach then
                local pos = attach.Pos
                local ang = attach.Ang

                local angUp = Up( ang )

                pos = pos + ( Forward( ang ) * 2 )
                pos = pos + ( angUp * 3 )
                RotateAroundAxis( ang, Right( ang ), -90 )
                RotateAroundAxis( ang, angUp, 90 )

                cam_Start3D2D( pos, ang, GetModelScale( ply ) )
                surface_SetMaterial( icon )
                surface_SetDrawColor( 255, 255, 255, 255 )
                surface_DrawTexturedRect( offset, offset, iconSize, iconSize )
                cam_End3D2D()
            end
        end
    end

    startDrawing = function()
        hook.Add( "PostDrawOpaqueRenderables", "CFC_AttentionMonitor_DrawTimeouts", DrawTimedOutPlayers )
    end

    stopDrawing = function()
        hook.Remove( "PostDrawOpaqueRenderables", "CFC_AttentionMonitor_DrawTimeouts" )
    end
end


do
    local math_huge = math.huge

    hook.Add( "PrePlayerDraw", "CFC_AttentionMonitor_TimeoutAnimations", function( ply )
        if not timingOutLookup[ply] then return end
        ply:SetAnimTime( math_huge )
    end )
end
