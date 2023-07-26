--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = require(ReplicatedStorage.Remotes)
local CheapNet = require(ReplicatedStorage.Packages.CheapNet)

Remotes.luanoid_move:SetOutboundMiddleware({
	function(...)
		return ...
	end,
})

RunService.Heartbeat:Connect(function()
	for player in Remotes.luanoid_move:eachS() do
		--print("Fired")
	end
end)

local t = { 3, 2 }
local i = 0
while task.wait() do
	--print("Fired")
	i += 1

	for _ = 1, 1 do
		Remotes.luanoid_move:FireAllClients(
			i,
			CheapNet.GetGlobalIdentifier("true"),
			Remotes.luanoid_move:GetLocalIdentifier(t)
		)
		--Remotes.luanoid_spawn:FireAllClients(Vector3.new(), "Player")
	end
end
