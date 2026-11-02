-- Theme style for one permission character (same rules as yazi's default)
local function perm_style(c)
  if c == "-" or c == "?" then
    return th.status.perm_sep
  elseif c == "r" then
    return th.status.perm_read
  elseif c == "w" then
    return th.status.perm_write
  elseif c == "x" or c == "s" or c == "S" or c == "t" or c == "T" then
    return th.status.perm_exec
  end
  return th.status.perm_type
end

-- Give a span the box background, if the theme defines one
local function boxed(span, bg)
  if bg then
    return span:bg(bg)
  end
  return span
end

-- File Info: name, size and permissions as a list of spans
local function file_info(self)
  local h = self._current.hovered
  if not h then
    return {}
  end

  local style = self:style()
  local bg = style.alt:bg()

  local spans = {
    ui.Span(" " .. ui.printable(h.name) .. "  "):style(style.alt),
    ui.Span(ya.readable_size(h.cha.len or 0) .. "  "):style(style.alt),
  }

  local perm = h.cha:perm()
  if perm then
    for i = 1, #perm do
      local c = perm:sub(i, i)
      spans[#spans + 1] = boxed(ui.Span(c):style(perm_style(c)), bg)
    end
  end

  spans[#spans + 1] = ui.Span(" "):style(style.alt)
  return spans
end

-- Mode: flat label using the theme's mode colors
local function mode(self)
  local name = tostring(self._tab.mode):sub(1, 3):upper()
  return ui.Line {
    ui.Span(" " .. name .. " "):style(self:style().main),
  }
end

-- Redraw: same as yazi's default, plus a centered line for file info
local function redraw(self)
  local left = self:children_redraw(self.LEFT)
  local right = self:children_redraw(self.RIGHT)
  local right_width = right:width() -- measure before `right` is consumed below

  return {
    ui.Text(""):area(self._area):style(th.status.overall),
    ui.Line(left):area(self._area),
    ui.Line(file_info(self)):area(self._area):align(ui.Align.CENTER),
    ui.Line(right):area(self._area):align(ui.Align.RIGHT),
    table.unpack(ui.redraw(Progress:new(self._area, right_width))),
  }
end

-- Icon: always use the icon's own color, even on the hovered row
local function icon(self)
  local i
  if th.icon then
    -- newer yazi
    i = th.icon:match(self._file, { hovered = self._file.is_hovered })
  else
    -- older yazi
    i = self._file:icon()
  end

  if not i then
    return ""
  end
  return ui.Line(i.text .. " "):style(i.style)
end

local function setup()
  Status.mode = mode
  Status.redraw = redraw
  Entity.icon = icon

  Status:children_remove(2, Status.LEFT)   -- size
  Status:children_remove(3, Status.LEFT)   -- name (now in file_info)
  Status:children_remove(4, Status.RIGHT)  -- permissions
  Status:children_remove(5, Status.RIGHT)  -- Top/Bot/%
  Status:children_remove(6, Status.RIGHT)  -- 1/4
end

return { setup = setup }
