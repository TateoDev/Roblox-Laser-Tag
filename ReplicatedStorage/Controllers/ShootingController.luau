--!strict

local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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
		local hitSomething : RaycastResult, playerHit : Player = fireShot:InvokeServer(unitRay.Origin, unitRay.Direction)
		
		if GameSettings.debug then
			gizmo.setColor3(Color3.new(1, 0, 0))
			
			task.spawn(function()
				local start = os.clock()
				local conn : RBXScriptConnection = nil
				
				conn = RunService.RenderStepped:Connect(function()
					if os.clock() > start + SHOT_LIFETIME then
						conn:Disconnect()
					end
					gizmo.drawRay(unitRay.Origin, unitRay.Direction * SHOT_RANGE)
				end)
			end)
		end
		
		AudioController.playSoundEffect("ShootSFX", 0.5, humanoidRootPart, true)
		
		if hitSomething then
			if playerHit then
				if GameSettings.debug then gizmo.setColor3(Color3.new(0.282353, 1, 0.0196078)) end
				CreateTracer(unitRay.Origin, unitRay.Origin + (unitRay.Direction * hitSomething.Distance), player)
			end
		else
			CreateTracer(unitRay.Origin, unitRay.Origin + (unitRay.Direction * GameSettings.shotDistance), player)
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
	params:AddToFilter(newCharacter)
end)

return ShootingController
