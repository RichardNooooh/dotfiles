-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Let XWayland games use the Dell's display modes, regardless of connector.
o.launch_on_start("/home/rnoh/.local/bin/xwayland-primary-monitor")

o.launch_on_start(o.launch_webapp("https://youtube.com"))
o.launch_on_start("discord")
o.launch_on_start("xdg-terminal-exec --app-id=org.omarchy.btop --title=btop btop")
