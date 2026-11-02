-- Just enough JSON for the monitor files: objects, arrays, strings, numbers, booleans

local json = {}

local escapes = { ['"'] = '\\"', ["\\"] = "\\\\", ["\n"] = "\\n", ["\r"] = "\\r", ["\t"] = "\\t" }

local function encode(v, indent)
  local t = type(v)
  if t == "string" then
    return '"' .. (v:gsub('[%c"\\]', function(c) return escapes[c] or string.format("\\u%04x", c:byte()) end)) .. '"'
  elseif t == "number" then
    return v % 1 == 0 and string.format("%d", v) or tostring(v)
  elseif t == "boolean" then
    return tostring(v)
  elseif t ~= "table" then
    return "null"
  end

  local inner = indent .. "  "
  if #v > 0 then
    local out = {}
    for i = 1, #v do out[i] = encode(v[i], inner) end
    return "[" .. table.concat(out, ", ") .. "]"
  end

  local keys = {}
  for k in pairs(v) do keys[#keys + 1] = tostring(k) end
  if #keys == 0 then return "{}" end
  table.sort(keys)

  local out = {}
  for _, k in ipairs(keys) do out[#out + 1] = inner .. encode(k, inner) .. ": " .. encode(v[k], inner) end
  return "{\n" .. table.concat(out, ",\n") .. "\n" .. indent .. "}"
end

function json.encode(v) return encode(v, "") end

-- nil when the text isn't valid JSON
function json.decode(s)
  local pos = 1
  local value

  local function skip() pos = s:find("[^ \t\r\n]", pos) or #s + 1 end

  local function expect(c)
    skip()
    if s:sub(pos, pos) ~= c then error("expected " .. c .. " at " .. pos) end
    pos = pos + 1
  end

  local function str()
    expect('"')
    local out = {}
    while true do
      local c = s:sub(pos, pos)
      if c == "" then error("unterminated string") end
      if c == '"' then pos = pos + 1; return table.concat(out) end
      if c == "\\" then
        local e = s:sub(pos + 1, pos + 1)
        if e == "u" then
          out[#out + 1] = utf8.char(tonumber(s:sub(pos + 2, pos + 5), 16))
          pos = pos + 6
        else
          out[#out + 1] = ({ n = "\n", r = "\r", t = "\t", b = "\b", f = "\f" })[e] or e
          pos = pos + 2
        end
      else
        out[#out + 1] = c
        pos = pos + 1
      end
    end
  end

  value = function()
    skip()
    local c = s:sub(pos, pos)
    if c == "{" then
      pos = pos + 1
      local obj = {}
      skip()
      if s:sub(pos, pos) == "}" then pos = pos + 1; return obj end
      repeat
        local k = str()
        expect(":")
        obj[k] = value()
        skip()
        c = s:sub(pos, pos); pos = pos + 1
      until c ~= ","
      if c ~= "}" then error("expected } at " .. pos) end
      return obj
    elseif c == "[" then
      pos = pos + 1
      local arr = {}
      skip()
      if s:sub(pos, pos) == "]" then pos = pos + 1; return arr end
      repeat
        arr[#arr + 1] = value()
        skip()
        c = s:sub(pos, pos); pos = pos + 1
      until c ~= ","
      if c ~= "]" then error("expected ] at " .. pos) end
      return arr
    elseif c == '"' then
      return str()
    end
    if s:sub(pos, pos + 3) == "true"  then pos = pos + 4; return true  end
    if s:sub(pos, pos + 4) == "false" then pos = pos + 5; return false end
    if s:sub(pos, pos + 3) == "null"  then pos = pos + 4; return nil   end
    local num = s:match("^-?%d+%.?%d*[eE]?[-+]?%d*", pos)
    if not num then error("unexpected " .. c .. " at " .. pos) end
    pos = pos + #num
    return tonumber(num)
  end

  local ok, result = pcall(value)
  return ok and result or nil
end

return json
