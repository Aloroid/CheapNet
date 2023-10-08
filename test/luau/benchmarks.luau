local testkit = require("test/luau/testkit")
local packet_encoder = require("src/packet_encoder")
local packet_decoder = require("src/packet_decoder")

local BENCH, START = testkit.benchmark()

math.randomseed(0)

local function generate_ordered_packet()
	local i = math.random(1, 2)
	return {
		id = math.random(1, 10),
		packet = if i == 1 then true else { test = true, struct = { a = math.random() > 0.5 } },
	}
end

local function generate_unordered_packet(n: number)
	local packets = {}

	for i = 1, n do
		packets[i] = { test = true, struct = { a = math.random() > 0.5 } }
	end

	return packets
end

local function TITLE(name: string)
	print(testkit.color.white(name))
end

do
	TITLE("Packet Encoding  / Decoding Ordered")
	local queue = {}
	local packet

	for i = 1, 10000 do
		table.insert(queue, generate_ordered_packet())
	end

	BENCH("Encoding", function()
		START(#queue)
		packet = packet_encoder.serialize_ordered(queue, false)
	end)

	--print(counter.GetDataByteSize(packet))

	BENCH("Decoding", function()
		START(#queue)
		packet_decoder.deserialize_ordered(packet)
	end)
end

do
	TITLE("Packet Encoding  / Decoding Unordered")
	local queue = {}
	local packet

	for i = 1, 100 do
		queue[i] = generate_unordered_packet(1000)
	end

	--packet_encoder.serialize_unordered(queue, false)

	BENCH("Encoding", function()
		START(#queue)
		packet = packet_encoder.serialize_unordered(queue, true)
	end)

	--print(counter.GetDataByteSize(packet))

	BENCH("Decoding", function()
		START(#queue)
		packet_decoder.deserialize_unordered(packet)
	end)
end
