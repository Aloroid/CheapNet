local ReplicatedStorage = game:GetService("ReplicatedStorage")

local cheapnet = require(ReplicatedStorage.Packages.CheapNet)
local quick_remotes = require(ReplicatedStorage.quick_remotes)
local testkit = require(ReplicatedStorage.testkit)

testkit.disable_formatting()

local TEST, CASE, CHECK, FINISH = testkit.test()

TEST("Identifiers", function()
	quick_remotes.get_remote_event("identifier_create"):FireServer()

	local identifier = quick_remotes.get_remote_event("identifier_get").OnClientEvent:Wait()
	local value
	do
		CASE("Get Identifier Value")
		value = cheapnet.get_value(identifier)
		CHECK(value == "test")
	end

	do
		CASE("Get Identifier")
		CHECK(cheapnet.create_identifier("hiiii") ~= nil)
	end

	do
		CASE("Identifiers remain the same")
		CHECK(identifier == cheapnet.create_identifier("test"))
	end

	do
		CASE("Attempting to create unknown identifiers will error")
		CHECK(pcall(function()
			cheapnet.create_identifier("awawa")
		end) == false)
	end
end)

TEST("Unordered Events", function()
	do
		CASE("Remotes receive and send packetss")
		local event = cheapnet.event(1, "unordered")

		quick_remotes.get_remote_event("event"):FireServer()
		local a = event.on_client_event:wait()
		CHECK(a == true)

		quick_remotes.get_remote_event("event").OnClientEvent:Wait()
		event:fire_server(true)
	end

	do
		CASE("Remotes respect nil values")
		local event = cheapnet.event(2, "unordered")

		quick_remotes.get_remote_event("event"):FireServer()
		local a, b, c = event.on_client_event:wait()
		CHECK(b == nil and c == false and a == true)
		event:fire_server(true, nil, false)
	end
end)

TEST("Ordered Events", function()
	do
		CASE("Remotes receive and send packets")

		local event = cheapnet.event(3, "ordered")

		quick_remotes.get_remote_event("event"):FireServer()
		local a = event.on_client_event:wait()
		CHECK(a == true)

		quick_remotes.get_remote_event("event").OnClientEvent:Wait()
		event:fire_server(true)
		CHECK(true)
	end

	do
		CASE("Remotes respect nil values")
		local event = cheapnet.event(4, "ordered")

		quick_remotes.get_remote_event("event"):FireServer()
		local a, b, c = event.on_client_event:wait()

		CHECK(a == true)
		CHECK(b == nil)
		CHECK(c == false)

		event:fire_server(true, nil, false)
	end

	do
		CASE("Remotes respect order")
		local event1 = cheapnet.event(5, "ordered")
		local event2 = cheapnet.event(6, "ordered")
		local event3 = cheapnet.event(7, "unordered")

		quick_remotes.get_remote_event("event"):FireServer()
		local order = {}
		local thread = coroutine.running()

		local function add(n)
			return function()
				table.insert(order, n)
				if #order == 4 then coroutine.resume(thread) end
			end
		end

		event1.on_client_event:connect(add(1))
		event2.on_client_event:connect(add(2))
		event3.on_client_event:connect(add(3))

		coroutine.yield()

		CHECK(order[1] == 1)
		CHECK(order[2] == 2)
		CHECK(order[3] == 1)
		CHECK(order[4] == 3)

		event3:fire_server()
		event1:fire_server()
		event2:fire_server()
		event1:fire_server()
	end
end)

TEST("Unreliable Events", function()
	do
		CASE("Remotes receive and send packets")
		local event = cheapnet.event(8, "unreliable")

		quick_remotes.get_remote_event("event"):FireServer()
		local a = event.on_client_event:wait()
		CHECK(a == true)

		quick_remotes.get_remote_event("event").OnClientEvent:Wait()
		event:fire_server(true)
	end

	do
		CASE("Remotes respect nil values")
		local event = cheapnet.event(9, "unreliable")

		quick_remotes.get_remote_event("event"):FireServer()
		local a, b, c = event.on_client_event:wait()
		CHECK(b == nil and c == false and a == true)
		event:fire_server(true, nil, false)
	end
end)

TEST("Unordered Events 16bit", function()
	cheapnet.event(301):fire_server()

	do
		CASE("Remotes receive and send packets")
		local event = cheapnet.event(1, "unordered")

		quick_remotes.get_remote_event("event"):FireServer()
		local a = event.on_client_event:wait()
		CHECK(a == true)

		quick_remotes.get_remote_event("event").OnClientEvent:Wait()
		event:fire_server(true)
	end

	do
		CASE("Remotes respect nil values")
		local event = cheapnet.event(2, "unordered")

		quick_remotes.get_remote_event("event"):FireServer()
		local a, b, c = event.on_client_event:wait()
		CHECK(b == nil and c == false and a == true)
		event:fire_server(true, nil, false)
	end
end)

TEST("Ordered Events 16bit", function()
	do
		CASE("Remotes receive and send packets")

		local event = cheapnet.event(3, "ordered")

		quick_remotes.get_remote_event("event"):FireServer()
		local a = event.on_client_event:wait()
		CHECK(a == true)

		quick_remotes.get_remote_event("event").OnClientEvent:Wait()
		event:fire_server(true)
		CHECK(true)
	end

	do
		CASE("Remotes respect nil values")
		local event = cheapnet.event(4, "ordered")

		quick_remotes.get_remote_event("event"):FireServer()
		local a, b, c = event.on_client_event:wait()

		CHECK(a == true)
		CHECK(b == nil)
		CHECK(c == false)

		event:fire_server(true, nil, false)
	end

	do
		CASE("Remotes respect order")
		local event1 = cheapnet.event(5, "ordered")
		local event2 = cheapnet.event(6, "ordered")
		local event3 = cheapnet.event(7, "unordered")

		quick_remotes.get_remote_event("event"):FireServer()
		local order = {}
		local thread = coroutine.running()

		local function add(n)
			return function()
				table.insert(order, n)
				if #order == 4 then coroutine.resume(thread) end
			end
		end

		event1.on_client_event:connect(add(1))
		event2.on_client_event:connect(add(2))
		event3.on_client_event:connect(add(3))

		coroutine.yield()

		CHECK(order[1] == 1)
		CHECK(order[2] == 2)
		CHECK(order[3] == 1)
		CHECK(order[4] == 3)

		event3:fire_server()
		event1:fire_server()
		event2:fire_server()
		event1:fire_server()
	end
end)

FINISH()
