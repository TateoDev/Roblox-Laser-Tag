--!strict

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

type CameraControllerImpl = {
	fovMods : {[string] : number};
	_updateCamera : (self : CameraControllerImpl) -> ();
}

local DEFAULT_FOV = 70
local ROLL_DEGREES = 5
local SMOOTH_SPEED = 0.1

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

local camera = workspace.CurrentCamera
local currentTilt = 0

local CameraController : CameraControllerImpl = {
	fovMods = {},
	_updateCamera = function(self)
		-- FOV adjustment
		local newFov = DEFAULT_FOV
		for _, mod in self.fovMods do
			newFov += mod
		end
		camera.FieldOfView = math.lerp(camera.FieldOfView, newFov, 0.3)
		
		-- Tilt logic
		local moveDir = humanoid.MoveDirection
		local targetTilt = 0
		
		if moveDir.Magnitude > 0 then
			local rightDot = moveDir.Unit:Dot(camera.CFrame.RightVector)
			targetTilt = math.rad(ROLL_DEGREES) * math.clamp(rightDot, -1, 1)
		end
		
		currentTilt += (targetTilt - currentTilt) * SMOOTH_SPEED
		
		-- Snap to zero if very close, to avoid float drift
		if math.abs(currentTilt) < 0.001 then
			currentTilt = 0
		end
		
		camera.CFrame *= CFrame.Angles(0, 0, currentTilt)
	end
}

RunService:BindToRenderStep("Camera", Enum.RenderPriority.Camera.Value, function()
	CameraController:_updateCamera()
end)

player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = newCharacter:WaitForChild("Humanoid") :: Humanoid
	humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart") :: BasePart
	if player.Team == Teams.Lobby then
		player.CameraMode = Enum.CameraMode.Classic
	else
		player.CameraMode = Enum.CameraMode.LockFirstPerson
	end
end)

return CameraController
