
local Packages = script.Parent.Parent

local t = require(Packages.t)

export type PacketFilterable = {
	included: {[Player]: boolean},
	
	include: (PacketFilterable, {Player} | Player) -> PacketFilterable,
	exclude: (PacketFilterable, {Player} | Player) -> PacketFilterable
	
}

local PacketFilterable = {}
PacketFilterable.__index = PacketFilterable

function PacketFilterable.new(list: {Player}?)
	local self = setmetatable({
		included = {}
	}, PacketFilterable)
	
	if list then
		self:include(list)
	end
	
	return self :: PacketFilterable
end


local is_player = t.union(t.array(t.instance("Player")), t.instance("Player"))
function PacketFilterable:include(players: {Player} | Player)
	assert(is_player(players))
	
	if typeof(players) == "Instance" then
		players = {players}
	end
	
	local actual_players = players :: {Player}
	for _, player in actual_players do
		self.included[player] = true
	end
	
	return self
	
end

function PacketFilterable:exclude(players: {Player} | Player)
	assert(is_player(players))
	
	if typeof(players) == "Instance" then
		players = {players}
	end
	
	local actual_players = players :: {Player}
	for _, player in actual_players do
		self.included[player] = nil
	end
	
	return self
	
end

return PacketFilterable