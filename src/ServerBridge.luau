--[[
	ServerBridge
	
]]

local Players = game:GetService("Players")

local Packages = script.Parent.Parent

local t = require(Packages.t)
local Signal = require(Packages.Signal)
local PacketFilterable = require(script.Parent.PacketFilterable)
local Identifier = require(script.Parent.Identifier)
local sharedState = require(script.Parent.SharedState)
local CallIdentifier = require(script.Parent.CallIdentifier)

type Signal<T...> = sharedState.Signal<T...>
type Middleware = (...any) -> ...any
type PacketFilterable = PacketFilterable.PacketFilterable

export type ServerBridge<S..., R...> = {

	Id: number,

	FireAllClients: (ServerBridge<S..., R...>, S...) -> PacketFilterable,
	FireToClients: (ServerBridge<S..., R...>, S...) -> PacketFilterable,

	-- Middleware
	SetInboundMiddleware: (ServerBridge<S..., R...>, { Middleware }) -> (),
	SetOutboundMiddleware: (ServerBridge<S..., R...>, { Middleware }) -> (),

	-- Identifier
	FromLocalIdentifier: (ServerBridge<S..., R...>, identifier: string) -> string,
	GetLocalIdentifier: (ServerBridge<S..., R...>, value: string) -> string,

	-- RBXScriptSignal Implementation
	OnServerEvent: Signal<R...>,

	-- Iterates through all the packets that have been received last frame.
	eachS: (ServerBridge<S..., R...>) -> () -> (Player, R...),
}

local ServerBridge = {}
local cached_middleware_threads = {}
local Id = 1
ServerBridge.__index = ServerBridge

local function nonFatalError(...)
	task.spawn(error, table.concat({ ... }, " "))
end

function ServerBridge.new<S..., R...>(
	name: string,
	before: (R...) -> (boolean, string?),
	after: (R...) -> (boolean, string?)
): ServerBridge<S..., R...>
	if sharedState.bridges[name] then
		return sharedState.bridges[name]
	end

	local before_filter = before or function()
		return true
	end
	local after_filter = after or before or function()
		return true
	end

	local self = setmetatable({
		Id = Id,

		_name = name,
		_packets = { [""] = {} },
		_inbound_middleware = {},
		_outbound_middleware = {},
		_before_filter = before_filter,
		_after_filter = after_filter,

		OnServerReceive = Signal.new(),
	}, ServerBridge)

	sharedState.bridges[name] = self

	-- Creates a Link that the client can use in order to find the proper packet.
	local int_value = Instance.new("IntValue")

	int_value.Name = name
	int_value.Value = Id
	int_value.Parent = script.Parent.Links

	sharedState.identifiers[Id] = self
	Id += 1

	return self
end

function ServerBridge:FireToClients(...)
	local packet_filterable = PacketFilterable.new()

	local transformed = { ... }

	-- perform a initial check to make sure the packet we're sending is OK
	do
		local success, reasoning = self._after_filter(unpack(transformed))

		if success ~= true then
			warn(`Invalid packet (wrong input) on "{self._name}":\n {reasoning}`)
			return packet_filterable
		end
	end

	-- processes the packet through middleware
	for index, middleware: Middleware in self._outbound_middleware do
		local thread = cached_middleware_threads[middleware]

		-- create a new thread to disallow yielding and such.
		if thread == nil then
			thread = coroutine.create(function(packet)
				local packed = packet
				while true do
					packed = coroutine.yield({ middleware(unpack(packed)) })
				end
			end)

			cached_middleware_threads[middleware] = thread
		end

		local success, result = coroutine.resume(thread, transformed)

		if success == true then
			transformed = result
		else
			nonFatalError(`Middleware #{index} has failed: {result} -> {debug.traceback(thread)}`)
			return packet_filterable
		end
	end

	-- perform another check to make sure the packet we're sending after being processed by middleware is also OK
	do
		local success, reasoning = self._before_filter(unpack(transformed))

		if success ~= true then
			warn(`Invalid packet (middleware returned invalid data) on "{self._name}":\n {reasoning}`)
			return packet_filterable
		end
	end

	table.insert(sharedState.queue, { id = self.Id, players = packet_filterable, packet = transformed })

	return packet_filterable
end

function ServerBridge:FireAllClients(...)
	return self:FireToClients(...):include(Players:GetPlayers())
end

local is_middleware = t.array(t.callback)
function ServerBridge:SetInboundMiddleware(middleware)
	assert(is_middleware(middleware))
	self._inbound_middleware = middleware
end

function ServerBridge:SetOutboundMiddleware(middleware)
	assert(is_middleware(middleware))
	self._outbound_middleware = middleware
end

function ServerBridge:FromLocalIdentifier(identifier: string)
	return Identifier.fromLocalIdentifier(self._name, identifier)
end

function ServerBridge:GetLocalIdentifier(value: any)
	return Identifier.getLocalIdentifier(self._name, value)
end

function ServerBridge:eachS(discriminator: number | string?)
	local i = 0

	local key = CallIdentifier(self.Id, discriminator)
	local packets = self._packets[key] or self._packets[""]
	self._packets[key] = self._packets[key] or {}

	return function()
		i += 1
		local packet = packets[i]

		if packet then
			return i, unpack(packet)
		else
			table.clear(packets)
			return nil
		end
	end
end

function ServerBridge:_receive_packet_signal(packet)
	local transformed = packet

	-- perform a initial check to make sure the packet that the client sent is OK
	do
		local success, reasoning = self._before_filter(unpack(transformed, 2))

		if success ~= true then
			warn(`Invalid packet on "{self._name}" from {packet[1]}:\n {reasoning}`)
			return
		end
	end

	-- processes the packet through middleware
	for index, middleware: Middleware in self._outbound_middleware do
		local thread = cached_middleware_threads[middleware]

		-- create a new thread to disallow yielding and such.
		if thread == nil then
			thread = coroutine.create(function(packet)
				local packed = packet
				while true do
					packed = { coroutine.yield({ middleware(unpack(packed)) }) }
				end
			end)

			cached_middleware_threads[middleware] = thread
		end

		local success, result = coroutine.resume(thread, transformed)

		if success == true then
			transformed = result
		else
			nonFatalError(`Middleware #{index} has failed: {result} -> {debug.traceback(thread)}`)
			return
		end
	end

	-- perform another check to make sure the packet we're sending after being processed by middleware is also OK
	do
		local success, reasoning = self._after_filter(unpack(transformed, 2))

		if success ~= true then
			warn(`Invalid packet (middleware returned invalid data) on "{self._name}" from {packet[1]}:\n {reasoning}`)
			return
		end
	end

	for identifier, packets in self._packets do
		table.insert(packets, transformed)
	end

	if self.OnServerReceive._handlerListHead ~= false then
		self.OnServerReceive:Fire(unpack(transformed))
	end
end

return ServerBridge
