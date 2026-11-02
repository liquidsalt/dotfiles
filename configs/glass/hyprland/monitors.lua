-- monitor-conf.json says which screens exist and their limits, monitors.json remembers what was changed

local json = require("json")

local M = {}

local home = os.getenv("HOME")

M.confPath  = (os.getenv("XDG_CONFIG_HOME") or home .. "/.config") .. "/dotfiles/monitor-conf.json"
M.statePath = (os.getenv("XDG_STATE_HOME") or home .. "/.local/state") .. "/dotfiles/monitors.json"
M.primary   = nil

local function readJson(path)
  local f = io.open(path, "r"); if not f then return nil end
  local text = f:read("a"); f:close()
  return json.decode(text)
end

local function connected(port)
  for n = 0, 7 do
    local f = io.open("/sys/class/drm/card" .. n .. "-" .. port .. "/status", "r")
    if f then
      local status = f:read("l"); f:close()
      if status == "connected" then return true end
    end
  end
  return false
end

local function readState()
  return readJson(M.statePath) or {}
end

local function writeState(state)
  os.execute("mkdir -p '" .. M.statePath:match("(.*)/") .. "'")
  local tmp = M.statePath .. ".tmp"
  local f = io.open(tmp, "w"); if not f then return end
  f:write(json.encode(state), "\n"); f:close()
  os.rename(tmp, M.statePath)
end

-- Docked once any screen the docked profile names, other than the built-in one, is plugged in
function M.layout()
  local conf = readJson(M.confPath)
  if not conf then return {} end

  local builtIn
  for _, m in pairs(conf.undocked or {}) do builtIn = m.port end

  local profile = conf.undocked or {}
  for _, m in pairs(conf.docked or {}) do
    if m.port ~= builtIn and connected(m.port) then profile = conf.docked; break end
  end

  local out = {}
  for _, m in pairs(profile) do out[#out + 1] = m end
  table.sort(out, function(a, b) return a.index < b.index end)
  return out
end

-- Left to right by index. Saved changes first, then the preferred values, then the limits
function M.apply()
  local saved = readState()
  local x = 0
  for _, m in ipairs(M.layout()) do
    local s = saved[m.port] or {}
    local res      = s.resolution or m["preferred-resolution"] or m["max-resolution"]
    local rate     = s.refresh or m["preferred-refresh-rate"] or m["max-refresh-rate"]
    local rotation = s.rotation or m["preferred-rotation"] or 0
    local w, h = res:match("^(%d+)x(%d+)$")

    hl.monitor({
      output    = m.port,
      mode      = res .. "@" .. rate,
      position  = x .. "x0",
      scale     = 1,
      transform = rotation,
    })

    x = x + tonumber(rotation % 2 == 1 and h or w)  -- a sideways screen is as wide as it is tall
    if m.primary then M.primary = m.port end
  end
end

-- Five per output by index, 0 gets 1-5, 1 gets 6-10
function M.workspaces()
  for _, m in ipairs(M.layout()) do
    for n = 1, 5 do
      hl.workspace_rule({ workspace = m.index * 5 + n, monitor = m.port })
    end
  end
end

local function save(port, change)
  local state = readState()
  state[port] = state[port] or {}
  for k, v in pairs(change) do state[port][k] = v end
  writeState(state)
  M.apply()
end

function M.flip(port)
  port = port or hl.get_active_monitor().name
  local current = (readState()[port] or {}).rotation
  for _, m in ipairs(M.layout()) do
    if current == nil and m.port == port then current = m["preferred-rotation"] end
  end
  current = current or 0
  save(port, { rotation = current == 0 and 3 or 0 })
end

return M
