local CheapNet = require(script.Parent.Packages.CheapNet)
local t = require(script.Parent.Packages.t)

return {

	luanoid_move = CheapNet.new("luanoid/move", t.tuple(t.number, t.string, t.string)),
	luanoid_spawn = CheapNet.new("luanoid/spawn", t.string),
}
