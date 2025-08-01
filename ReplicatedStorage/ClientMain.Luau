local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Controllers = ReplicatedStorage:WaitForChild("Controllers")

for _, controller in Controllers:GetChildren() do
	if controller:IsA("ModuleScript") then
		require(controller)
	end
end
