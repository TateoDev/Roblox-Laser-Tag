local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("Services")

for _, service in Services:GetChildren() do
	if service:IsA("ModuleScript") then
		print(`Requiring {service.Name}`)
		local s = require(service)
	end
end
