require "/scripts/vec2.lua"

ParticleSpawner = {}
function ParticleSpawner:init(cfg)
  self.config = cfg
  
  self.particle = sb.jsonMerge(cfg.specification)
  self.particle.finalVelocity = { 0, 0 }

  local action = { action = "particle", specification = self.particle, time = 0, ["repeat"] = false }
  self.projectileParams = { actionOnReap = { action } }

  cfg.crouchOffset = vec2.add(cfg.offset, cfg.crouchOffset)
  self.offset = cfg.offset
end

function ParticleSpawner:spawn(angle)
  local cfg = self.config
  local spec = self.particle

  spec.size = cfg.specification.size + (cfg.sizeAmplitude * math.sin(world.time() / cfg.sizePeriod))

  spec.velocity = vec2.withAngle(angle, cfg.speed)
  spec.position = vec2.withAngle(angle, cfg.distance)
  spec.approach = vec2.withAngle(angle, cfg.resistance)
  spec.approach[1] = math.abs(spec.approach[1])
  spec.approach[2] = math.abs(spec.approach[2])

  local targetOffset = mcontroller.crouching() and cfg.crouchOffset or cfg.offset
  targetOffset = vec2.rotate(targetOffset, mcontroller.rotation())

  if not vec2.eq(self.offset, targetOffset) then
    self.offset = vec2.approach(self.offset, targetOffset, cfg.offsetApproachRate)
  end
  
  local position = vec2.add(mcontroller.position(), self.offset)

  local id = world.spawnProjectile("pat_wowozela_particlespawner", position, entity.id(), { 0, 0 }, true, self.projectileParams)
  world.callScriptedEntity(id, "projectile.die")
end

function ParticleSpawner:setHue(hue)
  self.particle.color = self:hueToRgb(hue)
end

function ParticleSpawner:hueToRgb(hue)
  hue = (hue / 360) % 1
  local i = math.floor(hue * 6)
  local f = hue * 6 - i
  local q = 1 - f
  i = i % 6
  
  local r, g, b
  if     i == 0 then r, g, b = 1, f, 0
  elseif i == 1 then r, g, b = q, 1, 0
  elseif i == 2 then r, g, b = 0, 1, f
  elseif i == 3 then r, g, b = 0, q, 1
  elseif i == 4 then r, g, b = f, 0, 1
  elseif i == 5 then r, g, b = 1, 0, q end

  return { r * 255, g * 255, b * 255 }
end
