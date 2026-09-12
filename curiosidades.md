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
- Cierre nativo / kill / muerte de proceso: `windowsOut` → `popin 65%` + `snappy` (POP).
- `SUPER+Q` (desintegración): pone `noanim` + alpha 0 **después** de que el overlay ya cubre la captura, para no disparar el POP ni pelear con el efecto.
- Movimientos / recolocado de floats: `windowsMove` con `smoothOut`.
- Layers globales: `fade` (evitar `slide` en overlays: parece que “suben/caen”).
- **hyprfocus** (Vaxry): flash sutil al cambiar foco — no es animación de open/close.
- Puertas Jugoo (`shell-app-launcher`, `shell-clipboard-picker`, `shell-emoji-picker`): `no_anim` en layer rule + cierran con animación puerta GTK (no desintegración).

---

## Efectos con captura de imagen (patrón desintegración)

Idea clave: **Hyprland no puede aplicar shaders custom a una ventana real**. Lo que sí puedes hacer es congelar la ventana en un PNG, taparla con un overlay click-through que sí corre shaders, y recién entonces cerrar/ocultar la ventana de verdad. Visualmente es la ventana “haciendo” algo imposible (desintegrarse, morph, etc.).

### Piezas

| Pieza | Ruta | Rol |
|-------|------|-----|
| Launcher | `scripts/close_disintegrate.py` | Captura, handshake ready, close/`--overlay-only` |
| Overlay | `scripts/window_disintegrate/overlay.qml` | Quickshell `PanelWindow` + placa + `ShaderEffect` |
| Shader | `scripts/window_disintegrate/disintegrate.frag` (+ `.qsb`) | Efecto (Qt 6 / qsb) |
| Bind / gesto | `config/binds.lua`, `config/inputs.lua` | `SUPER+Q` y swipe 3 dedos ↓ |
| Layer rule | `config/windowrules.lua` → `hypr-disintegrate-passthrough` | `no_anim` en namespace `hypr-window-disintegrate` |
| Jugoo (opcional) | `~/.config/jugoo/shell/ui/disintegrate_hide.py` | Misma lógica sobre la **tarjeta**, no el layer fullscreen |

Deps: `grim`, `qs` (Quickshell), `qt6-shadertools` (`/usr/lib/qt6/bin/qsb`).

Experimentos viejos: `Deprecados/close_gravity.py`, `Deprecados/close_smart.py`.

### Flujo (ventana Hyprland normal)

```
1. grim -g "x,y wxh" → PNG temporal          # ventana AÚN visible
2. qs -d -p overlay.qml                      # overlay encima, mismo rect
3. overlay pinta “placa” sólida (Image)      # copia 1:1 de la captura
4. escribe flag READY                        # handshake anti-parpadeo
5. Python espera el flag
6. setprop noanim + alpha 0 → window.close()  # close limpio, sin POP
7. ShaderEffect anima progress 0→1           # el “efecto imposible”
8. overlay borra PNG y Qt.quit()
```

**Por qué el handshake:** si ocultas la ventana antes de que el overlay esté mapeado, hay un frame vacío → parpadeo. La placa debe estar encima **antes** de tocar alpha/close.

**Click-through:** `mask: Region { width: 0; height: 0 }` + `focusable: false` + `WlrKeyboardFocus.None` para no robar foco ni bloquear cierres en paralelo.

**Fire-and-forget:** `qs -d` + sin lock global → varias desintegraciones a la vez.

### Flujo Jugoo (layers)

Las “ventanas” Jugoo type puerta/settings son **GtkLayerShell** (a menudo fullscreen con backdrop). `activewindow` de Hyprland no es eso.

- Geometría útil = **tarjeta** (`_door` / `launcher-card-host`), no el layer entero.
- Origen global: `hyprctl layers -j` (namespace) o `clients` (título), **no** `Gdk.get_origin()` (en Wayland suele mentir).
- Modo: `close_disintegrate.py --overlay-only -g "x,y wxh"` → Jugoo hace `hide()` cuando el script ya esperó READY.
- Puertas (launcher/clipboard/emoji): **siguen con puerta**; no pasan por desintegración.

