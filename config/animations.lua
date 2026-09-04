-- Animations
-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/

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

hl.curve("smooth", {
    type = "bezier",
    points = {
        {0.25, 0.1},
        {0.25, 1},
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

hl.curve("snappy", {
    type = "bezier",
    points = {
        {0.2, 0.8},
        {0.2, 1},
    }
})

-- Curva de aceleración tipo gravedad
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

hl.curve("soft", {
    type = "spring",
    mass = 1,
    stiffness = 300,
    dampening = 30,
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
    speed = 3,
    bezier = "quick",
})


-- ============================================================
-- WINDOWS
-- ============================================================

-- Apertura / cierre de ventanas
hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 3,
    spring = "easy",
    style = "slide",
})

-- Movimiento físico de ventanas.
-- IMPORTANTE:
-- Nuestro move_workspace_contents.py utiliza:
--
-- hl.dsp.window.move(...)
--
-- por lo que estos movimientos pasan por windowsMove.
hl.animation({
    leaf = "windowsMove",
    enabled = true,
    speed = 4,
    bezier = "easeOutQuint",
    style = "slide",
})


-- ============================================================
-- WORKSPACES
-- ============================================================

-- Cambio normal de workspace
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 5,
    bezier = "quick",
    style = "slide",
})


-- ============================================================
-- SPECIAL WORKSPACES
-- ============================================================

hl.animation({
    leaf = "specialWorkspaceIn",
    enabled = true,
    speed = 3,
    bezier = "easeOutQuint",
    style = "slide top",
})

hl.animation({
    leaf = "specialWorkspaceOut",
    enabled = true,
    speed = 3,
    bezier = "easeOutQuint",
    style = "slide bottom",
})


-- ============================================================
-- LAYERS
-- ============================================================

hl.animation({
    leaf = "layers",
    enabled = true,
    speed = 4,
    bezier = "quick",
    style = "slide",
})


-- ============================================================
-- FADE
-- ============================================================

hl.animation({
    leaf = "fadeIn",
    enabled = true,
    speed = 3,
    bezier = "easeOutQuint",
})

hl.animation({
    leaf = "fadeOut",
    enabled = true,
    speed = 3,
    bezier = "easeOutQuint",
})

hl.animation({
    leaf = "fadeSwitch",
    enabled = true,
    speed = 4,
    bezier = "quick",
})

hl.animation({
    leaf = "fadeShadow",
    enabled = true,
    speed = 3,
    bezier = "easeOutQuint",
})


-- ============================================================
-- BORDERS
-- ============================================================

hl.animation({
    leaf = "border",
    enabled = true,
    speed = 3,
    bezier = "quick",
})

hl.animation({
    leaf = "borderangle",
    enabled = true,
    speed = 30,
    bezier = "linear",
})


-- ============================================================
-- DIM
-- ============================================================

hl.animation({
    leaf = "fadeDim",
    enabled = true,
    speed = 3,
    bezier = "easeOutQuint",
})


-- ============================================================
-- WINDOW CLOSE / OPEN
-- ============================================================

-- Entrada
hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 3,
    bezier = "easeOutQuint",
    style = "popin 70%",
})

-- Salida: caída hacia abajo
hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 5,
    bezier = "gravity",
    style = "slide bottom",
})

-- Opacidad de entrada
hl.animation({
    leaf = "fadeIn",
    enabled = true,
    speed = 3,
    bezier = "easeOutQuint",
})

-- Opacidad de salida
hl.animation({
    leaf = "fadeOut",
    enabled = true,
    speed = 5,
    bezier = "gravity",
})

