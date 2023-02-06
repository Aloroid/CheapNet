--!optimize 2
--[[
	PacketEncoder
	
]]

local sharedState = require(script.Parent.sharedState)
local PacketFilterable = require(script.Parent.PacketFilterable)
local t = require(script.Parent.Parent.t)

local Serializer = {}

local Links = script.Parent.Links
local Remote = script.Parent.Remote

type Packet = {
	id: number,
	players: PacketFilterable.PacketFilterable,
	packet: {any}
}

local function get_bridge_id(id: number)
	
	local total_links = #Links:GetChildren()
	local total_characters = if total_links > 255 then 2 else 1
	
	return string.pack("I"..total_characters, id)
	
end

local cache = {}
local function get_bridge_from_id(id: string)
	
	if cache[id] then return cache[id] end
	
	local total_links = #Links:GetChildren()
	local total_characters = if total_links > 255 then 2 else 1
	
	local unpacked = string.unpack("I"..total_characters, id)
	cache[id] = sharedState.identifiers[unpacked]
	
	return sharedState.identifiers[unpacked]
	
end

function Serializer.onSendServer()
	
	debug.profilebegin("CheapNet Serialize")
	-- On the server, we'll have to get all the packets that we are supposed to send.
	-- After we have gotten all the packets, we have to figure which players we need
	-- to send the given packets to.
	-- We'll then have to do some basic packing to get it to work.
	local queue = sharedState.queue
	local filtered_data = {}
	
	-- We'll have to go through all the packets and figure out which players need to
	-- receive which packets.
	for _, packet_data: Packet in queue do
		local filterable = packet_data.players
		local id = packet_data.id
		
		for player in filterable.included do
			-- We'll create a new table for the player if there isn't one yet.
			filtered_data[player] = filtered_data[player] or {}
			local player_filter = filtered_data[player]
			
			-- We've determined this player has to receive packets, so let's see if there is a key
			-- for the packet we're trying to send.
			player_filter[id] = player_filter[id] or {get_bridge_id(id)}
			local local_packet_queue = player_filter[id]
			
			-- We will insert the packet in the queue.
			table.insert(local_packet_queue, packet_data.packet)
			
		end
	end
	
	table.clear(sharedState.queue)
	
	-- We have filtered all the packets and performed some basic optimizations.
	-- We'll now convert the player's filtered data into a array and send that.
	for player, player_filter in filtered_data do
		local optimized = {}
		
		-- Insert the data in the id-less array.
		for _, local_packet_queue in player_filter do
			table.insert(optimized, local_packet_queue)	
		end
		
		-- Send!
		print("Sent it to the player")
		Remote:FireClient(player, optimized)
	end
	
	debug.profileend()
	
end

function Serializer.onSendClient()
	
	debug.profilebegin("CheapNet Serialize")
	
	-- On the client, we'll have to get all the packets that we are supposed to send.
	-- We'll then have to do some basic packing to get it to work.
	local queue = sharedState.queue
	local filtered_data = {}
	
	-- We'll have to go through all the packets and do some basic conversion.
	for _, packet_data: Packet in queue do
		local id = packet_data.id
		
		-- Let's see if there is a key for the packet we're trying to send.
		filtered_data[id] = filtered_data[id] or {get_bridge_id(id)}
		local local_packet_queue = filtered_data[id]
		
		-- We will insert the packet in the queue.
		table.insert(local_packet_queue, packet_data.packet)
			
	end
	
	table.clear(sharedState.queue)
	
	-- We have filtered all the packets and performed some basic optimizations.
	-- We'll now convert the filtered data into a array and send that.
	local optimized = {}
	
	-- Insert the data in the id-less array.
	for _, local_packet_queue in filtered_data do
		table.insert(optimized, local_packet_queue)	
	end
	
	-- Send!
	Remote:FireServer(optimized)
	
	debug.profileend()
	
end

local packet_check = t.array(t.array(t.any))
function Serializer.onReceiveServer(player: Player, optimized_packets)
	debug.profilebegin("CheapNet Decode Server")
	assert(packet_check(optimized_packets))
	
	for _, local_packet_queue in optimized_packets do
		
		local bridge = get_bridge_from_id(local_packet_queue[1])
		
		for i, packet in local_packet_queue do
			if i == 1 then continue end -- That's the id
			
			table.insert(packet, 1, player)
			bridge:_receive_packet_signal(packet)
			
		end
	end
	
	debug.profileend()
end

function Serializer.onReceiveClient(optimized_packets)
	print("Deserializing")
	debug.profilebegin("CheapNet Decode Client")
	
	for _, local_packet_queue in optimized_packets do
		
		local bridge = get_bridge_from_id(local_packet_queue[1])
		
		
		for i, packet in local_packet_queue do
			if i == 1 then continue end -- That's the id
			
			bridge:_receive_packet_signal(packet)
			
		end
	end
	
	debug.profileend()
end



return Serializer