local ReplicatedStorage = game:GetService("ReplicatedStorage")

local cheapnet = require(ReplicatedStorage.Packages.CheapNet)
local quick_remotes = require(ReplicatedStorage.quick_remotes)
local testkit = require(ReplicatedStorage.testkit)

testkit.disable_formatting()

local TEST, CASE, CHECK, FINISH = testkit.test()

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

FINISH()
