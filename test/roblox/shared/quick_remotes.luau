--[[

	A basic remote event wrapper to handle basic networking tasks.
	This is used for testing in CheapNet.

]]

local RunService = game:GetService("RunService")

local function get_remote_event(name: string)
	if RunService:IsServer() then
		return script:FindFirstChild(name) :: RemoteEvent
			or (function()
				local remote = Instance.new("RemoteEvent")
				remote.Name = name
				remote.Parent = script
				return remote
			end)()
	else
		return script:WaitForChild(name) :: RemoteEvent
	end
end

local function get_remote_function(name: string)
	if RunService:IsServer() then
		return script:FindFirstChild(name) :: RemoteFunction
			or (function()
				local remote = Instance.new("RemoteFunction")
				remote.Name = name
				remote.Parent = script
				return remote
			end)()
	else
		return script:WaitForChild(name) :: RemoteFunction
	end
end

return {
	get_remote_event = get_remote_event,
	get_remote_function = get_remote_function,
}
