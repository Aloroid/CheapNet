--[[

	Handles the creation of a new identifier.

]]

local RunService = game:GetService("RunService")

local efficient_pack_int = require(script.Parent.efficient_pack_int)
local get_identifier_namespace = require(script.Parent.get_identifier_namespace)
local identifier_state = require(script.Parent.identifier_state)

local remote_new: RemoteEvent
local remote_get_all: RemoteFunction

local function get_remote()
	if not remote_new then
		return
	end

	if RunService:IsServer() then
		remote_new = Instance.new("RemoteEvent")
		remote_get_all = Instance.new("RemoteFunction")

		remote_new.Name = "Receive"
		remote_get_all.Name = "GetAll"
		remote_new.Parent = script
		remote_get_all.Parent = script

		remote_get_all.OnServerInvoke = function(player)
			local namespaces = {}

			for key, namespace in identifier_state do
				namespaces[key] = namespace.values
			end
		end
	else
		remote_new = script:WaitForChild("Receive") :: RemoteEvent
		remote_get_all = script:WaitForChild("GetAll") :: RemoteFunction

		task.spawn(function()
			local replicated_namespaces = remote_get_all:InvokeServer()

			for key, namespace_values in replicated_namespaces do
				local namespace = {
					size = #namespace_values,
					values = namespace_values,
					keys = {},
				}

				for id, value in namespace_values do
					namespace.keys[value] = id
				end

				identifier_state[key] = replicated_namespaces
			end
		end)

		remote_new.OnClientEvent:Connect(function(namespace_key: string, id_packed: string, value: any)
			local id = efficient_pack_int.unpack(id_packed)
			local namespace = get_identifier_namespace(namespace_key)
			namespace.size += 1
			namespace.keys[value] = id
			namespace.values[id] = value
		end)
	end
end

local function replicate_value(namespace_key: string, id: number, value: any)
	get_remote()

	remote_new:FireAllClients(namespace_key, efficient_pack_int.pack(id, true), value)
end

local function identifier_create(namespace_key: string, value: any): number?
	local namespace = get_identifier_namespace(namespace_key)
	local key = namespace.keys[value]

	if key then
		return key
	end

	if RunService:IsServer() then
		local id = namespace.size

		namespace.values[id] = value
		namespace.keys[value] = id

		namespace.size += 1

		replicate_value(namespace_key, id, value)

		return id
	end

	return nil
end

return identifier_create
