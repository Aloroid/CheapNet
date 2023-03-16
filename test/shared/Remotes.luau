local CheapNet = require(script.Parent.Packages.CheapNet)

local function a(b: Vector3)
	return true
end

return {
	
	luanoid_move = CheapNet.new("luanoid/move", a),
	luanoid_spawn = CheapNet.new("luanoid/spawn")
	
}