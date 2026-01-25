require "/pat/wowozela/item/soundplayer.lua"
require "/pat/wowozela/item/particlespawner.lua"
require "/scripts/vec2.lua"

function init()
  activeItem.setHoldingItem(false)
  if not player then return script.setUpdateDelta(0) end

  PrimarySound = SoundPlayer:new("primary")
  AltSound = SoundPlayer:new("alt")

  SpawnOffset = config.getParameter("spawnOffset")
  SpawnOffset.current = SpawnOffset.normal

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

    if input.bindDown("pat_wowozela", "menu") then
      activeItem.interact("ScriptPane", { baseConfig = "/pat/wowozela/menu/wowozela.config", holdBind = true })
    end
  else
    PrimarySound:update(fireMode == "primary")
    AltSound:update(fireMode == "alt")
  end

  local aimPos = activeItem.ownerAimPosition()
  local aimDir = aimPos[1] > mcontroller.xPosition() and 1 or -1
  activeItem.setFacingDirection(aimDir)

  local targetOffset = mcontroller.crouching() and SpawnOffset.crouch or SpawnOffset.normal
  if targetOffset[1] ~= 0 then targetOffset = { targetOffset[1] * aimDir, targetOffset[2] } end
  targetOffset = vec2.rotate(targetOffset, mcontroller.rotation())
  SpawnOffset.current = vec2.approach(SpawnOffset.current, targetOffset, SpawnOffset.approachRate * dt)

  local spawnPos = vec2.add(mcontroller.position(), SpawnOffset.current)
  local aimAngle = vec2.angle(world.distance(aimPos, spawnPos))
  local aimDegrees = (math.deg(aimAngle) + 90) % 360
  if aimDegrees > 180 then aimDegrees = 360 - aimDegrees end

  local pitch = aimDegrees / 89
  PrimarySound:setPitch(pitch)
  AltSound:setPitch(pitch)

  if PrimarySound.playing or AltSound.playing then
    local hue = aimDegrees * 2.7
    ParticleSpawner:spawn(spawnPos, aimAngle, hue)
    
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
