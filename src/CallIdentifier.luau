--[[

	Identifies the call and creates a unique id based on the given call which
	can be used to uniquely identify the call made

]]

return function(...: string | number?)
	local s, l = debug.info(3, "sl")
	local key = `{s}:{l}:` .. table.concat({ ... }, ":")

	return key
end
