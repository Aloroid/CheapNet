--[[

	CheapNet is a networking library designed quickly.

]]

local RunService = game:GetService("RunService")

local client_bridge = require(script.client_event_bridge)
local efficient_pack_int = require(script.efficient_pack_int)
local filterable = require(script.filterable)
local get_identifier_namespace = require(script.get_identifier_namespace)
local identifier_create = require(script.identifier_create)
local identifier_get = require(script.identifier_get)
local leaky_bucket = require(script.leaky_bucket)
local packet_decoder = require(script.packet_decoder)
local packet_encoder = require(script.packet_encoder)
local server_bridge = require(script.server_event_bridge)
local signal = require(script.signal)
local timestamps = require(script.timestamps)

type Signal<T...> = signal.Signal<T...>
type behavior = "ordered" | "unordered" | "unreliable" | "unreliable_drop_old_packets"
export type Filterable = filterable.Filterable
export type Event<T...> = {

	id: number,
	behavior: behavior,

	on_client_event: Signal<T...>,
	on_server_event: Signal<(Player, T...)>,

	fire_server: (Event<T...>, T...) -> (),
	fire_clients: (Event<T...>, T...) -> Filterable,
}

return {

	create_global_identifier = function(value: unknown, namespace: any?)
		return identifier_create(namespace or "_global", value)
	end,

	get_global_identifier = function(key: string, namespace: any?)
		return identifier_get(namespace or "_global", key)
	end,

	event = (
			if RunService:IsServer() then server_bridge :: any else client_bridge :: any
		) :: <T...>(key: any, behavior: behavior?, typecheck: ((...any) -> T...)?) -> Event<T...>,

	pack = efficient_pack_int.pack,
	unpack = efficient_pack_int.unpack,

	leaky_bucket = leaky_bucket,

	timestamp = timestamps,

	_private = {
		identifier_create = identifier_create,
		identifier_get = identifier_get,
		get_identifier_namespace = get_identifier_namespace,

		packet_encoder = packet_encoder,
		packet_decoder = packet_decoder,

		filterable = filterable,
	},
}
