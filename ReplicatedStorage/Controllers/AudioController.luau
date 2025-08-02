--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

type AudioControllerImpl = {
	musicLayers : {[number] : Sound | number};

	playSoundEffect: (soundName : string, volume : number, parent : Instance?, global : boolean?) -> ();
	setMusicAtLayer: (self : AudioControllerImpl, music : string, layer : number) -> ();
	stopMusicAtLayer: (self : AudioControllerImpl, layer : number) -> ();
}

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local playSound = remotes.PlaySound

local musicFolder = ReplicatedStorage.Assets.Music
local soundEffectFolder = ReplicatedStorage.Assets.SoundEffects

local AudioController : AudioControllerImpl = {
	musicLayers = {},
	playSoundEffect = function(soundName, volume, parent, global)
		if global then
			playSound:FireServer(soundName, volume, parent)
		else
			task.spawn(function()
				local sound = soundEffectFolder:FindFirstChild(soundName):Clone() :: Sound
				if not sound then error(`Sound {soundName} not found`) end
				sound.Parent = parent or workspace
				sound.Volume = volume
				sound.PlayOnRemove = true
				sound:Destroy()
			end)
		end
	end,
  
	setMusicAtLayer = function(self, music, layer)
		local musicToPlay : Sound = musicFolder[music]
		if not musicToPlay then return end
		self.musicLayers[layer] = musicToPlay

		local maxLayer = 0

		for k in pairs(self.musicLayers) do
			if type(k) == "number" and k > maxLayer and self.musicLayers[k] ~= 0 then
				maxLayer = k
			end
		end

		if layer == maxLayer then
			for _, sound : Sound in musicFolder:GetChildren() do
				sound:Stop()
			end
			musicToPlay:Play()
		end
	end,
  
	stopMusicAtLayer = function(self, layer)
		if not self.musicLayers[layer] then return end
		musicFolder[self.musicLayers[layer]]:Stop()
		self.musicLayers[layer] = 0
		for i = #self.musicLayers, 1, -1 do
			if typeof(self.musicLayers[i]) ~= "string" then continue end
			if musicFolder[self.musicLayers[i]] then
				musicFolder[self.musicLayers[i]]:Play()
				break
			end
		end
	end,
}


return AudioController
