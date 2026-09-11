-- Colocación inteligente de flotantes (OPT-IN al abrir) + despeje al abrir tiled.
--
-- 1) Flotante con tag "autoplace" / título "juguete:*":
--    si solapa otra flotante libre, busca hueco (las tiled no empujan).
-- 2) Tiled (anclada) nueva:
--    si flotantes la tapan, las mueve (animación windowsMove) hasta dejarla visible.
--    Prefiere no solapar otras flotantes; puede quedar parcialmente fuera de pantalla.
--
-- Opt-in spawn:
--   hl.exec_cmd("kitty", { float = true, tag = "+autoplace", ... })

local AUTOPLACE_TAG = "autoplace"
local JUGUETE_PREFIX = "juguete:"

local MARGIN = 16
local GAP = 10
local GRID_STEP = 48
local PLACE_DELAY_MS = 90
local EVICT_DELAY_MS = 140
-- Cuánto de la ventana debe seguir en el monitor para poder agarrarla.
local GRAB_SLACK = 72

local function has_autoplace_tag(window)
    local tags = window.tags
    if type(tags) == "string" then
        return tags:find(AUTOPLACE_TAG, 1, true) ~= nil
    end
    if type(tags) == "table" then
        for _, tag in pairs(tags) do
            if tostring(tag):find(AUTOPLACE_TAG, 1, true) then
                return true
            end
        end
    end
    return false
end

