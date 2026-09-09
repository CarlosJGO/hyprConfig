-- Juguetes de terminal (toggle).
-- SUPER + Home         → tiled
-- SUPER + SHIFT + Home → floating (tamaño según cantidad)
-- Toggle: si ya hay juguetes → cierra + limpia huérfanos; si no → abre.

local mainMod = "SUPER"
local spawnGapMs = 280
local titlePrefix = "juguete:"

-- Edita esta lista para agregar/quitar. `run` es lo que recibe kitty -e.
local juguetes = {
    { name = "cmatrix",      run = "cmatrix" },
    { name = "lavat",        run = "lavat" },
    { name = "pipes.sh",     run = "pipes.sh" },
    { name = "cava",         run = "cava" },
    { name = "cbonsai",      run = "cbonsai -l" },
    { name = "genact",       run = "genact" },
    { name = "asciiquarium", run = "asciiquarium" },
}

local spawning = false

-- Más juguetes → ventanas más chicas (solo modo floating).
local function float_size_for_count(n)
    n = math.max(n, 1)
    local side = math.max(0.22, math.min(0.56, 0.92 / math.sqrt(n)))
    local w = string.format("monitor_w * %.3f", side)
    local h = string.format("monitor_h * %.3f", math.min(0.62, side * 1.08))
    return { w, h }
end

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
            .. "pkill -f asciiquarium >/dev/null 2>&1 || true"
    )
end

local function close_juguetes()
    spawning = false
    for _, window in ipairs(list_juguete_windows()) do
        hl.dispatch(hl.dsp.window.kill({ window = "address:" .. window.address }))
    end
    cleanup_orphan_toys()
end

local function spawn_juguetes(asFloat)
    if spawning then
        return
    end
    spawning = true

    local count = #juguetes
    local floatRules = {
        float = true,
        center = true,
        size = float_size_for_count(count),
    }

    local i = 0

    local function spawn_next()
        if not spawning then
            return
        end

        i = i + 1
        if i > count then
            spawning = false
            return
        end

        local toy = juguetes[i]
        local title = titlePrefix .. toy.name
        local line = string.format("%s --title %q -e %s", TERMINAL, title, toy.run)

        if asFloat then
            hl.exec_cmd(line, floatRules)
        else
            hl.exec_cmd(line)
        end

        if i < count then
            hl.timer(spawn_next, { timeout = spawnGapMs, type = "oneshot" })
        else
            spawning = false
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
    toggle_juguetes(false)
end)

hl.bind(mainMod .. " + SHIFT + Home", function()
    toggle_juguetes(true)
end)
