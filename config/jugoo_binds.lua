-- Managed by Jugoo acomodador.py. Prefer editing the copy under packaging/hyprland/.
-- Only keep non-conflicting custom binds here.

local mainMod = "SUPER"
local youtubeMusic = "BROWSER='" .. BROWSER .. "' jugoo-youtube-music"

-- This is intentionally the only custom Jugoo bind here: the main launcher / tray /
-- radial bindings live in ~/.config/hypr/config/binds/launcher.lua and must remain
-- the authoritative keys for the shell.
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd(youtubeMusic), { locked = true })
