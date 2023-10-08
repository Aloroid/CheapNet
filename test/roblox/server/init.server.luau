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

FINISH()
