--!strict

--[[

THIS CODE IS HEAVILY BASED ON eliminate the person by Schnogrind
https://www.roblox.com/games/16864761565/eliminate-the-person-Uncopylocked

]]--

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")

local Spring = require(ReplicatedStorage.Util.Spring)

local DASH_SPEED = 100
local DASH_COOLDOWN = 1

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local UpdateTorso = remotes.UpdateTorsoRotation

local player = Players.LocalPlayer

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local upperTorso = character:WaitForChild("UpperTorso")
local waist = upperTorso:WaitForChild("Waist") :: Motor6D

local playerScripts = player:WaitForChild("PlayerScripts")
local playerModule = require(playerScripts.PlayerModule)

playerModule:GetControls():Disable()

local camera = workspace.CurrentCamera

local pressedKeys : {[string] : boolean} = {}

local canDash = true

local front, side = Vector3.new(0,0,1), Vector3.new(1,0,0)
local direction = Spring.new(Vector3.new(0,0,0))
direction.Speed = 11

local sendInterval = 0.1  -- 10 updates per second
local accumulator = 0

local function handlePressedKeys(actionName, inputState, input : InputObject)
	if inputState == Enum.UserInputState.Begin then
		pressedKeys[input.KeyCode.Name] = true
	elseif inputState == Enum.UserInputState.End then
		pressedKeys[input.KeyCode.Name] = nil
	end
end
ContextActionService:BindAction("KeyboardInputs", handlePressedKeys, false, Enum.UserInputType.Keyboard)

local function dash(actionName, inputState, input : InputObject)
	if inputState ~= Enum.UserInputState.Begin or not canDash then return end
	canDash = false
	
	AudioController.playSoundEffect("DashSFX", 0.5, humanoidRootPart, false)

	local dashVelocity = Instance.new("LinearVelocity")
	dashVelocity.Parent = humanoidRootPart
	local attachment = Instance.new("Attachment")
	attachment.Parent = humanoidRootPart
	
	dashVelocity.MaxForce = math.huge
	dashVelocity.VectorVelocity = (humanoid.MoveDirection * Vector3.new(1, 0, 1)) * DASH_SPEED
	dashVelocity.Attachment0 = attachment
	
	local t = RunService.RenderStepped:Wait()
	Debris:AddItem(dashVelocity, t)
	Debris:AddItem(attachment, t)
	task.delay(DASH_COOLDOWN, function()
		canDash = true
	end)
end
ContextActionService:BindAction("Dash", dash, false, Enum.KeyCode.LeftShift)

local function jump(actionName, inputState, input : InputObject)
	if inputState ~= Enum.UserInputState.Begin then return end
	humanoid.Jump = true
end
ContextActionService:BindAction("Jump", jump, false, Enum.KeyCode.Space)

RunService:BindToRenderStep("Movement", Enum.RenderPriority.Character.Value, function()
	direction.Target = Vector3.new()
	if pressedKeys.W then
		direction.Target = direction.Target - front
	end
	if pressedKeys.S then
		direction.Target = direction.Target + front
	end
	if pressedKeys.A then
		direction.Target = direction.Target - side
	end
	if pressedKeys.D then
		direction.Target = direction.Target + side
	end
	player:Move(direction.Position, true)
end)

RunService:BindToRenderStep("SendTorsoPitch", Enum.RenderPriority.Input.Value, function(dt)
	accumulator = accumulator + dt
	if accumulator < sendInterval then return end
	accumulator = accumulator - sendInterval

	local look = camera.CFrame.LookVector
	local pitchAngle = math.asin(math.clamp(look.Y, -1, 1))  -- in radians

	-- Optionally quantize to reduce bandwidth
	UpdateTorso:FireServer(pitchAngle)
end)

player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = newCharacter:WaitForChild("Humanoid")
	humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")
end)

return nil
