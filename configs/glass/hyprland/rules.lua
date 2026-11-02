---@module 'hl'

hl.window_rule({
  name  = "pip",
  match = { title = "^(Picture-in-Picture)$" },
  float = true,
  pin   = true,
  move  = { "73%", "72%" },
  size  = { 426, 240 },
})

-- LibreOffice asks for fullscreen through xdg-activation
hl.window_rule({
  name           = "libreoffice-suppress-fs",
  match          = { class = "^(libreoffice-.*)$" },
  suppress_event = "fullscreen maximize",
})

-- ignore_alpha blurs only the painted part, not the whole full-width surface
hl.layer_rule({
  match        = { namespace = "^quickshell:(bar|popup|launcher|notifications|osd)$" },
  blur         = true,
  ignore_alpha = 0.08,
  xray         = 0,
})

hl.layer_rule({
  match = { namespace = "^quickshell:wallpaper$" },
  blur  = false,
})
