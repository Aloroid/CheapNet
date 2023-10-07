local testkit = require("test/luau/testkit")
local packet_encoder = require("src/packet_encoder")
local packet_decoder = require("src/packet_decoder")

local BENCH, START = testkit.benchmark()

local function generate_ordered_packet()
	local i = math.random(1, 2)
	return {
		id = math.random(1, 6),
		packet = if i == 1 then true else { test = true, struct = { a = math.random() > 0.5 } },
	}
end

local function TITLE(name: string)
	print()
	print(testkit.color.white(name))
end

do
	TITLE("Packet Encoding  / Decoding")
	local queue = {}
	local result
	local packet

	for i = 1, 10000 do
		table.insert(queue, generate_ordered_packet())
	end

	BENCH("Encoding", function()
		packet = packet_encoder.serialize_ordered(queue, false)
	end)

	BENCH("Decoding", function()
		result = packet_decoder.deserialize_ordered(packet, false)
	end)
end