### Shader Qt 6 (reglas que duelen si se olvidan)

1. Compilar con qsb, no GLSL inline:
   `/usr/lib/qt6/bin/qsb --glsl 100es,120,150 --hlsl 50 --msl 12 -o foo.frag.qsb foo.frag`
2. Uniform block: `mat4 qt_Matrix` @0, `float qt_Opacity` @64, luego tus floats.
3. Sampler `source` en binding 1; al inicio `progress=0` debe verse **igual** que la captura (travel=0) o hay flash.
4. Evitar flicker/spin agresivo → se ve “hormigueo”; preferir shards/voronoi con fade limpio.
5. Recompilar el `.qsb` cada vez que toques el `.frag`.

### Cómo clonar el patrón para otro efecto

1. Copiar `scripts/window_disintegrate/` → p. ej. `window_morph/`.
2. Nuevo `.frag` + `.qsb` (mismas reglas de uniforms).
3. Clonar/adaptar `close_disintegrate.py` (o parametrizar efecto por env/`--effect`).
4. Mantener el handshake READY + placa sólida + hide/close **después**.
5. Bind que llame al script; layer rule `no_anim` para el namespace del overlay.
6. Si el target no es xdg-window (layer/popup), calcular geometría del **contenido visible**, no del surface fullscreen.

Knobs útiles (env):

- `HYPR_DISINTEGRATE_DURATION_MS` (default ~550)
- `HYPR_DISINTEGRATE_BLOCK_SIZE` (voronoi scale, default ~0.018)
- `HYPR_DISINTEGRATE_INTENSITY`
- `HYPR_DISINTEGRATE_READY_TIMEOUT`

### Lecciones aprendidas

| Síntoma | Causa típica | Fix |
|---------|--------------|-----|
| Parpadeo al empezar | Hide antes del overlay / swap placa↔shader | READY flag; placa debajo unos frames |
| “Se va para arriba” | `layers=slide` en el overlay | `fade` + layer `no_anim` |
| Gravity/POP tras el efecto | `close`/`kill` con windowsOut activo | `noanim` antes del close; usar **close** no kill |
| Efecto a pantalla completa (Jugoo) | Capturaste el layer entero | Geometría de la tarjeta + hyprctl layers |
| Hormigueo / ruido | Shader con flicker/UV loco | Shards coherentes, travel 0 en t=0 |
| Muy cuadrado | Grid regular chico | Voronoi / celdas irregulares |
| Kill mata el proceso “feo” | `window.kill` | `window.close` para cierre limpio; kill solo para POP nativo |

---

## Scripts útiles

| Script | Ruta | Uso |
|--------|------|-----|
| Desintegrar / close | `~/.config/hypr/scripts/close_disintegrate.py` | `SUPER+Q`, gesto ↓, Jugoo `--overlay-only` |
| Minimizados | `~/.config/hypr/scripts/toggle_minimizados.py` | Scratchpad de minimizados |
| Mover todo un workspace | `~/.config/hypr/scripts/move_workspace_contents.py` | `SUPER+CTRL+SHIFT+Up/Down` |
| Wallpapers | `~/.config/hypr/scripts/wallpaper-*.sh` | (binds comentados / legacy) |
| Fondos special | `~/.config/hypr/scripts/special_backgrounds.py` | Capas de special WS |

`close_gravity.py` / `close_smart.py` → `Deprecados/`. Cierre visual activo: desintegración (`SUPER+Q`) + POP nativo en kill.

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
| `qs` / Quickshell | overlay de efectos (desintegración) |
| `grim` | captura de región para efectos |
| `noctalia msg` | volumen, brillo, paneles, lock |
| `~/.local/bin/audio-toggle` | `SUPER + M` |
| `~/.local/bin/ocr-wayland.sh` | `SUPER + SHIFT + X` |

---

## Docs hermanas

- Binds detallados: [`binds.md`](./binds.md)
