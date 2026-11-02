---@module 'hl'
local apps     = require("apps")
local monitors = require("monitors")

hl.bind(apps.mod .. " + Return",         hl.dsp.exec_cmd(apps.terminal))
hl.bind(apps.mod .. " + Space",          hl.dsp.exec_cmd(apps.appLauncher))
hl.bind(apps.mod .. " + Escape",         hl.dsp.exec_cmd(apps.powerMenu))
hl.bind(apps.mod .. " + F",              hl.dsp.exec_cmd(apps.fileManager))
hl.bind(apps.mod .. " + B",              hl.dsp.exec_cmd(apps.webBrowser))
hl.bind(apps.mod .. " + N",              hl.dsp.exec_cmd(apps.notesApp))
hl.bind(apps.mod .. " + D",              hl.dsp.exec_cmd(apps.discord))
hl.bind(apps.mod .. " + M",              hl.dsp.exec_cmd(apps.musicPlayer))
hl.bind(apps.mod .. " + G",              hl.dsp.exec_cmd(apps.gameLauncher))
hl.bind(apps.mod .. " + SHIFT + G",      hl.dsp.exec_cmd(apps.steamLauncher))
hl.bind(apps.mod .. " + W",              hl.dsp.exec_cmd(apps.wallpaperManager))

for key, dir in pairs({ H = "l", L = "r", K = "u", J = "d" }) do
  hl.bind(apps.mod .. " + " .. key,           hl.dsp.focus({ direction = dir }))
  hl.bind(apps.mod .. " + SHIFT + " .. key,   hl.dsp.window.move({ direction = dir }))
end

hl.bind(apps.mod .. " + CTRL + H", hl.dsp.window.resize({ x = -40, y =   0, relative = true }), { repeating = true })
hl.bind(apps.mod .. " + CTRL + L", hl.dsp.window.resize({ x =  40, y =   0, relative = true }), { repeating = true })
hl.bind(apps.mod .. " + CTRL + K", hl.dsp.window.resize({ x =   0, y = -40, relative = true }), { repeating = true })
hl.bind(apps.mod .. " + CTRL + J", hl.dsp.window.resize({ x =   0, y =  40, relative = true }), { repeating = true })

hl.bind(apps.mod .. " + Backspace", hl.dsp.window.close())
hl.bind(apps.mod .. " + T",         hl.dsp.window.float({ action = "toggle" }))

hl.bind(apps.mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(apps.mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

for ws = 1, 10 do
  local key = tostring(ws % 10)   -- workspace 10 is on the 0 key
  hl.bind(apps.mod .. " + " .. key,         hl.dsp.focus({ workspace = ws }))
  hl.bind(apps.mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = ws }))
end

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true, locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume      @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true, locked = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { repeating = true, locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { repeating = true, locked = true })

hl.bind(apps.mod .. " + equal", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"))
hl.bind(apps.mod .. " + minus", hl.dsp.exec_cmd("wpctl set-volume      @DEFAULT_AUDIO_SINK@ 5%-"))

hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -q s 10%+"), { repeating = true, locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -q s 10%-"), { repeating = true, locked = true })

hl.bind(apps.mod .. " + S",         hl.dsp.exec_cmd(apps.scripts .. "screenshot select"))
hl.bind(apps.mod .. " + SHIFT + S", hl.dsp.exec_cmd(apps.scripts .. "screenshot screen"))
hl.bind(apps.mod .. " + CTRL + S",  hl.dsp.exec_cmd(apps.scripts .. "screenshot all"))

hl.bind(apps.mod .. " + backslash", function() monitors.flip() end)
