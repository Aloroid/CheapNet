--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = require(ReplicatedStorage.Remotes)
local CheapNet = require(ReplicatedStorage.Packages.CheapNet)

RunService.Heartbeat:Connect(function()
	
	for player in Remotes.luanoid_move:eachS() do
		--print("Fired")
	end
end)

while task.wait() do
	--print("Fired")
	local t = {3, 2}
	for i = 1, 1 do
		Remotes.luanoid_move:FireAllClients("rgoiaj", CheapNet.GetGlobalIdentifier("true"), Remotes.luanoid_move:GetLocalIdentifier(t))
	--Remotes.luanoid_spawn:FireAllClients(Vector3.new(), "Player")
	end
end
