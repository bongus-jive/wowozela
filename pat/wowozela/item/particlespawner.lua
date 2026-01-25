require "/pat/wowozela/util.lua"
require "/scripts/vec2.lua"

ParticleSpawner = {}
function ParticleSpawner:init(cfg)
  self.config = cfg
  
  self.particle = sb.jsonMerge(cfg.specification)
  self.particle.finalVelocity = { 0, 0 }

  local action = { action = "particle", specification = self.particle, time = 0, ["repeat"] = false }
  self.projectileParams = { periodicActions = { action }, onlyHitTerrain = true }
end

function ParticleSpawner:spawn(position, angle, hue)
  local cfg = self.config
  local spec = self.particle

  spec.size = cfg.specification.size + (cfg.sizeAmplitude * math.sin(world.time() / cfg.sizePeriod))
  spec.color = wowoUtil.hsvToRgb(hue)
  spec.velocity = vec2.withAngle(angle, cfg.speed)
  spec.position = vec2.withAngle(angle, cfg.distance)
  spec.approach = vec2.withAngle(angle, cfg.resistance)
  spec.approach[1] = math.abs(spec.approach[1])
  spec.approach[2] = math.abs(spec.approach[2])
  
  world.spawnProjectile("pat_wowozela_particlespawner", position, entity.id(), { 0, 0 }, true, self.projectileParams)
end
