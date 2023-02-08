--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = require(ReplicatedStorage.Remotes)

RunService.RenderStepped:Connect(function()
	Remotes.luanoid_move:FireServer("hi")

	--print("Iterating", #Remotes.luanoid_move._packets)
	for value in Remotes.luanoid_move:eachC() do
		--print("Received", value)
	end
	
end)

--[[Remotes.luanoid_move.OnClientReceive:Connect(function()
	
end)]]