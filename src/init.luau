--[[

	CheapNet is a networking library designed quickly.

]]

local get_identifier_namespace = require(script.get_identifier_namespace)
local identifier_create = require(script.identifier_create)
local identifier_get = require(script.identifier_get)
local packet_decoder = require(script.packet_decoder)
local packet_encoder = require(script.packet_encoder)

return {

	create_global_identifier = function(value: unknown)
		return identifier_create("global", value)
	end,

	get_global_identifier = function(key: string)
		return identifier_get("global", key)
	end,

	_private = {
		identifier_create = identifier_create,
		identifier_get = identifier_get,
		get_identifier_namespace = get_identifier_namespace,

		packet_encoder = packet_encoder,
		packet_decoder = packet_decoder,
	},
}
