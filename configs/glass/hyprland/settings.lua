---@module 'hl'

hl.config({
  general = {
    layout           = "dwindle",
    border_size      = 0,
    gaps_in          = 6,
    gaps_out         = 12,
    resize_on_border = true,
    allow_tearing    = false,
  },

  decoration = {
    rounding         = 10,
    rounding_power   = 2.0,
    active_opacity   = 1.0,
    inactive_opacity = 1.0,

    blur = {
      enabled        = true,
      size           = 6,
      passes         = 2,
      noise          = 0.008,
      contrast       = 1.0,
      brightness     = 1.0,
      vibrancy       = 0.2,
      ignore_opacity = true,
    },

    shadow = { enabled = false },
  },

  dwindle = { preserve_split = true },
  master  = { new_status = "master" },

  cursor = {
    inactive_timeout    = 2,  -- seconds
    no_hardware_cursors = true,
  },

  input = {
    accel_profile = "flat",
    sensitivity   = -0.3,
  },

  misc     = { disable_hyprland_logo = true },
  xwayland = { force_zero_scaling = true },

  animations = { enabled = true },
})
