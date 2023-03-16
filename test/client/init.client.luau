--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = require(ReplicatedStorage.Remotes)
local CheapNet = require(ReplicatedStorage.Packages.CheapNet)

RunService.Heartbeat:Connect(function()
	Remotes.luanoid_move:FireServer("hi")
	--print("Iterating", #Remotes.luanoid_move._packets)

	for _, value, identifier, localIdentifier in Remotes.luanoid_move:eachC() do
		print(value, CheapNet.FromGlobalIdentifier(identifier), Remotes.luanoid_move:FromLocalIdentifier(localIdentifier))
	end
	
end)