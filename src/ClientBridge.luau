--[[
	ClientBridge
	
]]

local Packages = script.Parent.Parent

local t = require(Packages.t)
local Signal = require(Packages.Signal)
local sharedState = require(script.Parent.sharedState)
local Identifier = require(script.Parent.Identifier)

type Signal<T...> = sharedState.Signal<T...>
type Middleware = (...any) -> ...any

export type ClientBridge<S..., R...> = {

	Id: number,

	FireServer: (ClientBridge<S..., R...>, S...) -> (),

	-- Middleware
	SetInboundMiddleware: (ClientBridge<S..., R...>, { Middleware }) -> (),
	SetOutboundMiddleware: (ClientBridge<S..., R...>, { Middleware }) -> (),

	-- Identifier
	FromLocalIdentifier: (ClientBridge<S..., R...>, identifier: string) -> string,
	GetLocalIdentifier: (ClientBridge<S..., R...>, value: string) -> string,

	-- RBXScriptSignal Implementation
	OnClientEvent: RBXScriptSignal<R...>,

	-- Iterates through all the packets that have been received last frame.
	eachC: (ClientBridge<S..., R...>) -> () -> R...,
}

local ClientBridge = {}
local cached_middleware_threads = {}
ClientBridge.__index = ClientBridge

local function nonFatalError(...)
	task.spawn(error, table.concat({ ... }, " "))
end

function ClientBridge.new<S..., R...>(
	name: string,
	before: ((R...) -> (boolean, string))?,
	after: ((R...) -> (boolean, string))?
): ClientBridge<S..., R...>
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
		Id = 0 / 0,

		_name = name,
		_processed = false,
		_packets = {},
		_inbound_middleware = {},
		_outbound_middleware = {},

		_before_filter = before_filter,
		_after_filter = after_filter,

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
	local transformed = { ... }

	-- perform a initial check to make sure the packet we're sending is OK
	do
		local success, reasoning = self._after_filter(unpack(transformed))

		if success ~= true then
			warn(`Invalid packet (wrong input) on "{self._name}":\n {reasoning}`)
			return
		end
	end

	-- processes the packet through middleware
	for index, middleware: Middleware in self._outbound_middleware do
		local thread = cached_middleware_threads[middleware]

		-- create a new thread to disallow yielding and such.
		if thread == nil then
			thread = coroutine.create(function(...)
				local packed = { ... }
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
		local success, reasoning = self._before_filter(unpack(transformed))

		if success ~= true then
			warn(`Invalid packet (middleware returned invalid data) on "{self._name}":\n {reasoning}`)
			return
		end
	end

	table.insert(sharedState.queue, { id = self.Id, packet = transformed })
end

function ClientBridge:eachC()
	local i = 0
	self._processed = true

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

function ClientBridge:FromLocalIdentifier(identifier: string)
	return Identifier.fromLocalIdentifier(self._name, identifier)
end

function ClientBridge:GetLocalIdentifier(value: any)
	return Identifier.getLocalIdentifier(self._name, value)
end

function ClientBridge:_receive_packet_signal(packet)
	local transformed = packet

	local initial_success, initial_reasoning = self._before_filter(unpack(packet))

	if initial_success ~= true then
		warn(`Invalid packet on {self._name} because "{initial_reasoning}"`)
		return
	end

	-- processes the packet through middleware
	for index, middleware: Middleware in self._inbound_middleware do
		local thread = cached_middleware_threads[middleware]

		-- create a new thread to disallow yielding and such.
		if thread == nil then
			thread = coroutine.create(function(...)
				local packed = { ... }
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

	-- Run the filter
	local success, reasoning = self._after_filter(unpack(transformed))

	if success ~= true then
		warn(`Invalid packet (developer error) on {self._name} because "{reasoning}"`)
		return
	end

	table.insert(self._packets, transformed)

	if self.OnClientReceive._handlerListHead ~= false then
		self.OnClientReceive:Fire(unpack(transformed))
	end
end

return ClientBridge
