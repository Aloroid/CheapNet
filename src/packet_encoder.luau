--[[

	the packet encoder encodes packets into a special format.

]]

local is_16bit = false
local Vector3int16 = Vector3int16

if Vector3int16 == nil then
	Vector3int16 = {
		new = function(x: number?, y: number?, z: number?)
			return { X = x, Y = y, Z = z } :: any
		end,
	}
end

local function convert(...): { any } | any
	local a = ...
	if select("#", ...) > 1 or type(a) == "table" or a == nil then
		return { ... }
	else
		return a
	end
end

local function add_packet_to_queue(queue: { any }, type: "ordered" | "unordered", id: number, ...)
	is_16bit = is_16bit or id > 255
	local packet = convert(...)

	if type == "unordered" then
		queue[id] = queue[id] or {}
		table.insert(queue[id], packet)
	else
		table.insert(queue, { id = id, packet = packet })
	end
end

-- serializes the ordered packets using either 1 byte or 2 byte identifiers.
local function serialize_ordered(ordered_queue: { { id: number, packet: any } }, is_16bit: boolean)
	local serialized: { any } = {}

	if not is_16bit then
		local x, y, z = 0, 0, 0
		local n = 0
		local packets = table.create(6)

		for i, packet_data in ordered_queue do
			local id = packet_data.id
			local packet = packet_data.packet

			table.insert(packets, packet)

			n += 1
			if n == 1 then
				x = id
			elseif n == 2 then
				x += bit32.lshift(id, 8)
			elseif n == 3 then
				y = id
			elseif n == 4 then
				y += bit32.lshift(id, 8)
			elseif n == 5 then
				z = id
			elseif n == 6 then
				z += bit32.lshift(id, 8)
				n = 0

				table.insert(serialized, Vector3int16.new(x, y, z))
				table.move(packets, 1, 6, #serialized + 1, serialized)
				table.clear(packets)
				x, y, z = 0, 0, 0
			end
		end

		if n > 0 then
			table.insert(serialized, Vector3int16.new(x, y, z))
			table.move(packets, 1, 6, #serialized + 1, serialized)
		end
	else
		local x, y, z = 0, 0, 0
		local n = 0
		local packets = table.create(3)

		for i, packet_data in ordered_queue do
			local id = packet_data.id
			local packet = packet_data.packet

			table.insert(packets, packet)

			n += 1
			if n == 1 then
				x = id
			elseif n == 2 then
				y = id
			elseif n == 3 then
				z = id
				n = 0

				table.insert(serialized, Vector3int16.new(x, y, z))
				table.move(packets, 1, 3, #serialized + 1, serialized)
				table.clear(packets)
				x, y, z = 0, 0, 0
			end
		end

		if n > 0 then
			table.insert(serialized, Vector3int16.new(x, y, z))
			table.move(packets, 1, 3, #serialized + 1, serialized)
		end
	end

	return serialized
end

local function serialize_unordered(unordered_queue: { [number]: { any } }, is_16bit: boolean)
	local serialized: { any } = {}

	if not is_16bit then
		local x, y, z = 0, 0, 0
		local n = 0
		local packets = table.create(6)

		for id, packet in unordered_queue do
			n += 1
			table.insert(packets, packet)

			if n == 1 then
				x = id
			elseif n == 2 then
				x += bit32.lshift(id, 8)
			elseif n == 3 then
				y = id
			elseif n == 4 then
				y += bit32.lshift(id, 8)
			elseif n == 5 then
				z = id
			elseif n == 6 then
				z += bit32.lshift(id, 8)
				n = 0

				table.insert(serialized, Vector3int16.new(x, y, z))
				table.move(packets, 1, 6, #serialized + 1, serialized)
				table.clear(packets)
			end
		end

		if n > 0 then
			table.insert(serialized, Vector3int16.new(x, y, z))
			table.move(packets, 1, 6, #serialized + 1, serialized)
		end
	else
		local x, y, z = 0, 0, 0
		local n = 0
		local packets = table.create(6)

		for id, packet in unordered_queue do
			table.insert(packets, packet)

			n += 1
			if n == 1 then
				x = id
			elseif n == 2 then
				y = id
			elseif n == 3 then
				z = id
				n = 0

				table.insert(serialized, Vector3int16.new(x, y, z))
				table.move(packets, 1, 3, #serialized + 1, serialized)
				table.clear(packets)
			end
		end

		if n > 0 then
			table.insert(serialized, Vector3int16.new(x, y, z))
			table.move(packets, 1, 3, #serialized + 1, serialized)
		end
	end
end

local function get_packet(ordered_queue: { any }, unordered_queue: { any })
	local packet: { any } = {}
	table.insert(packet, is_16bit)
	table.insert(packet, serialize_ordered(ordered_queue, is_16bit))
	table.insert(packet, serialize_unordered(unordered_queue, is_16bit))
	ordered_queue = {}
	unordered_queue = {}
	return packet
end

return {
	get_packet = get_packet,
	add_packet_to_queue = add_packet_to_queue,

	serialize_ordered = serialize_ordered,
	serialize_unordered = serialize_unordered,
}
