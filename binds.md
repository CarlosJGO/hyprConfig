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
| `SUPER + Home` | Toggle **juguetes** tiled |
| `SUPER + SHIFT + Home` | Toggle **juguetes** floating |
| `SUPER + Escape` | Modo kill de Hyprland (click para matar ventana) |
| `SUPER + SHIFT + SPACE` | Minimizar / scratchpad “minimizados” |
| `SUPER + ALT + CONTROL + SPACE` | Toggle special workspace `minimizados` |
| `SUPER + CONTROL + SHIFT + Up/Down` | Mueve **todo** el contenido del workspace al siguiente/anterior |

---

## Ventanas

| Bind | Qué hace |
|------|----------|
| `SUPER + Q` | Cerrar ventana activa |
| `SUPER + ALT + Space` | Toggle float |
| `SUPER + D` | Maximize (fullscreen mode 1) |
| `SUPER + F` | Fullscreen |
| `SUPER + J` | Dwindle: togglesplit |
| `SUPER + Left/Right/Up/Down` | Mover foco |
| `ALT + Tab` | Ciclar ventanas |
| `SUPER + Tab` | Window switcher (Noctalia) |
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
| `SUPER + Space` | Jugoo launcher |
| `SUPER + .` (period) | Jugoo emoji picker |
| `SUPER + V` | Jugoo clipboard |
| `SUPER + Z` | Noctalia settings |
| `SUPER + X` | Noctalia control center |
| `SUPER + A` | Notificaciones (control center) |
| `SUPER + L` | Bloquear sesión |
| `SUPER + ALT + C` | Panel de sesión Noctalia |
| `SUPER + SHIFT + W` | Panel de wallpapers Noctalia |

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

- **Abrir/cerrar tiled:** `SUPER + Home`
- **Abrir/cerrar floating:** `SUPER + SHIFT + Home`
- Segunda pulsación (cualquier variante) cierra todos y limpia procesos huérfanos.
- Lista editable: ver `curiosidades.md`.
