require "/pat/wowozela/menu/widgets/ScrollInput.lua"
require "/pat/wowozela/menu/widgets/Radial.lua"

function init()
  PageScroller = ScrollInputWidget:new("pageScroller", Callbacks.pageScroll)
  PageScroller:init()

  Radial = RadialWidget:new("radialCanvas", Callbacks.radialSelect)
  Radial:init()

  Pages = {}
  local samples = root.assetJson("/pat/wowozela/samples/samples.config")
  
  for category, files in pairs(samples) do
    local list = {}
    for _, file in ipairs(files) do
      if file:sub(1, 1) ~= "/" then
        file = string.format("/pat/wowozela/samples/%s/%s", category, file)
      end
      local name = file:match("^.*/(.+)%.(.+)$") or file
      table.insert(list, { item = file, label = name })
    end
    table.sort(list, function(a, b) return a.item < b.item end)
    table.insert(Pages, { category = category, items = list })
  end
  table.sort(Pages, function(a, b) return a.category < b.category end)

  local data = player.getProperty("pat_wowozela") or {}
  Radial:setSelected(data.primary, data.alt)
  setPage(data.page or 1)

  --Radial:setSelected("/pat/wowozela/samples/voices/kleiner.ogg", "/pat/wowozela/samples/drums/amenbreak.ogg")
end

function update()
  Radial:update()
end

function cursorOverride(pos)
  PageScroller:update(pos)
end

function uninit()
  save()
  stopSound()
end

function stopSound()
  if not LastPlayedSound then return end
  pane.stopAllSounds(LastPlayedSound)
end

function save()
  local primary, alt = Radial:getSelected()
  local data = { primary = primary, alt = alt, page = CurrentPage }
  player.setProperty("pat_wowozela", data)
  world.sendEntityMessage(player.id(), "pat_wowozela_updateSounds")
end

function setPage(index)
  if index > #Pages then index = 1 end
  if index <= 0 then index = #Pages end
  CurrentPage = index
  
  local page = Pages[index]
  local hue = (index - 1) / #Pages * 360
  
  widget.setText("category", page.category)
  widget.setText("pageNumber", string.format("%s / %s", index, #Pages))
  
  Radial:setHue(hue)
  Radial:build(page.items)
end

Callbacks = {}
function Callbacks.pageScroll(up)
  setPage(CurrentPage + (up and -1 or 1))
end

function Callbacks.pageButton(_, offset)
  setPage(CurrentPage + offset)
end

function Callbacks.radialSelect(file, button)
  save()

  stopSound()
  pane.playSound(file)
  LastPlayedSound = file
end
