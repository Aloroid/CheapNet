local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CheapNet = require(ReplicatedStorage.Packages.CheapNet)
local quick_remotes = require(ReplicatedStorage.quick_remotes)

quick_remotes.get_remote_event("new_remote"):FireServer()

local event = CheapNet.event("this_inst_here_yet")

return event
