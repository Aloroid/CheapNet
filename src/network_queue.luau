local RunService = game:GetService("RunService")

local filterable = require(script.Parent.filterable)
local packet_decoder = require(script.Parent.packet_decoder)
local packet_encoder = require(script.Parent.packet_encoder)
local stored_bridges = require(script.Parent.stored_bridges)

type Filterable = filterable.Filterable
type PacketType = "ordered" | "unordered"

local ordered_queue = {}
local unordered_queue = {}

local remote

do
	if RunService:IsServer() then
		-- we use script:FindFirstChild in-case someone tries running this in parallel
		remote = (script:FindFirstChild("Packet") :: RemoteEvent) or Instance.new("RemoteEvent")
		remote.Name = "Packet"
		remote.Parent = script
	else
		remote = script:WaitForChild("Packet") :: RemoteEvent
	end
end

local function server_send_packet_to(filter: Filterable, type: PacketType, id: number, packet: any)
	if type == "ordered" then
		table.insert(ordered_queue, { id = id, filter = filter, packet = packet })
	elseif type == "unordered" then
		unordered_queue[id] = unordered_queue[id] or {}
		table.insert(unordered_queue[id], { filter = filter, packet = packet })
	else
		error(`packet type cannot be {type}`)
	end
end

local function client_send_packet(type: PacketType, id: number, packet: any)
	if type == "ordered" then
		packet_encoder.add_packet_to_queue(ordered_queue, type, id, packet)
	elseif type == "unordered" then
		packet_encoder.add_packet_to_queue(unordered_queue, type, id, packet)
	else
		error(`packet type cannot be {type}`)
	end
end

local function server_receive_packet(player: Player, packet: { { any } })
	assert(type(packet) == "table")
	assert(#packet[1] > 0)
	assert(#packet[2] > 0)

	local ordered, unordered = packet_decoder.get_packet(packet)

	for _, packet in ordered do
		local bridge = stored_bridges[packet.id + 1]
		if bridge == nil then continue end
		bridge:_receive_packet(player, packet.packet)
	end

	for id, packets in unordered do
		local bridge = stored_bridges[id + 1]
		if bridge == nil then continue end
		for _, packet in packets do
			bridge:_receive_packet(player, packet)
		end
	end
end

local function client_receive_packet(packet: { { any } })
	local ordered, unordered = packet_decoder.get_packet(packet)

	for _, packet in ordered do
		local bridge = stored_bridges[packet.id + 1]
		if bridge == nil then continue end
		bridge:_receive_packet(packet.packet)
	end

	for id, packets in unordered do
		local bridge = stored_bridges[id + 1]
		if bridge == nil then continue end
		for _, packet in packets do
			bridge:_receive_packet(packet)
		end
	end
end

local function server_empty_queue()
	local players = {}

	for _, packet in ordered_queue do
		for _, player in packet.filter:list() do
			local queue = players[player] or { {}, {} }
			packet_encoder.add_packet_to_queue(queue[1], "ordered", packet.id, packet.packet)
			players[player] = queue
		end
	end

	for id, packets in unordered_queue do
		for _, packet in packets do
			for _, player in packet.filter:list() do
				local queue = players[player] or { {}, {} }
				packet_encoder.add_packet_to_queue(queue[2], "unordered", id, packet.packet)
				players[player] = queue
			end
		end
	end

	for player, packets in players do
		remote:FireClient(player, packet_encoder.get_packet(packets[1], packets[2]))
	end

	table.clear(ordered_queue)
	table.clear(unordered_queue)
end

local function client_empty_queue()
	local packet = packet_encoder.get_packet(ordered_queue, unordered_queue)

	remote:FireServer(packet)

	table.clear(ordered_queue)
	table.clear(unordered_queue)
end

if RunService:IsServer() then
	RunService.Heartbeat:Connect(server_empty_queue)
	remote.OnServerEvent:Connect(server_receive_packet)
elseif RunService:IsClient() then
	RunService.Heartbeat:Connect(client_empty_queue)
	remote.OnClientEvent:Connect(client_receive_packet)
end

return {

	server_receive_packet = server_receive_packet,
	server_send_packet_to = server_send_packet_to,
	server_empty_queue = server_empty_queue,

	client_receive_packet = client_receive_packet,
	client_send_packet = client_send_packet,
	client_empty_queue = client_empty_queue,
}
