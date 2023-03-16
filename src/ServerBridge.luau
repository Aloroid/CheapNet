--[[
	ServerBridge
	
]]

local Players = game:GetService("Players")

local Packages = script.Parent.Parent

local t = require(Packages.t)
local Signal = require(Packages.Signal)
local PacketFilterable = require(script.Parent.PacketFilterable)
local sharedState = require(script.Parent.sharedState)
local Identifier = require(script.Parent.Identifier)

type Signal<T...> = sharedState.Signal<T...>
type Middleware = (...any) -> (...any)
type PacketFilterable = PacketFilterable.PacketFilterable

export type ServerBridge<S..., R...> = {
	
	Id: number,
	
	FireAllClients: (ServerBridge<S..., R...>, S...) -> PacketFilterable,
	FireToClients: (ServerBridge<S..., R...>, S...) -> PacketFilterable,
	
	-- Middleware
	SetInboundMiddleware: (ServerBridge<S..., R...>, {Middleware}) -> (),
	SetOutboundMiddleware: (ServerBridge<S..., R...>, {Middleware}) -> (),
	
	-- Identifier
	FromLocalIdentifier: (ServerBridge<S..., R...>, identifier: string) -> string,
	GetLocalIdentifier: (ServerBridge<S..., R...>, value: string) -> string,
	
	-- RBXScriptSignal Implementation
	OnServerEvent: Signal<R...>,
	
	-- Iterates through all the packets that have been received last frame.
	eachS: (ServerBridge<S..., R...>) -> () -> (Player, R...)
	
}

local ServerBridge = {}
local Id = 1
ServerBridge.__index = ServerBridge

function ServerBridge.new<S..., R...>(name: string, filter: ((R...) -> (boolean, string?))?): ServerBridge<S..., R...>
	
	local actual_filter = filter or function()
		return true
	end
	
	if sharedState.bridges[name] then
		return sharedState.bridges[name]
	end
	
	local self = setmetatable({
		Id = Id,
		
		_name = name,
		_packets = {},
		_inbound_middleware = {},
		_outbound_middleware = {},
		_filter = actual_filter,
		
		OnServerReceive = Signal.new()
		
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
	
	local transformed = {...}
	
	for _index, middleware: Middleware in self._outbound_middleware do
		transformed = {middleware(unpack(transformed))}
	end
	
	table.insert(sharedState.queue, {id = self.Id, players = packet_filterable, packet = transformed})
	
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

function ServerBridge:eachS()
	
	local i = 0
	
	return function()
		i += 1
		local packet = self._packets[i]
		
		if packet then
			return i,unpack(packet)
		else
			return nil
		end
		
	end
	
end

function ServerBridge:_receive_packet_signal(packet)
	
	local transformed = packet
	
	for _index, middleware: Middleware in self._inbound_middleware do
		transformed = {middleware(unpack(transformed))}	
	end
	
	-- Run the filter
	local success, reasoning = self._filter(unpack(transformed, 2))
	
	if success ~= true then
		warn(`Invalid packet on {self._name} because "{reasoning}" from {packet[1]}`)
		return
	end
	
	table.insert(self._packets, transformed)
	
	if self.OnServerReceive._handlerListHead ~= false then
		self.OnServerReceive:Fire(unpack(transformed))
	end
	
end

return ServerBridge