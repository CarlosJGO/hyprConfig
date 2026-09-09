-- Colocación inteligente de flotantes al abrir.
-- Hyprland no tiene windowrule nativa para "evitar solape";
-- usamos window.open y windowsMove (animado) para deslizar a un hueco.

local MARGIN = 16
local GAP = 10
local GRID_STEP = 48
local PLACE_DELAY_MS = 90

-- Popups del shell / cosas que ya posiciona otra app.
local function should_skip(window)
    if not window or not window.floating or not window.mapped then
        return true
    end
    if window.pinned or window.fullscreen ~= 0 then
        return true
    end

    local title = window.title or ""
    local class = window.class or ""
    if title:match("^Jugoo ") or class:match("jugoo") or class:match("Jugoo") then
        return true
    end

    return false
end

local function vec2(v, a, b)
    if type(v) ~= "table" then
        return 0, 0
    end
    return tonumber(v[a] or v[b] or v.x or v[1]) or 0, tonumber(v[b] or v[a] or v.y or v[2]) or 0
end

local function window_box(window)
    local x, y = vec2(window.at, 1, 2)
    local w, h = vec2(window.size, 1, 2)
    return x, y, w, h
end

local function overlap_area(ax, ay, aw, ah, bx, by, bw, bh)
    local x1 = math.max(ax, bx)
    local y1 = math.max(ay, by)
    local x2 = math.min(ax + aw, bx + bw)
    local y2 = math.min(ay + ah, by + bh)
    local w = x2 - x1
    local h = y2 - y1
    if w <= 0 or h <= 0 then
        return 0
    end
    return w * h
end

local function workarea(monitor)
    local mx = monitor.x or 0
    local my = monitor.y or 0
    local mw = monitor.width or 0
    local mh = monitor.height or 0
    local left, top, right, bottom = 0, 0, 0, 0
    local r = monitor.reserved

    if type(r) == "table" then
        if r.top ~= nil or r.left ~= nil then
            top = tonumber(r.top) or 0
            bottom = tonumber(r.bottom) or 0
            left = tonumber(r.left) or 0
            right = tonumber(r.right) or 0
        else
            -- hyprctl: [left, top, right, bottom]
            left = tonumber(r[1]) or 0
            top = tonumber(r[2]) or 0
            right = tonumber(r[3]) or 0
            bottom = tonumber(r[4]) or 0
        end
    end

    local x = mx + left + MARGIN
    local y = my + top + MARGIN
    local w = mw - left - right - (MARGIN * 2)
    local h = mh - top - bottom - (MARGIN * 2)
    return x, y, math.max(w, 1), math.max(h, 1)
end

local function others_on_workspace(window)
    local out = {}
    local ws = window.workspace
    if not ws then
        return out
    end

    for _, other in ipairs(hl.get_windows() or {}) do
        if other.address ~= window.address
            and other.mapped
            and not other.hidden
            and other.workspace
            and other.workspace.id == ws.id
        then
            local title = other.title or ""
            if not title:match("^Jugoo ") then
                out[#out + 1] = other
            end
        end
    end
    return out
end

local function total_overlap(x, y, w, h, others)
    local total = 0
    for _, other in ipairs(others) do
        local ox, oy, ow, oh = window_box(other)
        total = total + overlap_area(
            x - GAP, y - GAP, w + GAP * 2, h + GAP * 2,
            ox, oy, ow, oh
        )
    end
    return total
end

local function find_free_spot(window, others)
    local monitor = window.monitor
    if not monitor then
        return nil
    end

    local x0, y0, ww, hh = window_box(window)
    if ww <= 1 or hh <= 1 then
        return nil
    end

    local ax, ay, aw, ah = workarea(monitor)
    local max_x = ax + math.max(aw - ww, 0)
    local max_y = ay + math.max(ah - hh, 0)

    local current = total_overlap(x0, y0, ww, hh, others)
    if current <= 0 then
        return nil
    end

    local best_x, best_y = x0, y0
    local best_ov = current
    local best_dist = math.huge

    for y = ay, max_y, GRID_STEP do
        for x = ax, max_x, GRID_STEP do
            local ov = total_overlap(x, y, ww, hh, others)
            local dx = x - x0
            local dy = y - y0
            local dist = dx * dx + dy * dy

            if ov < best_ov or (ov == best_ov and dist < best_dist) then
                best_ov = ov
                best_dist = dist
                best_x, best_y = x, y
                if best_ov == 0 and dist <= (GRID_STEP * GRID_STEP * 8) then
                    return best_x, best_y
                end
            end
        end
    end

    if best_x == x0 and best_y == y0 then
        return nil
    end

    return best_x, best_y
end

local function place_floating(window)
    if should_skip(window) then
        return
    end

    local addr = window.address
    local sel = "address:" .. addr

    hl.timer(function()
        local live = hl.get_window(sel)
        if should_skip(live) then
            return
        end

        local others = others_on_workspace(live)
        if #others == 0 then
            return
        end

        local nx, ny = find_free_spot(live, others)
        if not nx then
            return
        end

        -- windowsMove anima el desplazamiento de forma smooth.
        hl.dispatch(hl.dsp.window.move({
            x = nx,
            y = ny,
            relative = false,
            window = sel,
        }))
    end, { timeout = PLACE_DELAY_MS, type = "oneshot" })
end

hl.on("window.open", place_floating)
