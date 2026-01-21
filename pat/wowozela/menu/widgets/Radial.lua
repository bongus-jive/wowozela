require "/pat/wowozela/util.lua"
require "/scripts/vec2.lua"
local rad270, rad360 = math.pi * 1.5, math.pi * 2

RadialWidget = {}

function RadialWidget:new(widgetName, callback)
  local new = { widgetName = widgetName, callback = callback }
  return setmetatable(new, { __index = self })
end

function RadialWidget:init()
  self.canvas = widget.bindCanvas(self.widgetName)
  self.config = widget.getData(self.widgetName)
  self.size = self.canvas:size()
  self.center = vec2.div(self.size, 2)
  self.selected = {}
  self.mouseEvent = function(...) self:click(...) end
end

function RadialWidget:update()
  if not self.built then return end

  local mousePosition = self.canvas:mousePosition()
  local mouseDistance = vec2.sub(self.center, mousePosition)
  local mouseMag = vec2.mag(mouseDistance)

  if self.config.innerRadius <= mouseMag and mouseMag <= self.config.outerRadius then
    local angle = (rad270 - math.atan(mouseDistance[2], mouseDistance[1])) % rad360
    self.hoverIndex = (angle // self.sliceSize) % self.sliceCount + 1
  else
    self.hoverIndex = nil
  end

  self:draw()
end

function RadialWidget:build(options)
  widget.removeAllChildren(self.widgetName)

  self.sliceCount = math.max(#options, self.config.minSlices)
  self.sliceSize = rad360 / self.sliceCount

  self.slices, self.outerTris, self.innerTris = {}, {}, {}
  local sliceSegments = math.ceil(self.config.minSegments / self.sliceCount)
  local totalSegments = sliceSegments * self.sliceCount

  local function circlePoint(angle, radius)
    return { self.center[1] + math.sin(angle) * radius, self.center[2] + math.cos(angle) * radius }
  end

  for index = 1, self.sliceCount do
    local startAngle = self.sliceSize * (index - 1)
    local slice = { tris = {} }
    
    local innerPoints, outerPoints = {}, {}
    for i = 0, sliceSegments do
      local angle = i / totalSegments * rad360 + startAngle
      table.insert(innerPoints, circlePoint(angle, self.config.innerRadius))
      table.insert(outerPoints, circlePoint(angle, self.config.outerRadius))
      
      if i ~= 0 then
        table.insert(slice.tris, { outerPoints[i], innerPoints[i], outerPoints[i + 1] })
        table.insert(slice.tris, { innerPoints[i], outerPoints[i + 1], innerPoints[i + 1] })
        table.insert(self.innerTris, { innerPoints[i], innerPoints[i + 1], self.center })
      end
    end
    table.move(slice.tris, 1, #slice.tris, #self.outerTris + 1, self.outerTris)
    
    slice.poly = innerPoints
    for i = #outerPoints, 1, -1 do
      table.insert(slice.poly, outerPoints[i])
    end
    
    local midAngle = startAngle + self.sliceSize / 2
    slice.iconPos = circlePoint(midAngle, self.config.iconRadius)
    
    local option = options[index]
    if option then
      slice.item = option.item
      local name = string.format("%s.%s", self.widgetName, index)
      local pos = circlePoint(midAngle, self.config.labelRadius)
      widget.addChild(self.widgetName, self.config.labelConfig, index)
      widget.setPosition(name, pos)
      widget.setText(name, option.label)
    end

    table.insert(self.slices, slice)
  end

  self.built = true
end

function RadialWidget:draw()
  self.canvas:clear()
  self.canvas:drawTriangles(self.innerTris, self.config.centerColor)
  self.canvas:drawTriangles(self.outerTris, self.backColor)

  local icons = {}
  for i, slice in ipairs(self.slices) do
    if slice.item then
      local isPrimary = slice.item == self.selected.primary
      local isAlt = slice.item == self.selected.alt
      
      if isPrimary and isAlt then
        self.canvas:drawTriangles(slice.tris, self.config.dualColor)
        table.insert(icons, { self.config.dualIcon, slice.iconPos })
      elseif isPrimary then
        self.canvas:drawTriangles(slice.tris, self.config.primaryColor)
        table.insert(icons, { self.config.primaryIcon, slice.iconPos })
      elseif isAlt then
        self.canvas:drawTriangles(slice.tris, self.config.altColor)
        table.insert(icons, { self.config.altIcon, slice.iconPos })
      end
    end
    
    self.canvas:drawPoly(slice.poly, self.lineColor, self.config.lineWidth)
  end

  local hoverSlice = self.slices[self.hoverIndex]
  if hoverSlice and hoverSlice.item then
    self.canvas:drawTriangles(hoverSlice.tris, self.config.hoverBackColor)
    self.canvas:drawPoly(hoverSlice.poly, self.config.hoverLineColor, self.config.lineWidth)
  end

  for _, icon in pairs(icons) do
    self.canvas:drawImageDrawable(icon[1], icon[2], self.config.iconScale)
  end
end

function RadialWidget:setHue(hue)
  local back, line = self.config.backHSVA, self.config.lineHSVA
  self.backColor = wowoUtil.hsvToRgb(hue + back[1], back[2], back[3], back[4])
  self.lineColor = wowoUtil.hsvToRgb(hue + line[1], line[2], line[3], line[4])
end

function RadialWidget:getSelected()
  return self.selected.primary, self.selected.alt
end

function RadialWidget:setSelected(primary, alt)
  self.selected.primary = primary
  self.selected.alt = alt
end

function RadialWidget:click(pos, button, down)
  if not down or not self.hoverIndex then return end

  local slice = self.slices[self.hoverIndex]
  if not slice or not slice.item then return end

  if button == 0 then
    self.selected.primary = slice.item
  elseif button == 2 then
    self.selected.alt = slice.item
  elseif button ~= 1 then
    return
  end

  self.callback(slice.item, button)
end
