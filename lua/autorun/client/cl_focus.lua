local tabbedOutList = {}
local isTabbedOut = false

timer.Create( "CFC_AttentionMonitor_tabNetTimmer", 0.5, 0, function()
	local hasFocus = system.HasFocus()

	if isTabbedOut == hasFocus then return end

	net.Start( "CFC_AttentionMonitor_gameHasFocus" )
		net.WriteBool( hasFocus )
	net.SendToServer()
	isTabbedOut = hasFocus
end )

net.Receive( "CFC_AttentionMonitor_sendData", function() -- receives the players that tabbed out
	tabbedOutList = net.ReadTable()
end )

hook.Add( "PostDrawTranslucentRenderables", "afkRenderElements", function()
	for ply in pairs( tabbedOutList ) do -- draws the icon for each tabbed out player
		if not ply:IsValid() then return end
		if ply == LocalPlayer() then return end

		local icon = Material( "icon16/monitor.png", "$translucent" )

		render.SetMaterial( icon ) -- Place Holder
		render.DrawSprite( ply:GetPos() + Vector( 0, 0, 75 ), 16, 16, Color( 225, 225, 225, 255 ) ) -- place Holder
	end
end )