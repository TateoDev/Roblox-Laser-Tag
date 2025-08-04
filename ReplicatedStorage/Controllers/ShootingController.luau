--!strict

local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")

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

local SHOT_COOLDOWN = GameSettings.shotCooldown
local SHOT_RANGE = GameSettings.shotDistance

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
		
		self.Debounces["shoot"] = true
		task.delay(SHOT_COOLDOWN, function()
			self.Debounces["shoot"] = nil
		end)
		
		local unitRay = camera:ViewportPointToRay(
			camera.ViewportSize.X / 2,
			camera.ViewportSize.Y / 2
		)
		local shotResults = fireShot:InvokeServer(unitRay.Origin, unitRay.Direction)
	end,
}


player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")
	params:AddToFilter(newCharacter)
	ContextActionService:UnbindAction("shoot")
	
	if player.Team ~= Teams.Lobby then
		ContextActionService:BindAction("shoot", function(actionName, inputState, inputObject)
			if inputState == Enum.UserInputState.Begin then
				ShootingController:Shoot()
			end
		end, false, Enum.UserInputType.MouseButton1)
	end
end)


return ShootingController
