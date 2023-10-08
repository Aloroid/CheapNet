local testkit = require("test/luau/testkit")
local packet_encoder = require("src/packet_encoder")
local packet_decoder = require("src/packet_decoder")

local TEST, CASE, CHECK, FINISH = testkit.test()

local function generate_ordered_packet()
	return {
		id = math.random(1, 6),
		packet = true,
	}
end

local function generate_unordered_packet(n: number)
	local packets = {}

	for i = 1, n do
		packets[i] = true
	end

	return packets
end

TEST("packet encoding decoding on ordered", function()
	local queue = {}
	local result
	local packet

	for i = 1, 6 do
		table.insert(queue, generate_ordered_packet())
	end

	do
		CASE("Packet Encoding")
		packet = packet_encoder.serialize_ordered(queue, false)
		CHECK(packet)
	end

	do
		CASE("Packet Decoding")
		result = packet_decoder.deserialize_ordered(packet)
		CHECK(result)
	end

	do
		CASE("Packet is equal")
		CHECK(testkit.deq(queue, result))
	end
end)

TEST("packet encoding decoding on unordered", function()
	local queue = {}
	local result
	local packet

	for i = 1, 6 do
		queue[i] = generate_unordered_packet(10)
	end

	do
		CASE("Packet Encoding")
		packet = packet_encoder.serialize_unordered(queue, false)
		CHECK(packet)
	end

	do
		CASE("Packet Decoding")
		result = packet_decoder.deserialize_unordered(packet)
		CHECK(result)
	end

	do
		CASE("Packet is equal")
		CHECK(testkit.deq(queue, result))
	end
end)

FINISH()
