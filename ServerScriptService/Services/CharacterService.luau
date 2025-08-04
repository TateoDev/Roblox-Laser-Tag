--[[
I'm gonna be honest here, I try write most of my code on my own, but this is almost straight ChatGPT

The code is kinda ugly, but it works. I'll clean it up once I finished everything else up
]]--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local event = remotes.UpdateTorsoRotation

local assets = ReplicatedStorage:WaitForChild("Assets")

-- Allowed pitch range to prevent extreme values (e.g., +/- 60 degrees)
local MAX_PITCH = math.rad(30)

-- Keep originalC0 per character to avoid drift
local originalC0s = {}

local function onCharacterAdded(player, character)
	local upperTorso = character:WaitForChild("UpperTorso")
	local waist = upperTorso:WaitForChild("Waist") :: Motor6D
	originalC0s[player] = waist.C0
	
	-- Clean up when character is removed
	character:WaitForChild("Humanoid").Died:Connect(function()
		originalC0s[player] = nil
	end)
	
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		onCharacterAdded(player, char)
		
		local highlight = assets.PlayerHighlight:Clone()
		highlight.OutlineColor = player.TeamColor.Color
		highlight.FillColor = player.TeamColor.Color
		
		highlight.Parent = char
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end)


event.OnServerEvent:Connect(function(player, pitchAngle)
	-- Basic validation
	if type(pitchAngle) ~= "number" then return end
	if math.abs(pitchAngle) > MAX_PITCH then
		pitchAngle = math.clamp(pitchAngle, -MAX_PITCH, MAX_PITCH)
	end

	local character = player.Character
	if not character then return end
	local upperTorso = character:FindFirstChild("UpperTorso")
	if not upperTorso then return end
	local waist = upperTorso:FindFirstChild("Waist") :: Motor6D
	if not waist then return end

	local originalC0 = originalC0s[player]
	if not originalC0 then return end

	-- Apply pitch directly (no smoothing here; smoothing could be added server-side if needed)
	local pitchCFrame = CFrame.Angles(pitchAngle, 0, 0)
	waist.C0 = originalC0 * pitchCFrame
end)

return nil
