--[[

	the packet encoder encodes packets into a special format.

]]

local is_16bit = false

local is_vector = "Vector3int16"
if not Vector3int16 then
	is_vector = "table"
end

local function convert(packet: { any } | any): ...any
	if type(packet) == "table" then
		return unpack(packet)
	else
		return packet
	end
end

-- serializes the ordered packets using either 1 byte or 2 byte identifiers.
local function deserialize_ordered(ordered: { any }, is_16bit: boolean)
	local normal = {}

	local x, y, z
	local packet_count = if is_16bit then 4 else 7
	for i, encoded_packet in ordered do
		-- every x packets
		local n = (i - 1) % packet_count
		if n == 0 then
			assert(typeof(encoded_packet) == is_vector, "Packet is malformed")
			x, y, z = encoded_packet.X, encoded_packet.Y, encoded_packet.Z
			continue
		end

		assert(x and y and z, "no x y z")

		local id = if is_16bit
			then (if n == 1 then x elseif n == 2 then y else z)
			else (if n == 1
				then bit32.extract(x, 0, 8)
				elseif n == 2 then bit32.extract(x, 8, 8)
				elseif n == 3 then bit32.extract(y, 0, 8)
				elseif n == 4 then bit32.extract(y, 8, 8)
				elseif n == 5 then bit32.extract(z, 0, 8)
				else bit32.extract(z, 8, 8))

		table.insert(normal, { id = id, packet = encoded_packet })
	end

	return normal
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
				x += bit32.lshift(id, 9)
			elseif n == 3 then
				y = id
			elseif n == 4 then
				y += bit32.lshift(id, 9)
			elseif n == 5 then
				z = id
			elseif n == 6 then
				z += bit32.lshift(id, 9)
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

local function get_packet(ordered_queue: { any }, unordered_queue: { any })
	local packet: { any } = {}
	table.insert(packet, is_16bit)
	table.insert(packet, deserialize_ordered(ordered_queue, is_16bit))
	table.insert(packet, serialize_unordered(unordered_queue, is_16bit))
	ordered_queue = {}
	unordered_queue = {}
	return packet
end

return {
	get_packet = get_packet,
	deserialize_ordered = deserialize_ordered,
}
