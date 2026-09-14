-- Auto-start config
-- if you dont use UWSM add your auto start programs here, otherwise use XDG autostart https://wiki.archlinux.org/title/XDG_Autostart
hl.on("hyprland.start", function ()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("waywallen")
    hl.exec_cmd("xhost +SI:localuser:root")
    hl.exec_cmd("touch /tmp/hypr-start-ran")
    hl.exec_cmd("sh -c 'qs -c overview > /tmp/jugoo-overview.log 2>&1 &'")
    hl.exec_cmd("/bin/sh -c 'exec \"${XDG_BIN_HOME:-$HOME/.local/bin}/jugoo\"'")
end)
