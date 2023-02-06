--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = require(ReplicatedStorage.Remotes)

RunService.Heartbeat:Connect(function()
	Remotes.luanoid_move:FireServer("hi")

end)

Remotes.luanoid_move.OnClientReceive:Connect(function(...)
	--print(...)

end)