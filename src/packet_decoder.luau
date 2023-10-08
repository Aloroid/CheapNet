--[[

	the packet encoder encodes packets into a special format.

]]

local is_16bit = false
local cache_8 = {}
local cache_16 = {}

for i = 0, 255 do
	cache_8[string.char(i)] = i
end

-- serializes the ordered packets using either 1 byte or 2 byte identifiers.
local function deserialize_ordered(ordered: { any })
	local deserialized = table.create(#ordered)
	local ids = table.remove(ordered, 1) :: string
	local is_16bit = string.sub(ids, 1, 1) == "H"
	local cache = if is_16bit then cache_16 else cache_8 :: never

	for i, packet in ordered do
		local string_id = string.sub(ids, i + 1, i + 1)
		local id = cache[string_id] or if is_16bit then string.unpack("H", ids, (i - 1) * 2) else string.byte(string_id);

		(if is_16bit then cache_16 else cache_8 :: never)[string_id] = id

		deserialized[i] = { id = id, packet = packet }
	end

	table.freeze(deserialized)
	return deserialized
end

local function deserialize_unordered(unordered: { any })
	local deserialized: { any } = {}
	local ids = table.remove(unordered, 1) :: string
	local is_16bit = string.sub(ids, 1, 1) == "H"

	local cache = if is_16bit then cache_16 else cache_8 :: never

	for i, packets in unordered do
		local s_id = string.sub(ids, i + 1, i + 1)
		local id = cache[s_id] or (is_16bit and string.unpack("H", ids, (i - 1) * 2) or string.byte(s_id))
		cache[s_id] = id

		deserialized[id] = packets
	end

	return deserialized
end

local function get_packet(ordered_queue: { any }, unordered_queue: { any })
	local packet: { any } = {}
	table.insert(packet, is_16bit)
	table.insert(packet, deserialize_ordered(ordered_queue))
	table.insert(packet, deserialize_unordered(unordered_queue))
	ordered_queue = {}
	unordered_queue = {}
	return packet
end

return {
	get_packet = get_packet,
	deserialize_ordered = deserialize_ordered,
	deserialize_unordered = deserialize_unordered,
}
