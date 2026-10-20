-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Let XWayland games use the Dell's display modes, regardless of connector.
o.launch_on_start("/home/rnoh/.local/bin/xwayland-primary-monitor")

-- Start Super Productivity in the background after login.
o.launch_on_start("/home/rnoh/.local/bin/super-productivity-start-in-tray")

require("hypr.boot-dashboard").install()
