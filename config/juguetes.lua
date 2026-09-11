-- Juguetes de terminal (toggle).
-- SUPER + Home         → tiled (reparte partiendo siempre la ventana más grande; ignora el mouse)
-- SUPER + SHIFT + Home → rejilla flotante fija (posiciones explícitas)
-- Toggle: si ya hay juguetes → cierra + limpia huérfanos; si no → abre.
--
-- Cada entrada:
--   name       título → "juguete:<name>"
--   run        comando que recibe kitty -e
--   size       opcional { w, h } expresiones Hyprland (solo floating; si falta → celda de la rejilla)
--   font_size  opcional número → kitty -o font_size=N (más chico = más detalle en la misma ventana)

local mainMod = "SUPER"
local spawnGapMs = 240
local titlePrefix = "juguete:"
local GAP_FRAC = 0.012

-- Edita esta lista para agregar/quitar.
local juguetes = {
    { name = "nyancat",      run = "nyancat", font_size = 5},
    { name = "cmatrix",      run = "cmatrix" },
    -- Lavat: radio/bolas más chicos + fuente kitty baja → se aprecia en celdas pequeñas.
    { name = "lavat",        run = "lavat -r 3 -b 8 -C", font_size = 1 },
    { name = "pipes.sh",     run = "pipes.sh" },
    { name = "cava",         run = "cava" },
    -- cbonsai: rectángulo vertical; el árbol necesita altura.
    {
        name = "cbonsai",
        run = "cbonsai -l",
        size = { "monitor_w * 0.18", "monitor_h * 0.58" },
    },
    { name = "genact",       run = "genact" },
    { name = "asciiquarium", run = "asciiquarium" },
    -- tty-clock: centrado, segundos, bold, colon parpadeante.
    {
        name = "tty-clock",
        run = "tty-clock -c -s -b -B",
        size = { "monitor_w * 0.28", "monitor_h * 0.22" },
    },
    
}

local spawning = false

