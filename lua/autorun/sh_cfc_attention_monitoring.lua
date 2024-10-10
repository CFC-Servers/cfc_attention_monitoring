CFCAttentionMonitor = CFCAttentionMonitor or {}

-- Enums, should always be a indexed table, importantance is sorted from 1 to n
CFCAttentionMonitor.Enums = {
    TabbedOut = 1,
    Chatbox = 2,
    Spawnmenu = 3,
}
CFCAttentionMonitor.EnumCount = table.Count( CFCAttentionMonitor.Enums )

if CLIENT then
    CFCAttentionMonitor.Icons = {
        [CFCAttentionMonitor.Enums.TabbedOut] = Material( "icon16/monitor.png", "3D mips" ),
        [CFCAttentionMonitor.Enums.Chatbox] = Material( "icon16/comment.png", "3D mips" ),
        [CFCAttentionMonitor.Enums.Spawnmenu] = Material( "icon16/application_view_icons.png", "3D mips" ),
    }
end
