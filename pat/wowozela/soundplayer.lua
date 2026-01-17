SoundPlayer = {}
SoundPlayer.playing = false

function SoundPlayer:new(soundName)
  animator.stopAllSounds(soundName)
  return setmetatable({ soundName = soundName }, { __index = self })
end

function SoundPlayer:update(playing)
  if playing == self.playing then return end
  self.playing = playing

  if playing then
    self:start()
  else
    self:stop()
  end
end

function SoundPlayer:setSound(sound)
  self.sound = sound
  animator.setSoundPool(self.soundName, { sound })
end

function SoundPlayer:setPitch(pitch)
  if pitch < 0.01 then pitch = 0.01 end
  animator.setSoundPitch(self.soundName, pitch)
end

function SoundPlayer:start()
  animator.stopAllSounds(self.soundName)
  animator.setSoundVolume(self.soundName, 1, 0)
  animator.playSound(self.soundName, -1)
end

function SoundPlayer:stop()
  animator.setSoundVolume(self.soundName, 0, 0.06)
end
