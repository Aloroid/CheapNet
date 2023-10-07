local testkit = require("test/luau/testkit")
local packet_encoder = require("src/packet_encoder")
local packet_decoder = require("src/packet_decoder")

local TEST, CASE, CHECK, FINISH = testkit.test()

local function generate_ordered_packet()
	local i = math.random(1, 2)
	return {
		id = math.random(1, 6),
		packet = if i == 1 then true else { test = true, struct = { a = math.random() > 0.5 } },
	}
end

TEST("packet encoding decoding", function()
	local queue = {}
	local result
	local packet

	for i = 1, 6 do
		table.insert(queue, generate_ordered_packet())
	end

	do
		CASE("Packet Encoding")
		packet = packet_encoder.serialize_ordered(queue, true)
		CHECK(packet)
	end

	do
		CASE("Packet Decoding")
		result = packet_decoder.deserialize_ordered(packet, true)
		CHECK(result)
	end

	do
		CASE("Packet is equal")
		CHECK(testkit.deq(queue, result))
	end
end)

FINISH()
