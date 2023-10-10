local efficient_pack_int = require("src/efficient_pack_int")
local packet_decoder = require("src/packet_decoder")
local packet_encoder = require("src/packet_encoder")
local signal = require("src/signal")
local testkit = require("test/luau/testkit")

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

TEST("int packing", function()
	do
		CASE("Packs unsigned integers")
		CHECK(efficient_pack_int.pack(56, true) == string.char(56))
		CHECK(efficient_pack_int.unpack(efficient_pack_int.pack(56, true), true) == 56)
	end

	do
		CASE("Packs signed integers")
		print(string.byte(efficient_pack_int.pack(-56)))
		CHECK(efficient_pack_int.pack(-56, false) == string.char(200))
		CHECK(efficient_pack_int.unpack(efficient_pack_int.pack(-56)) == -56)
	end

	do
		CASE("Errors when packing negative integers as unsigned")
		CHECK(pcall(function()
			efficient_pack_int.pack(-56, true)
		end) == false)
	end
end)

TEST("signal", function()
	local s, fire = signal()
	local connection
	local v

	do
		CASE("connecting to signal")

		connection = s:connect(function(a)
			v = a
		end)

		CHECK(connection)
	end

	do
		CASE("firing signal should call all callbacks")
		fire(1)
		CHECK(v == 1)
	end

	do
		CASE("disconnecting connections should prevent it from firing again")
		connection:disconnect()
		fire(2)
		CHECK(v == 1)
	end

	do
		CASE("reconnecting connections should let it fire again")
		connection:reconnect()
		fire(2)
		CHECK(v == 2)
	end

	do
		CASE(":once should only fire once")
		local v
		s:once(function(a0: number)
			v = a0
		end)

		fire(3)
		CHECK(v == 3)
		fire(4)
		CHECK(v == 3)
	end

	do
		CASE(":wait should yield")

		local v
		local thread = coroutine.create(function()
			v = s:wait()
		end)

		coroutine.resume(thread)
		CHECK(coroutine.status(thread) == "suspended")
		fire(5)
		CHECK(coroutine.status(thread) == "dead")
		CHECK(v == 5)
	end
end)

FINISH()
