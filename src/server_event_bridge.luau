local efficient_pack_int = require(script.Parent.efficient_pack_int)
local filterable = require(script.Parent.filterable)
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

local function create_server_bridge<T...>(key, behavior, runtime: ((...any) -> (true, T...) | false)?)
	local id = efficient_pack_int.unpack(identifier_create("event", key), true)
	local signal: Signal<(Player, T...)>, fire = signal()
	local typeguard = runtime or function()
		return true
	end :: never

	local self = {

		id = id,
		on_server_event = signal,
		behavior = behavior or "unordered" :: "unordered" | "ordered",
	}

	stored_bridges[id + 1] = self

	self.on_server_event = signal

	function self:fire_clients(...)
		local filter = filterable()
		local packet = pack_packet(...)

		network_queue.server_send_packet_to(filter, self.behavior, id, packet)

		return filter
	end

	function self:_receive_packet(player: Player, packet: any)
		local s = pcall(typeguard, unpack(packet))
		if not s then return end

		fire(player, unpack_packet(packet))
	end

	return self
end

return create_server_bridge
