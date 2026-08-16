-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 1
local omarchy_monitor_scale = 1.25

local primary = "desc:Dell Inc. Dell S2417DG #ASM4NFO2WRbd"
local secondary = "desc:LG Electronics LG ULTRAWIDE 0x0008A4E9"

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = primary, mode = "2560x1440@144", position = "0x0", scale = omarchy_monitor_scale })
hl.monitor({ output = secondary, mode = "preferred", position = "2048x-448", scale = omarchy_monitor_scale, transform = 3 })
hl.workspace_rule({ workspace = "6", monitor = secondary, default = true, persistent = true })