local function list_juguete_windows()
    local found = {}
    for _, window in ipairs(hl.get_windows() or {}) do
        local title = window.title or ""
        if title:sub(1, #titlePrefix) == titlePrefix then
            found[#found + 1] = window
        end
    end
    return found
end

local function cleanup_orphan_toys()
    hl.exec_cmd(
        "pkill -f '/usr/bin/pipes.sh' >/dev/null 2>&1 || true; "
            .. "pkill -x cmatrix >/dev/null 2>&1 || true; "
            .. "pkill -x lavat >/dev/null 2>&1 || true; "
            .. "pkill -x cava >/dev/null 2>&1 || true; "
            .. "pkill -x cbonsai >/dev/null 2>&1 || true; "
            .. "pkill -x genact >/dev/null 2>&1 || true; "
            .. "pkill -f asciiquarium >/dev/null 2>&1 || true; "
            .. "pkill -x tty-clock >/dev/null 2>&1 || true; "
            .. "pkill -x nyancat >/dev/null 2>&1 || true"
    )
end

local function close_juguetes()
    spawning = false
    for _, window in ipairs(list_juguete_windows()) do
        hl.dispatch(hl.dsp.window.kill({ window = "address:" .. window.address }))
    end
    cleanup_orphan_toys()
end

local function vec2(v)
    if type(v) ~= "table" then
        return 0, 0
    end
    return tonumber(v[1] or v.x) or 0, tonumber(v[2] or v.y) or 0
end

local function window_area(window)
    local w, h = vec2(window.size)
    return w * h, w, h
end

-- Elige la juguete con más área para que dwindle parta esa (BSP más parejo).
local function focus_largest_juguete()
    local best, best_area, best_w, best_h = nil, -1, 0, 0
    for _, window in ipairs(list_juguete_windows()) do
        local area, ww, hh = window_area(window)
        if area > best_area then
            best_area = area
            best = window
            best_w, best_h = ww, hh
        end
    end
    if not best then
        return
    end

    local sel = "address:" .. best.address
    hl.dispatch(hl.dsp.focus({ window = sel }))

    -- Cursor al centro de esa ventana → dwindle no sigue donde tengas el mouse real.
    local x, y = vec2(best.at)
    local cx = x + best_w * 0.5
    local cy = y + best_h * 0.5
    hl.dispatch(hl.dsp.cursor.move({ x = cx, y = cy }))
end

-- Rejilla solo para modo floating (SHIFT+Home).
local function grid_slots(n)
    n = math.max(n, 1)
    local cols = math.ceil(math.sqrt(n))
    local rows = math.ceil(n / cols)

    local side = math.max(0.42, math.min(0.82, 0.38 + 0.12 * cols))
    local area_w = side
    local area_h = math.min(0.88, side * (rows / cols) * 1.05)
    local origin_x = (1.0 - area_w) * 0.5
    local origin_y = (1.0 - area_h) * 0.5

    local cell_w = area_w / cols
    local cell_h = area_h / rows
    local gap_x = cell_w * GAP_FRAC
    local gap_y = cell_h * GAP_FRAC
    local inner_w = cell_w - gap_x * 2
    local inner_h = cell_h - gap_y - gap_y

    local slots = {}
    for i = 1, n do
        local idx = i - 1
        local col = idx % cols
        local row = math.floor(idx / cols)
        local x = origin_x + col * cell_w + gap_x
        local y = origin_y + row * cell_h + gap_y
        slots[i] = {
            size = {
                string.format("monitor_w * %.4f", inner_w),
                string.format("monitor_h * %.4f", inner_h),
            },
            move = {
                string.format("monitor_w * %.4f", x),
                string.format("monitor_h * %.4f", y),
            },
            -- Fracciones de monitor de la celda (para centrar size custom).
            cell = {
                x = x,
                y = y,
                w = inner_w,
                h = inner_h,
            },
        }
    end
    return slots
end

-- size custom como fracciones "monitor_w * 0.18" → 0.18, o nil si no parsea.
local function parse_monitor_frac(expr, axis)
    if type(expr) ~= "string" then
        return nil
    end
    local needle = axis == "w" and "monitor_w" or "monitor_h"
    local a, b = expr:match(needle .. "%s*%*%s*([%d%.]+)")
    if a then
        return tonumber(a)
    end
    a = expr:match("([%d%.]+)%s*%*%s*" .. needle)
    return tonumber(a)
end

local function resolve_float_geometry(toy, slot)
    local move = slot.move
    local size = slot.size
    if type(toy.size) == "table" and toy.size[1] and toy.size[2] then
        size = { toy.size[1], toy.size[2] }
        local tw = parse_monitor_frac(toy.size[1], "w")
        local th = parse_monitor_frac(toy.size[2], "h")
        local cell = slot.cell
        if tw and th and cell then
            -- Centrar el tamaño pedido dentro de la celda de la rejilla.
            local x = cell.x + math.max(0, (cell.w - tw) * 0.5)
            local y = cell.y + math.max(0, (cell.h - th) * 0.5)
            move = {
                string.format("monitor_w * %.4f", x),
                string.format("monitor_h * %.4f", y),
            }
        end
    end
    return size, move
end

local function kitty_line(toy)
    local title = titlePrefix .. toy.name
    local opts = ""
    if toy.font_size ~= nil then
        opts = string.format(" -o font_size=%s", tostring(toy.font_size))
    end
    return string.format("%s%s --title %q -e %s", TERMINAL, opts, title, toy.run)
end

local function spawn_juguetes(asFloat)
    if spawning then
        return
    end
    spawning = true

    local count = #juguetes
    local slots = asFloat and grid_slots(count) or nil
    local i = 0

    local prev_follow
    if not asFloat then
        -- Evita que el foco/splits sigan el mouse mientras spawneamos.
        prev_follow = hl.get_config("input.follow_mouse")
        hl.config({ input = { follow_mouse = 0 } })
    end

    local function finish()
        spawning = false
        if prev_follow ~= nil then
            hl.config({ input = { follow_mouse = prev_follow } })
        end
    end

    local function spawn_next()
        if not spawning then
            if prev_follow ~= nil then
                hl.config({ input = { follow_mouse = prev_follow } })
            end
            return
        end

        i = i + 1
        if i > count then
            finish()
            return
        end

        local toy = juguetes[i]
        local line = kitty_line(toy)

        if asFloat then
            local size, move = resolve_float_geometry(toy, slots[i])
            hl.exec_cmd(line, {
                float = true,
                tag = "+autoplace",
                size = size,
                move = move,
            })
        else
            -- Tiled: parte la juguete más grande (no donde esté el mouse).
            -- `size` no aplica aquí (lo decide dwindle).
            if i > 1 then
                focus_largest_juguete()
            end
            hl.exec_cmd(line, { tag = "+autoplace" })
        end

        if i < count then
            hl.timer(spawn_next, { timeout = spawnGapMs, type = "oneshot" })
        else
            finish()
        end
    end

    spawn_next()
end

local function toggle_juguetes(asFloat)
    if spawning or #list_juguete_windows() > 0 then
        close_juguetes()
        return
    end

    cleanup_orphan_toys()
    hl.timer(function()
        spawn_juguetes(asFloat)
    end, { timeout = 80, type = "oneshot" })
end

hl.bind(mainMod .. " + Home", function()
    toggle_juguetes(false) -- tiled
end)

hl.bind(mainMod .. " + SHIFT + Home", function()
    toggle_juguetes(true) -- floating grid
end)
