local efficient_pack_int = require(script.Parent.efficient_pack_int)
local identifier_create = require(script.Parent.identifier_create)
local network_queue = require(script.Parent.network_queue)
local signal = require(script.Parent.signal)
local stored_bridges = require(script.Parent.stored_bridges)

type Signal<T...> = signal.Signal<T...>

local function unpack_packet(packet: any)
	if type(packet) == "table" then
		return unpack(packet)
	else
		return packet
	end
end

local function pack_packet(...)
	local a = ...

	if select("#", ...) ~= 1 or a == nil or type(a) == "table" then
		return { ... }
	else
		return a
	end
end

local function create_client_bridge<T...>(key: string, behavior)
	local id = efficient_pack_int.unpack(identifier_create("event", key, true), true)
	local signal: Signal<T...>, fire = signal()

	local self = {

		id = id,
		on_client_event = signal,
		behavior = behavior or "unordered" :: "unordered" | "ordered",
	}

	stored_bridges[id + 1] = self

	self.on_server_event = signal

	function self:fire_server(...)
		local packet = pack_packet(...)

		network_queue.client_send_packet(self.behavior, id, packet)
	end

	function self:_receive_packet(packet: any)
		fire(unpack_packet(packet))
	end

	return self
end

return create_client_bridge
