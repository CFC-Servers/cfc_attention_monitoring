CFCAttentionMonitor = CFCAttentionMonitor or {}

-- Enums, should always be a indexed table, importantance is sorted from 1 to n
CFCAttentionMonitor.Enums = {
    TabbedOut = 1,
    Mainmenu = 2,
    Chatbox = 3,
    Spawnmenu = 4,
}
CFCAttentionMonitor.EnumCount = table.Count( CFCAttentionMonitor.Enums )
CFCAttentionMonitor.EnumsReverse = {}
for k, v in pairs( CFCAttentionMonitor.Enums ) do
    CFCAttentionMonitor.EnumsReverse[v] = k
end

if CLIENT then
    CFCAttentionMonitor.Icons = {
        [CFCAttentionMonitor.Enums.TabbedOut] = Material( "icon16/monitor.png", "3D mips" ),
        [CFCAttentionMonitor.Enums.Chatbox] = Material( "icon16/comment.png", "3D mips" ),
        [CFCAttentionMonitor.Enums.Spawnmenu] = Material( "icon16/application_view_icons.png", "3D mips" ),
        [CFCAttentionMonitor.Enums.Mainmenu] = Material( "icon16/application_view_detail.png", "3D mips" ),
    }
end
