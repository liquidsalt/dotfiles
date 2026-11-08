local scripts = os.getenv("HOME") .. "/.local/share/dotfiles/scripts/"

return {
  mod     = "SUPER",
  scripts = scripts,

  terminal      = "kitty",
  webBrowser    = "helium",
  fileManager   = "nautilus",
  notesApp      = "obsidian",
  discord       = "vesktop",
  musicPlayer   = "spotify",
  gameLauncher  = "play heroic",
  steamLauncher = "play steam -gamepadui",

  appLauncher      = "qs ipc call launcher toggle",
  powerMenu        = "qs ipc call powerMenu toggle",
  wallpaperManager = "qs ipc call wallpaperPicker toggle",
  statusBar        = "systemctl --user restart quickshell.service",

  cursorTheme = "Adwaita",
  cursorSize  = 24,
}
