local LeakyBucket = {}
LeakyBucket.__index = LeakyBucket

export type LeakyBucket = typeof(setmetatable(
	{} :: {
		drdrain_per_secondain: number,
		current: number,
		max: number,

		last_drained: number,
	},
	LeakyBucket
))

function LeakyBucket.new(drain: number, max: number)
	local self = setmetatable({

		drain_per_second = drain,
		current = 0,
		max = max,

		last_drained = os.clock(),
	}, LeakyBucket)

	return self :: LeakyBucket
end

-- calculates how much to drain
function LeakyBucket.drain(self: LeakyBucket)
	local last_drained = self.last_drained
	local time_between_last_drain = os.clock() - last_drained

	if time_between_last_drain < 1 then
		return
	end

	self.current -= time_between_last_drain * self.drain_per_second
	self.last_drained = os.clock()
end

function LeakyBucket.add(self: LeakyBucket, delta: number?)
	delta = delta or 1
	assert(delta) -- FIXME

	self:drain()

	if self.max < self.current then
		return false, `bucket is gonna leak by {self.current - self.max}`
	end

	self.current += delta

	return true
end

function LeakyBucket.leaking(self: LeakyBucket)
	return self.max < self.current
end

return LeakyBucket