local function is_opted_in(window)
    if has_autoplace_tag(window) then
        return true
    end
    local title = window.title or ""
    return title:sub(1, #JUGUETE_PREFIX) == JUGUETE_PREFIX
end

local function is_jugoo_title(window)
    local title = window.title or ""
    return title:match("^Jugoo ") ~= nil
end

local function should_skip_float_place(window)
    if not window or not window.floating or not window.mapped then
        return true
    end
    if window.pinned or window.fullscreen ~= 0 then
        return true
    end
    if not is_opted_in(window) then
        return true
    end
    return false
end

local function is_tiled_newcomer(window)
    if not window or not window.mapped or window.hidden then
        return false
    end
    if window.floating then
        return false
    end
    if window.fullscreen ~= 0 then
        return false
    end
    if is_jugoo_title(window) then
        return false
    end
    return true
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

local function monitor_rect(monitor)
    return monitor.x or 0, monitor.y or 0, monitor.width or 0, monitor.height or 0
end

local function others_floats(window)
    -- Solo otras flotantes “libres”: las tiled/ancladas no cuentan como obstáculo.
    local out = {}
    local ws = window.workspace
    if not ws then
        return out
    end

    for _, other in ipairs(hl.get_windows() or {}) do
        if other.address ~= window.address
            and other.mapped
            and not other.hidden
            and other.floating
            and not other.pinned
            and other.workspace
            and other.workspace.id == ws.id
            and not is_jugoo_title(other)
        then
            out[#out + 1] = other
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

local function boxes_overlap(x, y, w, h, boxes)
    local total = 0
    for _, b in ipairs(boxes) do
        total = total + overlap_area(
            x - GAP, y - GAP, w + GAP * 2, h + GAP * 2,
            b.x, b.y, b.w, b.h
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

-- Sitio que no tape la tiled; prefiere no solapar otras flotantes.
-- Puede colgarse del borde (sigue siendo agarrable por GRAB_SLACK).
local function find_evict_spot(fx, fy, fw, fh, tiled, soft_boxes, monitor)
    local mx, my, mw, mh = monitor_rect(monitor)
    if mw <= 0 or mh <= 0 or fw <= 1 or fh <= 1 then
        return nil
    end

    local tx, ty, tw, th = tiled.x, tiled.y, tiled.w, tiled.h
    local min_x = mx + GRAB_SLACK - fw
    local max_x = mx + mw - GRAB_SLACK
    local min_y = my + GRAB_SLACK - fh
    local max_y = my + mh - GRAB_SLACK
    if min_x > max_x then
        min_x, max_x = mx - fw + GRAB_SLACK, mx + mw - GRAB_SLACK
    end
    if min_y > max_y then
        min_y, max_y = my - fh + GRAB_SLACK, my + mh - GRAB_SLACK
    end

    local best_x, best_y = nil, nil
    local best_soft = math.huge
    local best_dist = math.huge

    local function consider(x, y)
        if x < min_x or x > max_x or y < min_y or y > max_y then
            return
        end
        if overlap_area(x, y, fw, fh, tx, ty, tw, th) > 0 then
            return
        end
        local soft = boxes_overlap(x, y, fw, fh, soft_boxes)
        local dx = x - fx
        local dy = y - fy
        local dist = dx * dx + dy * dy
        if soft < best_soft or (soft == best_soft and dist < best_dist) then
            best_soft = soft
            best_dist = dist
            best_x, best_y = x, y
        end
    end

    for y = min_y, max_y, GRID_STEP do
        for x = min_x, max_x, GRID_STEP do
            consider(x, y)
            if best_soft == 0 and best_dist <= (GRID_STEP * GRID_STEP * 16) then
                return best_x, best_y
            end
        end
    end

    -- Fallback: esquinas / bordes (parcialmente fuera).
    local fallbacks = {
        { min_x, min_y },
        { max_x, min_y },
        { min_x, max_y },
        { max_x, max_y },
        { min_x, fy },
        { max_x, fy },
        { fx, min_y },
        { fx, max_y },
    }
    for _, p in ipairs(fallbacks) do
        consider(p[1], p[2])
    end

    return best_x, best_y
end

local function move_window(sel, x, y)
    hl.dispatch(hl.dsp.window.move({
        x = x,
        y = y,
        relative = false,
        window = sel,
    }))
end

local function place_floating(window)
    if should_skip_float_place(window) then
        return
    end

    local addr = window.address
    local sel = "address:" .. addr

    hl.timer(function()
        local live = hl.get_window(sel)
        if should_skip_float_place(live) then
            return
        end

        local others = others_floats(live)
        if #others == 0 then
            return
        end

        local nx, ny = find_free_spot(live, others)
        if not nx then
            return
        end

        move_window(sel, nx, ny)
    end, { timeout = PLACE_DELAY_MS, type = "oneshot" })
end

local function covering_floats(tiled)
    local tx, ty, tw, th = window_box(tiled)
    if tw <= 1 or th <= 1 then
        return {}
    end

    local ws = tiled.workspace
    if not ws then
        return {}
    end

    local list = {}
    for _, other in ipairs(hl.get_windows() or {}) do
        if other.address ~= tiled.address
            and other.mapped
            and not other.hidden
            and other.floating
            and not other.pinned
            and other.workspace
            and other.workspace.id == ws.id
            and not is_jugoo_title(other)
        then
            local ox, oy, ow, oh = window_box(other)
            local ov = overlap_area(tx, ty, tw, th, ox, oy, ow, oh)
            if ov > 0 then
                list[#list + 1] = {
                    window = other,
                    overlap = ov,
                    x = ox,
                    y = oy,
                    w = ow,
                    h = oh,
                }
            end
        end
    end

    table.sort(list, function(a, b)
        return a.overlap > b.overlap
    end)
    return list
end

local function evict_floats_over_tiled(window)
    if not is_tiled_newcomer(window) then
        return
    end

    local addr = window.address
    local sel = "address:" .. addr

    hl.timer(function()
        local tiled = hl.get_window(sel)
        if not is_tiled_newcomer(tiled) then
            return
        end

        local monitor = tiled.monitor
        if not monitor then
            return
        end

        local tx, ty, tw, th = window_box(tiled)
        local tiled_box = { x = tx, y = ty, w = tw, h = th }
        local blockers = covering_floats(tiled)
        if #blockers == 0 then
            return
        end

        -- Cajas ya “comprometidas”: resto de flotantes que no vamos a mover aún,
        -- más las que ya reubicamos en esta pasada.
        local staying = {}
        local moving_addrs = {}
        for _, b in ipairs(blockers) do
            moving_addrs[b.window.address] = true
        end
        for _, other in ipairs(others_floats(tiled)) do
            if not moving_addrs[other.address] then
                local ox, oy, ow, oh = window_box(other)
                staying[#staying + 1] = { x = ox, y = oy, w = ow, h = oh }
            end
        end

        local placed = {}
        for i, b in ipairs(staying) do
            placed[i] = b
        end

        for _, b in ipairs(blockers) do
            local soft = {}
            for _, p in ipairs(placed) do
                soft[#soft + 1] = p
            end

            local nx, ny = find_evict_spot(b.x, b.y, b.w, b.h, tiled_box, soft, monitor)
            if nx then
                move_window("address:" .. b.window.address, nx, ny)
                placed[#placed + 1] = { x = nx, y = ny, w = b.w, h = b.h }
            end
        end
    end, { timeout = EVICT_DELAY_MS, type = "oneshot" })
end

local function on_window_open(window)
    place_floating(window)
    evict_floats_over_tiled(window)
end

hl.on("window.open", on_window_open)
