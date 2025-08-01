--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local util = ReplicatedStorage:WaitForChild("Util")
local GameSettings = require(util.GameSettings)
local CreateTracer = require(ReplicatedStorage.Util.CreateTracer)

type ShootingServiceImpl = {
	fireShot : (shotOwner : Player, unitOrigin : Vector3, unitDirection : Vector3) -> (RaycastResult?, Player?)
}

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local fireFunction = remotes.FireShot

local ShootingService : ShootingServiceImpl = {
	fireShot = function(shotOwner, unitOrigin, unitDirection)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params:AddToFilter(shotOwner.Character or shotOwner.CharacterAdded:Wait())
		
		local extendedShot = workspace:Raycast(unitOrigin, unitDirection * GameSettings.shotDistance, params)
		if extendedShot then
			local playerShot = Players:GetPlayerFromCharacter(extendedShot.Instance.Parent)
			if not playerShot then return extendedShot, nil end
			
			local character = extendedShot.Instance.Parent
			local humanoid = character:FindFirstChild("Humanoid") :: Humanoid
			if not humanoid then return extendedShot, nil end
			
			humanoid:TakeDamage(50)
			
			CreateTracer(unitOrigin, unitOrigin + (unitDirection * extendedShot.Distance), shotOwner)
			
			return extendedShot, playerShot
		else
			CreateTracer(unitOrigin, unitOrigin + (unitDirection * GameSettings.shotDistance), shotOwner)
			return nil, nil
		end
	end,
}

fireFunction.OnServerInvoke = function(player, unitOrigin, unitDirection)
	ShootingService.fireShot(player, unitOrigin, unitDirection)
end


Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		for _, child in character:GetChildren() do
			if child:IsA("Accessory") then
				child:FindFirstChildWhichIsA("MeshPart").CanQuery = false
			end
		end
	end)
end)

return ShootingService
