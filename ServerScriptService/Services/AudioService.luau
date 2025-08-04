--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

type AudioServiceImpl = {
	playSoundEffect : (soundName : string, volume : number, parent : Instance?) -> ();
}

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local playSound = remotes.PlaySound

local assets = ReplicatedStorage:WaitForChild("Assets")
local soundEffectFolder = assets.SoundEffects

local AudioService : AudioServiceImpl = {
	playSoundEffect = function(soundName, volume, parent)
		local soundToPlay = soundEffectFolder:FindFirstChild(soundName):Clone() :: Sound
		if not soundToPlay then error(`sound {soundName} not found`) end
		soundToPlay.Parent = parent
		task.spawn(function()
			soundToPlay:Play()
			soundToPlay.Ended:Connect(function()
				soundToPlay:Destroy()
			end)
		end)
	end,
}

playSound.OnServerEvent:Connect(function(player, soundName : string, volume : number, parent : Instance?)
	if typeof(soundName) ~= "string" then return end
	
	AudioService.playSoundEffect(soundName, math.clamp(volume, 0, 2), parent)
end)

return AudioService
