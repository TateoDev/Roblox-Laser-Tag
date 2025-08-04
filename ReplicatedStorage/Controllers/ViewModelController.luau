--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Teams = game:GetService("Teams")

local Spring = require(ReplicatedStorage.Util.Spring)

local controllers = ReplicatedStorage:WaitForChild("Controllers")
local ShootingController = require(controllers.ShootingController)

type ViewModelControllerImpl = {
	currentViewModel : Model?;
	changeViewModel : (self : ViewModelControllerImpl, model : Model?) -> ();a
	_updateViewModel : (self : ViewModelControllerImpl) -> ();
}

local MODEL_OFFSET = Vector3.new(2, -1, 3)

local viewModels = ReplicatedStorage:WaitForChild("Assets").Viewmodels

local player = Players.LocalPlayer

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid

local camera = workspace.CurrentCamera

local modelSpring = Spring.new(Vector3.new())
modelSpring.Speed = 20
modelSpring.Damping = 0.6

local modelRotationSpring = Spring.new(Vector3.new())
modelRotationSpring.Speed = 8
modelRotationSpring.Damping = 0.7

local ViewModelController : ViewModelControllerImpl = {
	currentViewModel = nil,
	changeViewModel = function(self, model)
		if self.currentViewModel then
			self.currentViewModel:Destroy()
		end
		if model then
			self.currentViewModel = model:Clone() 
			if self.currentViewModel then
				self.currentViewModel.Parent = camera
			end
		end
	end,
	_updateViewModel = function(self)
		if not self.currentViewModel then return end
		local cameraCFrame = camera.CFrame
		
		modelSpring.Target = cameraCFrame.Position + (cameraCFrame.RightVector * MODEL_OFFSET.X) + (cameraCFrame.UpVector * MODEL_OFFSET.Y) + (cameraCFrame.LookVector * MODEL_OFFSET.Z)
		
		self.currentViewModel:PivotTo(
			CFrame.new(Vector3.new(
				modelSpring.Position.X,
				modelSpring.Position.Y,
				modelSpring.Position.Z
				)) * CFrame.Angles(cameraCFrame:ToEulerAnglesXYZ()) * CFrame.Angles(modelRotationSpring.Position.X, modelRotationSpring.Position.Y, modelRotationSpring.Position.Z)
		)
	end,
}

RunService:BindToRenderStep("ViewModel", Enum.RenderPriority.Character.Value, function()
	ViewModelController:_updateViewModel()
end)

ShootingController.ShootEvent.Event:Connect(function()
	modelRotationSpring:Impulse(Vector3.new(20, 0, 0))
end)

player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = newCharacter:WaitForChild("Humanoid")
	if player.Team == Teams.Lobby then
		ViewModelController:changeViewModel(nil)
	else
		ViewModelController:changeViewModel(viewModels.Part)
	end
end)

return ViewModelController
