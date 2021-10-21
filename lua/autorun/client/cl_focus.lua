local tabbedOutList = {}
local isTabbedOut = false

timer.Create( "CFC_AttentionMonitor_tabNetTimmer", 1, 0, function()
	local hasFocus = system.HasFocus()

	if isTabbedOut ~= hasFocus then -- called when the client tabs out
		net.Start( "CFC_AttentionMonitor_gameHasFocus" )
			net.WriteBool( hasFocus )
		net.SendToServer()
		isTabbedOut = hasFocus
	end
end )

net.Receive( "CFC_AttentionMonitor_sendData", function() -- receives the players that tabbed out
	tabbedOutList = net.ReadTable()
end )

hook.Add( "PostDrawTranslucentRenderables", "afkRenderElements", function()
	for k, _ in pairs( tabbedOutList ) do -- draws the icon for each tabbed out player
		render.SetColorMaterial() -- Place Holder
		render.DrawSphere( k:GetPos() + Vector( 0, 0, 75 ), 6,10, 10, Color( 0, 55, 255) ) -- Place Holder
		render.DrawSphere( k:GetPos() + Vector( 0, 0, 75 ), 4,10, 10, Color( 255, 255, 255) ) -- Place Holder
	end
end )