-- Maximize / fullscreen sin esconder hermanas de golpe.
-- layout_aware=false: la ventana crece encima; las demás siguen en el layout
-- y al salir vuelven a su sitio (sin tocar geometrías a mano).

function toggle_maximize_consume()
    hl.dispatch(hl.dsp.window.fullscreen({
        mode = 1,
        layout_aware = false,
    }))
end

function toggle_fullscreen_consume()
    hl.dispatch(hl.dsp.window.fullscreen({
        layout_aware = false,
    }))
end
