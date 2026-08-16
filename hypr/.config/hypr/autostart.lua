-- Extra autostart processes.
-- o.launch_on_start("my-service")

o.launch_on_start(o.launch_webapp("https://youtube.com"))
o.launch_on_start("discord")
o.launch_on_start("xdg-terminal-exec --app-id=org.omarchy.btop --title=btop btop")
