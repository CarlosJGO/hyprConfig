# Binds de Hyprland

`mainMod` = **SUPER** (tecla Windows).

Fuente principal: `~/.config/hypr/config/binds.lua`  
Juguetes: `~/.config/hypr/config/juguetes.lua`  
Gestos: `~/.config/hypr/config/inputs.lua`

---

## Destacados / poco obvios

| Bind | Qué hace |
|------|----------|
| `SUPER + P` | **hyprpicker** — selector de color (copia al clipboard, `-a -n`) |
| `SUPER + SHIFT + P` | Screenshot **completo** con Flameshot → `~/Pictures` |
| `SUPER + SHIFT + C` | Screenshot de **región** (Flameshot GUI) |
| `SUPER + SHIFT + X` | OCR de pantalla (`~/.local/bin/ocr-wayland.sh`) |
| `SUPER + M` | Toggle salida de audio (auriculares ↔ parlantes) |
| `SUPER + Home` | Toggle **juguetes** tiled (reparte partiendo la ventana más grande; no sigue el mouse) |
| `SUPER + SHIFT + Home` | Toggle **juguetes** en rejilla flotante fija |
| `SUPER + Escape` | Modo kill de Hyprland (click para matar ventana) |
| `SUPER + Delete` | **Apagar el PC** (`systemctl poweroff`, apagado limpio) |
| `SUPER + SHIFT + SPACE` | Minimizar / scratchpad “minimizados” |
| `SUPER + ALT + CONTROL + SPACE` | Toggle special workspace `minimizados` |
| `SUPER + CONTROL + SHIFT + Up/Down` | Mueve **todo** el contenido del workspace al siguiente/anterior |

---

## Ventanas

| Bind | Qué hace |
|------|----------|
| `SUPER + Q` | Cerrar ventana activa |
| `SUPER + ALT + Space` | Toggle float |
| `SUPER + D` | Maximize (`layout_aware=false`: crece encima, al salir restaura el layout) |
| `SUPER + F` | Fullscreen (igual) |
| `SUPER + J` | Dwindle: togglesplit |
| `SUPER + Left/Right/Up/Down` | Mover foco |
| `ALT + Tab` | Ciclar ventanas |
| `SUPER + Tab` | Ciclar ventanas (Hyprland; Jugoo no tiene window-switcher) |
| `SUPER + SHIFT + flechas` | Mover ventana en esa dirección |
| `SUPER + SHIFT + 1/2/3` | Mover ventana al monitor 1/2/3 |
| `SUPER + SHIFT + scroll` | Mover ventana a monitor ±1 |
| `SUPER + CONTROL + SHIFT + Left/Right` | Mover ventana a workspace m±1 |
| `SUPER + CONTROL + SHIFT + scroll` | Idem con rueda |
| `SUPER + CONTROL + SHIFT + 1..N` | Mover a workspace relativo del monitor (`m~N`) |
| `SUPER + click izq` | Arrastrar ventana |
| `SUPER + click der` | Redimensionar ventana |

---

## Launchers / apps

| Bind | Qué hace |
|------|----------|
| `SUPER + Return` | Terminal (kitty vía uwsm) |
| `SUPER + E` | File manager (Dolphin) |
| `SUPER + T` | Editor de texto |
| `SUPER + C` | Calculadora |
| `SUPER + K` | Cámara (Snapshot) |
| `SUPER + O` | Obsidian |
| `SUPER + W` | Navegador (Zen) |
| `SUPER + Space` | Jugoo launcher (`jugoo action launcher`) |
| `SUPER + .` (period) | Jugoo emoji picker |
| `SUPER + V` | Jugoo clipboard |
| `SUPER + Z` | Jugoo settings (también desde Search) |
| `SUPER + X` | Jugoo control center |
| `SUPER + A` | Jugoo notificaciones |
| `SUPER + L` | Bloquear sesión (`loginctl lock-session`) |
| `SUPER + ALT + C` | Jugoo menú de sesión / power |
| `SUPER + Delete` | Apagar el sistema (`systemctl poweroff`) |
| `SUPER + SHIFT + W` | Wallpaper (`waywallen`; no es panel Jugoo) |

---

## Workspaces y monitores

| Bind | Qué hace |
|------|----------|
| `SUPER + 1..N` | Ir al workspace N (`NUM_WPM` en `variables.lua`) |
| `SUPER + TAB + 1..N` | Idem (absoluto) |
| `SUPER + CONTROL + 1..N` | Workspace relativo del monitor (`m~N`) |
| `SUPER + CONTROL + Left/Right` | Workspace m±1 |
| `SUPER + CONTROL + Down` | Siguiente workspace vacío del monitor |
| `SUPER + scroll` | Cambiar workspace m±1 |
| `SUPER + CONTROL + scroll` | Idem |
| `SUPER + S` | Toggle special (scratchpad) |
| `SUPER + SHIFT + S` | Enviar ventana al special |
| `SUPER + SHIFT + CONTROL + Space` | Restaurar todos los minimizados |

`N` = `NUM_WPM` (ahora 3) en `config/variables.lua`.

---

## Hardware / media

| Bind | Qué hace |
|------|----------|
| Teclas de volumen / mute / mic | Noctalia volume |
| Play / Pause / Next / Prev | Noctalia media |
| Brillo ± | Noctalia brightness |

---

## Gestos (trackpad)

| Gesto | Qué hace |
|-------|----------|
| 4 dedos horizontal | Cambiar workspace |
| 3 dedos ↓ | Cerrar ventana |
| 3 dedos ↑ | Fullscreen |
| 3 dedos ← | Toggle float |

---

## Juguetes (resumen)

- **Tiled:** `SUPER + Home` (parte siempre la más grande; no sigue el mouse)
- **Floating grid:** `SUPER + SHIFT + Home`
- Segunda pulsación cierra todos.
- Lista editable: ver `curiosidades.md`.
