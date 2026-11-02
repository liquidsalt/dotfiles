---@module 'hl'

local monitors = require("monitors")
monitors.apply()
monitors.workspaces()

require("settings")
require("animations")
require("env")
require("binds")
require("rules")
require("autostart")
