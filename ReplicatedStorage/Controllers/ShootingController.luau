--!strict

local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local controllers = ReplicatedStorage:WaitForChild("Controllers")
local AudioController = require(controllers.AudioController)

local util = ReplicatedStorage:WaitForChild("Util")
local GameSettings = require(util.GameSettings)
local gizmo = require(util.gizmo)

local CreateTracer = require(ReplicatedStorage.Util.CreateTracer)

type ShootingControllerImpl = {
	Debounces : {[string] : boolean};
	ShootEvent : BindableEvent;
	Shoot : (self : ShootingControllerImpl) -> ()
}

local SHOT_COOLDOWN = 0.2
local SHOT_RANGE = 400
local SHOT_LIFETIME = SHOT_COOLDOWN

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local fireShot = remotes.FireShot

local player = game.Players.LocalPlayer
local character = player.Character or  player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local camera = workspace.CurrentCamera

local params = RaycastParams.new()
params:AddToFilter(character)
params:AddToFilter(camera)
params.FilterType = Enum.RaycastFilterType.Exclude

local ShootingController : ShootingControllerImpl = {
	Debounces = {},
	ShootEvent = script.ShootingEvent,
	Shoot = function(self)
		if self.Debounces["shoot"] then return end

		self.ShootEvent:Fire()
		AudioController.playSoundEffect("ShootSFX", 0.5, humanoidRootPart, true)

		self.Debounces["shoot"] = true
		task.delay(SHOT_COOLDOWN, function()
			self.Debounces["shoot"] = nil
		end)

		local unitRay = camera:ViewportPointToRay(
			camera.ViewportSize.X / 2,
			camera.ViewportSize.Y / 2
		)
		local shotResults = fireShot:InvokeServer(unitRay.Origin, unitRay.Direction)
		
		if shotResults then
			CreateTracer(unitRay.Origin, unitRay.Direction * shotResults.Distance, player)
		else
			CreateTracer(unitRay.Origin, unitRay.Direction * SHOT_RANGE, player)
		end
	end,
}

ContextActionService:BindAction("shoot", function(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		ShootingController:Shoot()
	end
end, false, Enum.UserInputType.MouseButton1)

player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")
	params:AddToFilter(newCharacter)
end)

workspace.ShotTracers.DescendantAdded:Connect(function(desc)
	if desc:GetAttribute("Owner") == player.Name then
		desc:Destroy()
	end
end)

return ShootingController
