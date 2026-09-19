# Hyprland config

Este repositorio contiene mi configuración personal de Hyprland, junto con scripts auxiliares para mejorar la experiencia visual y la gestión de ventanas.

## Estructura principal

- `hyprland.conf` — configuración principal de Hyprland.
- `hyprland.lua` — configuración adicional en Lua.
- `hyprlock.conf` — configuración del bloqueo de pantalla.
- `hypridle.conf` — configuración del idle / suspensión.
- `xdph.conf` — configuración de XDG.
- `config/` — módulos y ajustes adicionales de Hyprland.
- `scripts/` — utilidades y automatizaciones.
- `shaders/` — shaders personalizados.
- `Deprecados/` — scripts antiguos o no usados.

## Carpetas importantes

### `config/`
Contiene la lógica modular de la configuración:

- `animations.lua`
- `autostart.lua`
- `binds.lua`
- `colors.lua`
- `decorations.lua`
- `environment.lua`
- `inputs.lua`
- `misc.lua`
- `monitors.lua`
- `variables.lua`
- `windowrules.lua`
- `workspaces.lua`

### `scripts/`
Suelen incluir funciones para:

- mover ventanas o espacios de trabajo
- gestionar minimizados
- animaciones o efectos visuales
- automatizaciones de entorno

### `shaders/`
Archivos GLSL usados para efectos visuales y transformaciones gráficas.

## Arranque

Normalmente la configuración se aplica al iniciar Hyprland desde el gestor de sesión o al ejecutar:

```bash
hyprland
```

Si quieres recargar la configuración sin cerrar la sesión:

```bash
hyprctl reload
```

## Recomendaciones

- Mantén copias de seguridad antes de tocar configuración crítica.
- Si agregas archivos temporales, backups o estados locales, añádelos a `.gitignore`.
- Revisa los scripts de `scripts/` antes de ejecutarlos si cambias el entorno.

## Notas

Este proyecto está pensado para uso personal y personalización local. Algunos scripts pueden depender de herramientas del sistema o de paquetes específicos instalados en el equipo.

## Licencia

No hay licencia específica definida en este repositorio; se usa como configuración personal.
