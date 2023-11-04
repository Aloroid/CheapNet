--[[

	CheapNet is a networking library designed quickly.

]]

local RunService = game:GetService("RunService")

local client_bridge = require(script.client_event_bridge)
local client_remote_function = require(script.client_remote_function)
local efficient_pack_int = require(script.efficient_pack_int)
local filterable = require(script.filterable)
local get_identifier_namespace = require(script.get_identifier_namespace)
local identifier_create = require(script.identifier_create)
local identifier_get = require(script.identifier_get)
local leaky_bucket = require(script.leaky_bucket)
local packet_decoder = require(script.packet_decoder)
local packet_encoder = require(script.packet_encoder)
local server_bridge = require(script.server_event_bridge)
local server_remote_function = require(script.server_remote_function)
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
export type Function<T..., U...> = {

	id: number,

	on_invoke: (Player, T...) -> U...,
	invoke: (Function<T..., U...>, T...) -> U...,
}

return {

	create_identifier = function(value: unknown, namespace: any?)
		return identifier_create(namespace or "_global", value)
	end,

	get_value = function(key: string, namespace: any?)
		return identifier_get(namespace or "_global", key)
	end,

	event = (
			if RunService:IsServer() then server_bridge :: any else client_bridge :: any
		) :: <T...>(key: any, behavior: behavior?, typecheck: ((T...) -> boolean)?) -> Event<T...>,
	r_function = (
			if RunService:IsServer() then server_remote_function :: any else client_remote_function :: any
		) :: <T..., U...>(key: any, typecheck: ((T...) -> boolean)?) -> Function<T..., U...>,

	pack = efficient_pack_int.pack,
	unpack = efficient_pack_int.unpack,

	leaky_bucket = leaky_bucket.new,

	timestamps = timestamps.timestamps,
	get_timestamp = timestamps.get_timestamp,

	player_warning = timestamps.invalid_timestamp,

	_private = {
		identifier_create = identifier_create,
		identifier_get = identifier_get,
		get_identifier_namespace = get_identifier_namespace,

		packet_encoder = packet_encoder,
		packet_decoder = packet_decoder,

		filterable = filterable,
	},
}
