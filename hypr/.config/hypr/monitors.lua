-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 1
local omarchy_monitor_scale = 1.25

local primary = "desc:Dell Inc. Dell S2417DG #ASM4NFO2WRbd"
local secondary = "desc:LG Electronics LG ULTRAWIDE 0x0008A4E9"

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = primary, mode = "2560x1440@144", position = "0x0", scale = omarchy_monitor_scale })
hl.monitor({ output = secondary, mode = "preferred", position = "2048x-448", scale = omarchy_monitor_scale, transform = 3 })

-- Number keys 1–5 use the Dell; 6–0 (workspaces 6–10) use the LG.
for workspace = 1, 10 do
  hl.workspace_rule({
    workspace = tostring(workspace),
    monitor = workspace <= 5 and primary or secondary,
    default = workspace == 1 or workspace == 6,
    persistent = true,
  })
end
