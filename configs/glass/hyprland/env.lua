---@module 'hl'
local apps = require("apps")

hl.env("XCURSOR_THEME",    apps.cursorTheme)
hl.env("XCURSOR_SIZE",     apps.cursorSize)
hl.env("HYPRCURSOR_THEME", apps.cursorTheme)
hl.env("HYPRCURSOR_SIZE",  apps.cursorSize)

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE",    "wayland")

hl.env("GDK_SCALE",              1)
hl.env("GDK_BACKEND",            "wayland,x11,*")
hl.env("QT_QPA_PLATFORM",        "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME",   "gtk3")  -- Qt takes its theme from the GTK settings
hl.env("QT_STYLE_OVERRIDE",      "Fusion")
hl.env("SDL_VIDEODRIVER",        "wayland")
