--[[
	ClientBridge
	
]]

local Packages = script.Parent.Parent

local t = require(Packages.t)
local Signal = require(Packages.Signal)
local sharedState = require(script.Parent.sharedState)

type Signal<T...> = sharedState.Signal<T...>
type Middleware = (...any) -> (...any)

export type ClientBridge<S..., R...> = {
	
	Id: number,
	
	FireServer: (ClientBridge<S..., R...>, S...) -> (),
	
	-- Middleware
	SetInboundMiddleware: (ClientBridge<S..., R...>, {Middleware}) -> (),
	SetOutboundMiddleware: (ClientBridge<S..., R...>, {Middleware}) -> (),
	
	-- RBXScriptSignal Implementation
	OnClientEvent: RBXScriptSignal<R...>,
	
	-- Iterates through all the packets that have been received last frame.
	eachC: (ClientBridge<S..., R...>) -> () -> (R...)
	
}

local ClientBridge = {}
ClientBridge.__index = ClientBridge

function ClientBridge.new<S..., R...>(name: string, filter: ((R...) -> (boolean, string))?): ClientBridge<S..., R...>
	
	local actual_filter = filter or function()
		return true
	end
	
	if sharedState.bridges[name] then
		return sharedState.bridges[name]
	end
	
	local self = setmetatable({
		Id = 0/0,
		
		_name = name,
		_packets = {},
		_filter = actual_filter,
		_inbound_middleware = {},
		_outbound_middleware = {},
		OnClientReceive = Signal.new(),
		
	}, ClientBridge)
	
	sharedState.bridges[name] = self
	
	-- Waits for the Server to create a identifier.
	task.spawn(function()
		local id_object: IntValue = script.Parent.Links:WaitForChild(name)
		self.Id = id_object.Value
		sharedState.identifiers[id_object.Value] = self
	end)
	
	return self
	
end

local is_middleware = t.array(t.callback)
function ClientBridge:SetInboundMiddleware(middleware)
	assert(is_middleware(middleware))
	self._inbound_middleware = middleware
	
end

function ClientBridge:SetOutboundMiddleware(middleware)
	assert(is_middleware(middleware))
	self._outbound_middleware = middleware
	
end

function ClientBridge:Connect(callback: () -> ())
	return self._signal:Connect(callback)
end

function ClientBridge:Once(callback: () -> ())
	return self._signal:Once(callback)
end

function ClientBridge:Wait()
	return self._signal:Wait()
end

function ClientBridge:FireServer(...)
	local transformed = {...}
	
	for _index, middleware: Middleware in self._outbound_middleware do
		transformed = {middleware(unpack(transformed))}
	end
	
	table.insert(sharedState.queue, {id = self.Id, packet = transformed})
	
end

function ClientBridge:eachC()
	
	local i = 0
	
	return function()
		i += 1
		local packet = self._packets[i]
		
		if packet then
			return i, unpack(packet)
		else
			return nil
		end
		
	end
	
end

function ClientBridge:_receive_packet_signal(packet)
	
	local transformed = packet
	
	for _index, middleware: Middleware in self._inbound_middleware do
		transformed = {middleware(unpack(transformed))}	
	end
	
	-- Run the filter
	local success, reasoning = self._filter(unpack(transformed, 2))
	
	if success ~= true then
		warn(reasoning or "Unknown packet")
		return
	end
	
	table.insert(self._packets, transformed)
	
	if self.OnClientReceive._handlerListHead ~= false then
		self.OnClientReceive:Fire(unpack(transformed))
	end
	
end

return ClientBridge