require "/pat/wowozela/soundplayer.lua"
require "/pat/wowozela/particlespawner.lua"
require "/scripts/interp.lua"

function init()
  activeItem.setHoldingItem(false)

  PrimarySound = SoundPlayer:new("primary")
  AltSound = SoundPlayer:new("alt")
  
  ParticleSpawner:init(config.getParameter("particleConfig"))

  do -- no menu yet <3
    local samples = root.assetJson("/pat/wowozela/samples/samples.config")
    local sounds = {}
    for category, files in pairs(samples) do
      for _, file in pairs(files) do
        table.insert(sounds, string.format("/pat/wowozela/samples/%s/%s", category, file))
      end
    end
    PrimarySound:setSound(sounds[math.random(#sounds)])
    AltSound:setSound(sounds[math.random(#sounds)])
  end
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

  sb.setLogMap("^pink;Wowozela M1", PrimarySound.sound)
  sb.setLogMap("^pink;Wowozela M2", AltSound.sound)
  sb.setLogMap("^pink;Wowozela Pitch", pitch)
end
