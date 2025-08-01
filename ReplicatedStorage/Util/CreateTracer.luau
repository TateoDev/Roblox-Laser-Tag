--!strict

--[[
Raycast visualizing code is heavily inspired and referenced from the gizmo module by Brad Sharp
https://github.com/BradSharp/Roblox-Miscellaneous/tree/master/Gizmo
]]--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local GLOBAL_ORIGIN = CFrame.new(0,0,0)
local TRACER_DURATION = 1

local assets = ReplicatedStorage:WaitForChild("Assets")

return function(from : Vector3, to : Vector3, owner : Player)
	local distance = math.abs((to - from).Magnitude)
	local orientation = GLOBAL_ORIGIN * CFrame.lookAt(from, to)
	
	local tracer = assets.ShotTracer:Clone()
	tracer.Size = Vector3.new(0.2, 0.2, distance)
	tracer.CFrame = orientation * CFrame.new(0,0, -distance * 0.5)
	tracer.Parent = workspace.ShotTracers
	tracer.Name = HttpService:GenerateGUID(false)
	
	if RunService:IsServer() then
		tracer:SetAttribute("Owner", owner.Name)
		task.delay(TRACER_DURATION/2, function()
			tracer.Transparency = 0.5
		end)
	else
		tracer:SetAttribute("Owner", "local")
		task.delay(TRACER_DURATION/2, function()
			TweenService:Create(
				tracer,
				TweenInfo.new(TRACER_DURATION / 2),
				{Transparency = 1}
			):Play()
		end)
	end
	Debris:AddItem(tracer, TRACER_DURATION)
	return tracer
end
