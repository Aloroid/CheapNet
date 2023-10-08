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
		CASE("Get Identifier")
		value = cheapnet.get_global_identifier(identifier)
		CHECK(value == "test")
	end

	do
		CASE("Identifiers remain the same")
		CHECK(identifier == cheapnet.create_global_identifier("test"))
	end
end)

FINISH()
