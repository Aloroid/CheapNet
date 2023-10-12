local leaky_bucket = {}
leaky_bucket.__index = leaky_bucket

export type LeakyBucket = typeof(setmetatable(
	{} :: {
		drain_per_second: number,
		current: number,
		max: number,

		last_drained: number,
	},
	leaky_bucket
))

function leaky_bucket.new(drain: number, max: number)
	local self = setmetatable({

		drain_per_second = drain,
		current = 0,
		max = max,

		last_drained = os.clock(),
	}, leaky_bucket)

	return self :: LeakyBucket
end

-- calculates how much to drain
function leaky_bucket.drain(self: LeakyBucket)
	local last_drained = self.last_drained
	local time_between_last_drain = os.clock() - last_drained

	if time_between_last_drain < 1 then return end

	self.current -= time_between_last_drain * self.drain_per_second
	self.last_drained = os.clock()
end

function leaky_bucket.add(self: LeakyBucket, delta: number?): (boolean, string?)
	delta = delta or 1
	assert(delta) --FIXME

	self:drain()

	if self.max < self.current then return false, `bucket is gonna leak by {self.current - self.max}` end

	self.current += delta

	return true
end

function leaky_bucket.leaking(self: LeakyBucket)
	return self.max < self.current
end

return leaky_bucket
