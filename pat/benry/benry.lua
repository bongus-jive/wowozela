require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/interp.lua"

function init()
	timer = 0
	activeItem.setHoldingItem(false)
	
	icon = root.itemConfig(item.name()).config.inventoryIcon
end

function update(dt, fireMode, shiftHeld)
	local pos = vec2.add(mcontroller.position(), {0, 0.25 - (mcontroller.crouching() and 1 or 0)})
	local aimAngle, aimDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())
	activeItem.setFacingDirection(aimDirection)
	
	local mag = (util.clamp(world.magnitude(pos, activeItem.ownerAimPosition()), 5, 25) - 5) / 20
	local hue = interp.linear(mag, 0, 359)
	
	activeItem.setCursor("/pat/benry/cursor/"..math.floor(interp.linear(mag, 0, 71))..".cursor")
	activeItem.setInventoryIcon(icon.."?hueshift="..math.floor(hue))
	
	animator.setSoundPitch("prima", interp.linear(mag, 0.9, 1.2), dt)

	if fireMode == "primary" then
		if timer == 0 then
			animator.playSound("prima")
		end
		
		if timer < 4 + interp.linear(mag, 0.1, -0.6) then		
			if mcontroller.facingDirection() == aimDirection then
				world.spawnProjectile("pat_benry", pos, activeItem.ownerEntityId(), aimVector(aimAngle), false, {processing = "?hueshift="..hue})
			end
		end
	
		timer = math.min(4.2, timer + dt)
	else
		timer = 0
		animator.stopAllSounds("prima")
	end
end

function aimVector(aimAngle)
  local aimVector = vec2.rotate({1, 0}, aimAngle)
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function uninit()
	activeItem.setInventoryIcon(icon)
	animator.stopAllSounds("prima")
end