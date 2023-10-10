local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local cheapnet = require(ReplicatedStorage.Packages.CheapNet)
local filterable = require(ReplicatedStorage.Packages.CheapNet.filterable)
local quick_remotes = require(ReplicatedStorage.quick_remotes)
local testkit = require(ReplicatedStorage.testkit)

testkit.disable_formatting()

local TEST, CASE, CHECK, FINISH = testkit.test()

local function CHECK_ERR(callback: () -> (), ...)
	CHECK(pcall(callback, ...) == false)
end

TEST("Identifiers", function()
	quick_remotes.get_remote_event("identifier_create").OnServerEvent:Wait()

	local identifier
	do
		CASE("Create Identifier")
		identifier = cheapnet.create_global_identifier("test")
		cheapnet.create_global_identifier("hiiii")
		CHECK(type(identifier) == "string")
	end

	do
		CASE("Identifiers remain the same")
		CHECK(identifier == cheapnet.create_global_identifier("test"))
	end

	do
		CASE("Get Identifier")
		CHECK("test" == cheapnet.get_global_identifier(identifier))
	end

	quick_remotes.get_remote_event("identifier_get"):FireAllClients(identifier)
end)

TEST("Filterables", function()
	do
		CASE(":include includes players")
		local player_1 = Players:GetPlayers()[1]
		CHECK(filterable():include(player_1):list()[1] == player_1)
		CHECK(#filterable():include(player_1):include(player_1):list() == 1)
	end

	do
		CASE(":exclude removes players")
		local player_1 = Players:GetPlayers()[1]
		CHECK(filterable():include(player_1):exclude(player_1):list()[1] ~= player_1)
	end

	do
		CASE(":always")
		local player_1 = Players:GetPlayers()[1]
		CHECK(filterable():always(player_1):exclude(player_1):list()[1] == player_1)
	end

	do
		CASE(":never")
		local player_1 = Players:GetPlayers()[1]
		CHECK(filterable():never(player_1):include(player_1):list()[1] ~= player_1)
	end

	do
		CASE(":has")
		local player_1 = Players:GetPlayers()[1]
		CHECK(filterable():has(player_1) == false)
		CHECK(filterable():include(player_1):has(player_1) == true)
	end

	do
		CASE(":all")
		CHECK(#filterable():all():list() == #Players:GetPlayers())
	end

	do
		CASE(":always errors when player must :never be included")
		local player_1 = Players:GetPlayers()[1]
		CHECK_ERR(function()
			filterable():never(player_1):always(player_1)
		end)
	end

	do
		CASE(":never errors when player must :always be included")
		local player_1 = Players:GetPlayers()[1]
		CHECK_ERR(function()
			filterable():always(player_1):never(player_1)
		end)
	end

	do
		CASE("later calls take precedent")
		local player_1 = Players:GetPlayers()[1]
		CHECK(filterable():include(player_1):exclude(player_1):include(player_1):list()[1] == player_1)
	end
end)

cheapnet.event(1, "unordered")
cheapnet.event(2, "unordered")
cheapnet.event(3, "ordered")
cheapnet.event(4, "ordered")
cheapnet.event(5, "ordered")
cheapnet.event(6, "ordered")
cheapnet.event(7, "unordered")
TEST("Unordered Events", function()
	do
		CASE("Remotes receive and send packets")
		local event = cheapnet.event(1)

		quick_remotes.get_remote_event("event").OnServerEvent:Wait()
		event:fire_clients(true):all()
		CHECK(true)

		quick_remotes.get_remote_event("event"):FireClient(filterable():all():list()[1])
		local plr, a = event.on_server_event:wait()
		CHECK(plr:IsA("Player") and a == true)
	end

	do
		CASE("Remotes respect nil values")
		local event = cheapnet.event(2)
		quick_remotes.get_remote_event("event").OnServerEvent:Wait()
		event:fire_clients(true, nil, false):all()
		local _, a, b, c = event.on_server_event:wait()

		CHECK(a == true and b == nil and c == false)
	end
end)

TEST("Ordered Events", function()
	do
		CASE("Remotes receive and send packets")
		local event = cheapnet.event(3, "ordered")

		quick_remotes.get_remote_event("event").OnServerEvent:Wait()
		event:fire_clients(true):all()

		quick_remotes.get_remote_event("event"):FireClient(filterable():all():list()[1])
		local plr, a = event.on_server_event:wait()
		CHECK(plr:IsA("Player") and a == true)
	end

	do
		CASE("Remotes respect nil values")
		local event = cheapnet.event(4, "ordered")

		quick_remotes.get_remote_event("event").OnServerEvent:Wait()
		event:fire_clients(true, nil, false):all()
		local _, a, b, c = event.on_server_event:wait()

		CHECK(a == true)
		CHECK(b == nil)
		CHECK(c == false)
	end

	do
		CASE("Remotes respect order")
		local event1 = cheapnet.event(5, "ordered")
		local event2 = cheapnet.event(6, "ordered")
		local event3 = cheapnet.event(7, "unordered")

		quick_remotes.get_remote_event("event").OnServerEvent:Wait()
		event3:fire_clients():all()
		event1:fire_clients():all()
		event2:fire_clients():all()
		event1:fire_clients():all()

		local order = {}
		local thread = coroutine.running()

		local function add(n)
			return function()
				table.insert(order, n)
				if #order == 4 then coroutine.resume(thread) end
			end
		end

		event1.on_server_event:connect(add(1))
		event2.on_server_event:connect(add(2))
		event3.on_server_event:connect(add(3))

		coroutine.yield()

		CHECK(order[1] == 1)
		CHECK(order[2] == 2)
		CHECK(order[3] == 1)
		CHECK(order[4] == 3)
	end
end)

FINISH()
