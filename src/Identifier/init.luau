--[[
	This module handles the creation of new identifiers and converting identifiers
	into packed formats.
	
	Identifiers are 2 bytes.
	
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local efficientPackInt = require(script.Parent.EfficientPackInt)

local Identifier = {}

-- This metatable will automatically create a new table if we try to index a
-- value that is nil. This stops us from checking constantly if there is anything
-- inside it.
local AUTOCREATETABLE = {
	__index = function(t, k)
		t[k] = {}
		return t[k]
	end,
}
local identifiersToValues = setmetatable({}, AUTOCREATETABLE)
local valuesToIdentifiers = setmetatable({}, AUTOCREATETABLE)
local totalIdentifiers = {}
local sendToClients = {}
local initialized = {}

function Identifier.fromLocalIdentifier(groupName, identifier)
	return identifiersToValues[groupName][identifier]
end

function Identifier.getLocalIdentifier(group, value)
	if RunService:IsServer() then
		local identifier = valuesToIdentifiers[group][value]
		if identifier == nil then
			local rawId = (totalIdentifiers[group] or 0) + 1
			local id = efficientPackInt.pack(rawId, true)

			totalIdentifiers[group] = rawId
			identifiersToValues[group][id] = value
			valuesToIdentifiers[group][value] = id

			table.insert(sendToClients, { group, id, value })
			for _, player in initialized do
				script.Add:FireClient(player, group, id, value)
			end

			return id
		end

		return identifier
	else
		return valuesToIdentifiers[group][value]
	end
end

if RunService:IsServer() then
	script.Get.OnServerInvoke = function(player: Player)
		table.insert(initialized, player)
		return sendToClients
	end

	Players.PlayerRemoving:Connect(function(player)
		local index = table.find(initialized, player)
		if index then
			table.remove(initialized, index)
		end
	end)
else
	-- Client requests the server
	local data = script.Get:InvokeServer()

	for _, add in data do
		local group, id, value = add[1], add[2], add[3]
		identifiersToValues[group][id] = value
		valuesToIdentifiers[group][value] = id
	end

	script.Add.OnClientEvent:Connect(function(group: string, id: string, value: any)
		identifiersToValues[group][id] = value
		valuesToIdentifiers[group][value] = id
	end)
end

return Identifier
