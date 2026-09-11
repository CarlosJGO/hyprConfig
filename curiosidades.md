# Curiosidades y rutas importantes

Config raíz: `~/.config/hypr/`  
Entrada Lua: `~/.config/hypr/hyprland.lua`

---

## Juguetes de terminal

| Qué | Dónde |
|-----|--------|
| Lista para agregar/quitar a mano | `~/.config/hypr/config/juguetes.lua` → tabla `juguetes` |
| Binds | `SUPER + Home` (tiled) · `SUPER + SHIFT + Home` (rejilla flotante) |

Cada entrada:

```lua
{
  name = "cbonsai",
  run = "cbonsai -l",
  -- opcional, solo SHIFT+Home (floating):
  size = { "monitor_w * 0.18", "monitor_h * 0.58" },
  -- opcional: kitty más chico = más “píxeles” (lavat, etc.)
  font_size = 7,
},
```

**Comportamiento útil**

- Es **toggle**: si ya hay ventanas `juguete:*`, la próxima pulsación las mata y limpia huérfanos.
- **Home (tiled):** spawnea sin float; antes de cada una enfoca la juguete más grande y mueve el cursor a su centro, para que dwindle parta espacio de forma más pareja sin seguir tu mouse. `size` no aplica (lo decide el layout).
- **SHIFT+Home (floating):** rejilla fija; `size` custom se centra en su celda. Sin `size` → celda uniforme.
- `font_size` baja la fuente de kitty para que demos ASCII (p. ej. lavat) se vean en ventanas chicas.
- Escalados (~240 ms) entre spawns.
- Kitty directo (sin `uwsm`) para reglas + kill limpios.

Juguetes actuales: `cmatrix`, `lavat` (font 7 + radio chico), `pipes.sh`, `cava`, `cbonsai` (vertical), `genact`, `asciiquarium`, `tty-clock` (centrado + segundos, `nyancat`.

## Cómo añadir otro la próxima vez
Archivo: ~/.config/hypr/config/juguetes.lua
Instala el binario (tty-clock, cmatrix, etc.).
Añade una fila en la tabla juguetes:
{ name = "mi-toy", run = "mi-toy --flags" },
-- opcional:
-- font_size = 7,
-- size = { "monitor_w * 0.28", "monitor_h * 0.22" },  -- solo floating
Limpieza al cerrar — en cleanup_orphan_toys(), un pkill del proceso ( -x si es un binario limpio; -f si es script/ruta).
hyprctl reload.

---

## Flotantes que se recolocan solos

| Qué | Dónde |
|-----|--------|
| Lógica | `~/.config/hypr/config/float_place.lua` |
| Carga | `require("config.float_place")` en `hyprland.lua` |

**Opt-in:** solo mueve ventanas con tag `autoplace` o título `juguete:*` al **abrir flotantes**.
Solo reubica si se solapan con **otra flotante** (no pineada). Encima de tiled se quedan donde abrieron (p. ej. centradas).

**Despeje al abrir tiled:** si una ventana anclada aparece y flotantes la tapan, esas flotantes se apartan (animación `windowsMove`). Intentan no solaparse entre sí; pueden quedar parcialmente fuera de pantalla (sigue siendo agarrable).

Cómo se marca:

1. **Binds de apps** (`binds.lua` → `launch()`): añaden `tag = "+autoplace"` al lanzar.
2. **Windowrules** de tus floats “de verdad” (Dolphin principal, calc, editor, Noctalia settings, utils…): también `+autoplace`.
3. **Juguetes floating**: tag + título `juguete:*`.

**No** se marcan: modales genéricos, diálogos Steam/Audacity, popups Jugoo, etc.

Si añades otra app flotante tuya, pon `tag = "+autoplace"` en su windowrule o lánzala con `launch(...)`.

---

## Animaciones

| Qué | Dónde |
|-----|--------|
| Curvas + tree | `~/.config/hypr/config/animations.lua` |
| Flash al enfocar (plugin) | `~/.config/hypr/config/hyprfocus.lua` |

Se carga con `hyprpm reload` en el arranque (el plugin tiene que estar `hyprpm enable hyprfocus`).  
La config `plugin.hyprfocus.*` **solo se aplica si el plugin ya está cargado**; si no, Hyprland marca error de “unknown config key”.

Notas:

- Apertura de ventanas: `popin 55%` + spring `jelly` (crecen y rebotan un poco). Evitar bezier con Y>1 en popin: estira bordes y el contenido no acompaña.
- Maximize / fullscreen (`SUPER+D` / `F`): `layout_aware=false` — crece encima de las hermanas (animación al instante); al salir el layout vuelve como estaba.
- Cierre de flotantes: caída `gravity` + `slide bottom` (`windowsOut`).
- Movimientos / recolocado de floats: `windowsMove` con `smoothOut`.
- **hyprfocus** (Vaxry): flash sutil al cambiar foco — no es animación de open/close.
- Puertas Jugoo (`shell-app-launcher`, `shell-clipboard-picker`, `shell-emoji-picker`): `no_anim` en layer rule para no pelear con la animación puerta de GTK.

---

## Scripts útiles

| Script | Ruta | Uso |
|--------|------|-----|
| Minimizados | `~/.config/hypr/scripts/toggle_minimizados.py` | Scratchpad de minimizados |
| Mover todo un workspace | `~/.config/hypr/scripts/move_workspace_contents.py` | `SUPER+CTRL+SHIFT+Up/Down` |
| Wallpapers | `~/.config/hypr/scripts/wallpaper-*.sh` | (binds comentados / legacy) |
| Fondos special | `~/.config/hypr/scripts/special_backgrounds.py` | Capas de special WS |

`close_gravity.py` / `close_smart.py` quedaron de experimentos; el cierre activo es el nativo `SUPER+Q` → `hl.dsp.window.close()`.

---

## Otros módulos de config

| Archivo | Rol |
|---------|-----|
| `config/variables.lua` | `TERMINAL`, apps, `NUM_WPM`, monitores |
| `config/windowrules.lua` | Reglas (Jugoo, PiP, gaming, floats…) |
| `config/decorations.lua` | Gaps, bordes, blur, opacidades |
| `config/hyprfocus.lua` | Plugin flashfocus |
| `config/inputs.lua` | Teclado, gestos |
| `noctalia.lua` / `jugoo_theme_generated.lua` | Temas (Jugoo al final del load) |

---

## Apps / bins que tocan binds

| Bin | Bind / rol |
|-----|------------|
| `hyprpicker` | `SUPER + P` |
| `flameshot` | `SUPER + SHIFT + C/P` |
| `jugoo` | launcher, emoji, clipboard |
| `noctalia msg` | volumen, brillo, paneles, lock |
| `~/.local/bin/audio-toggle` | `SUPER + M` |
| `~/.local/bin/ocr-wayland.sh` | `SUPER + SHIFT + X` |

---

## Docs hermanas

- Binds detallados: [`binds.md`](./binds.md)
