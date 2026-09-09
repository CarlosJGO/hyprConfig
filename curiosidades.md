# Curiosidades y rutas importantes

Config raíz: `~/.config/hypr/`  
Entrada Lua: `~/.config/hypr/hyprland.lua`

---

## Juguetes de terminal

| Qué | Dónde |
|-----|--------|
| Lista para agregar/quitar a mano | `~/.config/hypr/config/juguetes.lua` → tabla `juguetes` |
| Binds | `SUPER + Home` (tiled) · `SUPER + SHIFT + Home` (floating) |

Cada entrada es `{ name = "...", run = "comando args" }`.  
Ejemplo para agregar uno:

```lua
{ name = "htop", run = "htop" },
```

**Comportamiento útil**

- Es **toggle**: si ya hay ventanas `juguete:*`, la próxima pulsación las mata y limpia huérfanos (`pipes.sh`, `cmatrix`, etc.).
- En floating, el **tamaño escala con la cantidad** (`float_size_for_count`): más juguetes → ventanas más chicas.
- Se abren **escalonados** (~280 ms) para que corra la animación `windowsIn`.
- Se lanzan con kitty directo (sin `uwsm`) para que el PID coincida con la ventana: float rules + kill limpian bien el proceso hijo.

Juguetes actuales: `cmatrix`, `lavat`, `pipes.sh`, `cava`, `cbonsai -l`, `genact`, `asciiquarium`.

---

## Flotantes que se recolocan solos

| Qué | Dónde |
|-----|--------|
| Lógica | `~/.config/hypr/config/float_place.lua` |
| Carga | `require("config.float_place")` en `hyprland.lua` |

Hyprland **no** tiene una windowrule nativa de “si solapa, muévete”.  
Al evento `window.open`, si la ventana es flotante y se monta encima de otra del mismo workspace, busca un hueco en el monitor y la desplaza con `hl.dsp.window.move` — animado por `windowsMove` (curva smooth en `animations.lua`).

Ignora popups Jugoo, pinned y fullscreen.

---

## Animaciones

| Qué | Dónde |
|-----|--------|
| Curvas + tree | `~/.config/hypr/config/animations.lua` |
| Flash al enfocar (plugin) | `~/.config/hypr/config/hyprfocus.lua` |

Notas:

- Cierre de flotantes: caída `gravity` + `slide bottom` (`windowsOut`).
- Movimientos / recolocado de floats: `windowsMove` con `smoothIO`.
- **hyprfocus** (Vaxry): flash sutil al cambiar foco — no es animación de open/close.

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
