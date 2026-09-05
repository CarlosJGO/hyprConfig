-- Auto-start config
-- if you dont use UWSM add your auto start programs here, otherwise use XDG autostart https://wiki.archlinux.org/title/XDG_Autostart
hl.on("hyprland.start", function ()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("noctalia")
    hl.exec_cmd("waywallen")
    hl.exec_cmd("xhost +SI:localuser:root")
    --hl.exec_cmd("/home/carlosjgo/.config/hypr/scripts/special_backgrounds.py")

    --hl.exec_cmd("/bin/sh -c 'mkdir -p \"${XDG_RUNTIME_DIR}/wallpaper-engine\" && systemctl --user daemon-reload && systemctl --user reset-failed wallpaper-auto.service 2>/dev/null; systemctl --user stop wallpaper-auto.service 2>/dev/null; systemctl --user start wallpaper-auto.service'")

    hl.exec_cmd("/bin/sh -c 'exec \"${XDG_BIN_HOME:-$HOME/.local/bin}/jugoo\"'")
end)