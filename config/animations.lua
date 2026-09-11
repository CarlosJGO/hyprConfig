-- Animations
-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
-- Transiciones suaves y responsivas (~300–400 ms)

-- ============================================================
-- BEZIER CURVES
-- ============================================================

hl.curve("easeOutQuint", {
    type = "bezier",
    points = {
        {0.23, 1},
        {0.32, 1},
    }
})

hl.curve("easeInOutCubic", {
    type = "bezier",
    points = {
        {0.65, 0.05},
        {0.36, 1},
    }
})

hl.curve("easeInOutQuart", {
    type = "bezier",
    points = {
        {0.76, 0},
        {0.24, 1},
    }
})

hl.curve("easeOutCubic", {
    type = "bezier",
    points = {
        {0.33, 1},
        {0.68, 1},
    }
})

hl.curve("easeOutExpo", {
    type = "bezier",
    points = {
        {0.16, 1},
        {0.3, 1},
    }
})

hl.curve("easeInOutExpo", {
    type = "bezier",
    points = {
        {0.87, 0},
        {0.13, 1},
    }
})

hl.curve("linear", {
    type = "bezier",
    points = {
        {0, 0},
        {1, 1},
    }
})

hl.curve("almostLinear", {
    type = "bezier",
    points = {
        {0.5, 0.5},
        {0.75, 1},
    }
})

hl.curve("quick", {
    type = "bezier",
    points = {
        {0.15, 0},
        {0.1, 1},
    }
})

-- Entrada/salida suave sin freno brusco
hl.curve("smooth", {
    type = "bezier",
    points = {
        {0.22, 0.61},
        {0.36, 1},
    }
})

-- Desaceleración elegante (ventanas / fade)
hl.curve("smoothOut", {
    type = "bezier",
    points = {
        {0.16, 1},
        {0.3, 1},
    }
})

-- Transiciones bidireccionales (workspaces, move)
hl.curve("smoothIO", {
    type = "bezier",
    points = {
        {0.45, 0.05},
        {0.55, 0.95},
    }
})

hl.curve("overshoot", {
    type = "bezier",
    points = {
        {0.5, 0.9},
        {0.1, 1.1},
    }
})

hl.curve("smoothOvershoot", {
    type = "bezier",
    points = {
        {0.34, 1.56},
        {0.64, 1},
    }
})

-- Gelatina vía spring: el overshoot anima realSize (contenido + marco juntos).
-- No usar bezier con Y>1 en popin: Hyprland estira solo bordes (#8058).
hl.curve("jelly", {
    type = "spring",
    mass = 1,
    stiffness = 400,
    dampening = 16,
})

hl.curve("snappy", {
    type = "bezier",
    points = {
        {0.2, 0.8},
        {0.2, 1},
    }
})

hl.curve("gravity", {
    type = "bezier",
    points = {
        {0.55, 0},
        {1, 1},
    },
})

-- ============================================================
-- SPRINGS
-- ============================================================

hl.curve("easy", {
    type = "spring",
    mass = 1,
    stiffness = 500,
    dampening = 35,
})

-- Suave y bien amortiguado (sin rebote perceptible)
hl.curve("soft", {
    type = "spring",
    mass = 1,
    stiffness = 280,
    dampening = 32,
})

hl.curve("bouncy", {
    type = "spring",
    mass = 1,
    stiffness = 400,
    dampening = 20,
})

hl.curve("rubber", {
    type = "spring",
    mass = 1,
    stiffness = 200,
    dampening = 15,
})


-- ============================================================
-- GLOBAL
-- ============================================================

hl.animation({
    leaf = "global",
    enabled = true,
    speed = 4,
    bezier = "smoothOut",
})


-- ============================================================
-- WINDOWS
-- ============================================================

hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 4,
    spring = "soft",
    style = "slide",
})

-- Movimiento / resize (maximize, fullscreen, drag, float_place…)
-- Un poco más lento para que al maximizar se vea cómo “consume” a las de debajo.
hl.animation({
    leaf = "windowsMove",
    enabled = true,
    speed = 5,
    bezier = "smoothOut",
    style = "slide",
})

hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 5,
    spring = "jelly",
    style = "popin 55%",
})

-- Salida: caída hacia abajo
hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 5,
    bezier = "gravity",
    style = "slide bottom",
})


-- ============================================================
-- WORKSPACES
-- ============================================================

hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 4,
    bezier = "smoothIO",
    style = "slide",
})


-- ============================================================
-- SPECIAL WORKSPACES
-- ============================================================

hl.animation({
    leaf = "specialWorkspaceIn",
    enabled = true,
    speed = 4,
    bezier = "smoothOut",
    style = "slide top",
})

hl.animation({
    leaf = "specialWorkspaceOut",
    enabled = true,
    speed = 3,
    bezier = "smooth",
    style = "slide bottom",
})


-- ============================================================
-- LAYERS
-- ============================================================

hl.animation({
    leaf = "layers",
    enabled = true,
    speed = 3,
    bezier = "smoothOut",
    style = "slide",
})


-- ============================================================
-- FADE
-- ============================================================

hl.animation({
    leaf = "fadeIn",
    enabled = true,
    speed = 3,
    bezier = "smoothOut",
})

hl.animation({
    leaf = "fadeOut",
    enabled = true,
    speed = 5,
    bezier = "gravity",
})

hl.animation({
    leaf = "fadeSwitch",
    enabled = true,
    speed = 3,
    bezier = "smoothIO",
})

hl.animation({
    leaf = "fadeShadow",
    enabled = true,
    speed = 3,
    bezier = "smoothOut",
})

hl.animation({
    leaf = "fadeDim",
    enabled = true,
    speed = 3,
    bezier = "smoothOut",
})


-- ============================================================
-- BORDERS
-- ============================================================

hl.animation({
    leaf = "border",
    enabled = true,
    speed = 3,
    bezier = "smoothOut",
})

hl.animation({
    leaf = "borderangle",
    enabled = true,
    speed = 30,
    bezier = "linear",
})
