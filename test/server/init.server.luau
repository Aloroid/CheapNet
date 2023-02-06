--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = require(ReplicatedStorage.Remotes)

RunService.Heartbeat:Connect(function()
	for i = 1, 200 do
		Remotes.luanoid_move:FireAllClients()
	--Remotes.luanoid_spawn:FireAllClients(Vector3.new(), "Player")
	end
end)

Remotes.luanoid_move.OnServerReceive:Connect(function(p: Vector3)
	--print("Receive", ...)
	
	
end)

Remotes.luanoid_move.OnServerReceive:Connect(function(p)
	
end)