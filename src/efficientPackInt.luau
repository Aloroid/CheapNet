--[[
	This function will efficiently pack integers to be as small as possible.
	
]]

local BYTE = 2^256

local function efficientPackInt(n: number, unsigned: boolean?)
	n = math.round(n) -- automatically round decimal numbers
	assert(unsigned == true and n >= 0 or unsigned == false, "Cannot pack negative numbers as unsigned")
	
	if unsigned then
		local bytes = math.ceil(math.log(n + 1, BYTE))
		return string.pack("I"..bytes, n)
	else
		n = if n >= 0 then n + 1 else math.abs(n)
		local bytes = math.ceil(math.log(n + 1, BYTE / 2))
		return string.pack("i"..bytes, n)
	end
	
end

local function efficientUnpackInt(n: string, unsigned: boolean?)
	
	local size = #n
	
	if unsigned then
		return string.unpack("I"..size, n)
	else
		return string.unpack("i"..size, n)
	end
	
end

return {
	pack = efficientPackInt,
	unpack = efficientUnpackInt
	
}