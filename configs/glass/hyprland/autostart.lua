---@module 'hl'
local apps     = require("apps")
local monitors = require("monitors")

hl.on("hyprland.start", function()
  hl.exec_cmd(apps.statusBar)
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("systemctl --user start dotfiles-backup.timer")
  hl.exec_cmd("sleep 2; " .. apps.scripts .. "wallpaper restore")
  if monitors.primary then
    hl.exec_cmd("xrandr --output " .. monitors.primary .. " --primary")
  end
end)
