local tabbedOutList = {}
local Icon = Material( "icon16/application_double.png" ) -- the afk icon

timer.Create( "tabNetTimmer", 1, 0, function()
	if not system.HasFocus() then -- called when the client tabs out
		net.Start( "tabbedOut" )
		net.SendToServer()
	else -- called when the client tabs back in
		net.Start( "tabbedIn" )
		net.SendToServer()
	end

	net.Receive( "sendData", function() -- receives the players that tabbed out
		tabbedOutList = net.ReadTable()
	end )
end )

hook.Add( "PostDrawTranslucentRenderables", "icon", function()
	for _, v in ipairs( tabbedOutList ) do -- draws the icon for each tabbed out player

		render.SetColorMaterial() -- Place Holder
		render.DrawSphere( v:GetPos() + Vector( 0, 0, 75 ), 6,10, 10, Color( 0, 55, 255) ) -- Place Holder
		render.DrawSphere( v:GetPos() + Vector( 0, 0, 75 ), 4,10, 10, Color( 255, 255, 255) ) -- Place Holder

	end
end )