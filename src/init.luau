--!nocheck
--[[
	CheapNet is a networking library designed for running networking code at a
	low performance cost while having the capabilities to be incredibly safe,
	encouraging the user to leverage typechecking and more.
]]

local RunService = game:GetService("RunService")

local Serializer = require(script.Serializer)
local PacketFilterable = require(script.PacketFilterable)
local sharedState = require(script.sharedState)
local LeakyBucket = require(script.LeakyBucket)
local Identifier = require(script.Identifier)

export type PacketFilterable = PacketFilterable.PacketFilterable
type Middleware<T... = ...any> = (T...) -> ...any
type Connection = { Disconnect: Connection }
type Signal<T...> = sharedState.Signal<T...>
type RuntimeTypecheck<T...> = (T...) -> (boolean, string?)
export type UnifiedBridge<T..., U...> = {

	Id: number,

	FireToClients: (UnifiedBridge<T..., U...>, U...) -> PacketFilterable,
	FireAllClients: (UnifiedBridge<T..., U...>, U...) -> PacketFilterable,
	FireServer: (UnifiedBridge<T..., U...>, U...) -> (),

	SetInboundMiddleware: (UnifiedBridge<T..., U...>, { Middleware }) -> (),
	SetOutboundMiddleware: (UnifiedBridge<T..., U...>, { Middleware }) -> (),

	-- Identifier
	FromLocalIdentifier: (UnifiedBridge<T..., U...>, identifier: string) -> unknown,
	GetLocalIdentifier: (UnifiedBridge<T..., U...>, value: unknown) -> string,

	-- Signal
	OnServerReceive: Signal<(Player, U...)>,
	OnClientReceive: Signal<T...>,

	eachC: (UnifiedBridge<T..., U...>) -> () -> (number, U...),
	eachS: (UnifiedBridge<T..., U...>) -> () -> (number, Player, U...),
}

local CheapNet = {}

CheapNet.LeakyBucket = LeakyBucket

-- the before_middleware test exists so you can confirm the packet the client
-- has sent is valid. the after_middleware test exists so that you don't mess
-- up. ndee
function CheapNet.new(bridge, before_middleware_test, after_middleware_test)
	if RunService:IsServer() then
		local ServerBridge = require(script.ServerBridge)
		return ServerBridge.new(bridge, before_middleware_test, after_middleware_test or before_middleware_test)
	else
		local ClientBridge = require(script.ClientBridge)
		return ClientBridge.new(bridge, before_middleware_test, after_middleware_test or before_middleware_test)
	end
end

function CheapNet.FromGlobalIdentifier(identifier)
	return Identifier.fromLocalIdentifier(script, identifier)
end

function CheapNet.GetGlobalIdentifier(value)
	return Identifier.getLocalIdentifier(script, value)
end

local processingPacket = {}

RunService.Stepped:Connect(function()
	for _, bridge in sharedState.bridges do
		bridge._packets = {}
	end

	-- Clear up all the existing packets
	if RunService:IsServer() then
		debug.profilebegin("CheapNet Server")
		Serializer.onSendServer()
		for player, packet in processingPacket do
			Serializer.onReceiveServer(player, packet)
		end
		processingPacket = {}
	else
		debug.profilebegin("CheapNet Client")
		Serializer.onSendClient()
		Serializer.onReceiveClient(processingPacket)
	end

	processingPacket = {}

	debug.profileend()
end)

if RunService:IsClient() then
	script.Remote.OnClientEvent:Connect(function(packet)
		for _, queue in packet do
			table.insert(processingPacket, queue)
		end
	end)
else
	script.Remote.OnServerEvent:Connect(function(player, packet)
		processingPacket[player] = processingPacket[player] or {}
		for _, queue in packet do
			table.insert(processingPacket[player], queue)
		end
	end)
end

return CheapNet :: {

	new: (<T..., U...>(bridge: string) -> UnifiedBridge<T..., U...>)
		& (<T...>(bridge: string, before: RuntimeTypecheck<T...>) -> UnifiedBridge<T..., T...>)
		& (<T..., U...>(
			bridge: string,
			before: RuntimeTypecheck<T...>,
			after: RuntimeTypecheck<U...>
		) -> UnifiedBridge<T..., U...>),

	FromGlobalIdentifier: (identifier: string) -> unknown,
	GetGlobalIdentifier: (value: unknown) -> string,

	LeakyBucket: typeof(LeakyBucket),
}
