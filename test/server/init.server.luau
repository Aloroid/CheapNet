--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = require(ReplicatedStorage.Remotes)

RunService.Heartbeat:Connect(function()
	
	
	for player in Remotes.luanoid_move:eachS() do
		--print("Fired")
	end
end)

while task.wait(1/20) do
	print("Fired")
	for i = 1, 200 do
		Remotes.luanoid_move:FireAllClients("rgoiaj")
	--Remotes.luanoid_spawn:FireAllClients(Vector3.new(), "Player")
	end
end
