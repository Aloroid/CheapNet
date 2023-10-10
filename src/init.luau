local RunService = game:GetService("RunService")
--[[

	CheapNet is a networking library designed quickly.

]]

local client_bridge = require(script.client_event_bridge)
local efficient_pack_int = require(script.efficient_pack_int)
local filterable = require(script.filterable)
local get_identifier_namespace = require(script.get_identifier_namespace)
local identifier_create = require(script.identifier_create)
local identifier_get = require(script.identifier_get)
local packet_decoder = require(script.packet_decoder)
local packet_encoder = require(script.packet_encoder)
local server_bridge = require(script.server_event_bridge)
local signal = require(script.signal)

type Signal<T...> = signal.Signal<T...>
export type Filterable = filterable.Filterable
export type Event<T...> = {

	id: number,
	behavior: "ordered" | "unordered",

	on_client_event: Signal<T...>,
	on_server_event: Signal<(Player, T...)>,

	fire_server: (Event<T...>, T...) -> (),
	fire_clients: (Event<T...>, T...) -> Filterable,
}

return {

	create_global_identifier = function(value: unknown)
		return identifier_create("global", value)
	end,

	get_global_identifier = function(key: string)
		return identifier_get("global", key)
	end,

	event = (
			if RunService:IsServer() then server_bridge :: any else client_bridge :: any
		) :: <T...>(key: any, behavior: "ordered" | "unordered"?) -> Event<T...>,

	pack = efficient_pack_int.pack,
	unpack = efficient_pack_int.unpack,

	_private = {
		identifier_create = identifier_create,
		identifier_get = identifier_get,
		get_identifier_namespace = get_identifier_namespace,

		packet_encoder = packet_encoder,
		packet_decoder = packet_decoder,

		filterable = filterable,
	},
}
