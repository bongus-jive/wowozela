require "/pat/wowozela/item/soundplayer.lua"
require "/pat/wowozela/item/particlespawner.lua"

function init()
  activeItem.setHoldingItem(false)
  if not player then return script.setUpdateDelta(0) end

  PrimarySound = SoundPlayer:new("primary")
  AltSound = SoundPlayer:new("alt")

  ParticleSpawner:init(config.getParameter("particleConfig"))

  getSounds()
  message.setHandler("pat_wowozela_updateSounds", function(_, isLocal)
    if isLocal then getSounds() end
  end)
end

function getSounds()
  local data = player.getProperty("pat_wowozela") or root.assetJson("/pat/wowozela/samples/samples.config:defaults")
  PrimarySound:setSound(data.primary)
  AltSound:setSound(data.alt)
end

function update(dt, fireMode, shiftHeld)
  if input and input.mouse then
    local firing = fireMode ~= "none"
    PrimarySound:update(firing and input.mouse("MouseLeft"))
    AltSound:update(firing and input.mouse("MouseRight"))
  else
    PrimarySound:update(fireMode == "primary")
    AltSound:update(fireMode == "alt")
  end

  local aimPos = activeItem.ownerAimPosition()
  local aimAngle = activeItem.aimAngle(0, aimPos)
  local aimDir = aimPos[1] > mcontroller.xPosition() and 1 or -1
  activeItem.setFacingDirection(aimDir)

  local aimDegrees = (math.deg(aimAngle) + 90) % 180
  if aimDir == -1 then aimDegrees = 180 - aimDegrees end

  local pitch = aimDegrees / 89
  PrimarySound:setPitch(pitch)
  AltSound:setPitch(pitch)

  if PrimarySound.playing or AltSound.playing then
    local hue = aimDegrees * 2.7
    ParticleSpawner:spawn(aimAngle, hue)
    
    activeItem.emote("Blabbering")
    IsPlaying = true
  elseif IsPlaying then
    activeItem.emote("Idle")
    IsPlaying = false
  end

  sb.setLogMap("^pink;Wowozela M1", "%s", PrimarySound.sound)
  sb.setLogMap("^pink;Wowozela M2", "%s", AltSound.sound)
  sb.setLogMap("^pink;Wowozela Pitch", "%s", pitch)
end
