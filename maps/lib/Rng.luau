--!strict
--[[
	A tiny seeded random generator (Park–Miller) for map layouts: the same seed gives the same map on every run and
	OS, so `lune run maps/build --check` stays stable. Every product stays below 2^53, so the math is exact.
]]
local Rng = {}
Rng.__index = Rng

export type Rng = typeof(setmetatable({} :: { state: number }, Rng))

local MODULUS = 2147483647

function Rng.new(seed: number): Rng
	local state = math.floor(seed) % MODULUS
	if state == 0 then
		state = 1
	end
	return setmetatable({ state = state }, Rng)
end

-- A number in [0, 1).
function Rng.next(self: Rng): number
	self.state = (self.state * 48271) % MODULUS
	return (self.state - 1) / (MODULUS - 1)
end

-- A number in [min, max), rounded to 0.05 (shorter map files).
function Rng.range(self: Rng, min: number, max: number): number
	return math.floor((min + (max - min) * self:next()) * 20 + 0.5) / 20
end

-- A whole number in [min, max].
function Rng.int(self: Rng, min: number, max: number): number
	return math.min(max, min + math.floor((max - min + 1) * self:next()))
end

function Rng.chance(self: Rng, probability: number): boolean
	return self:next() < probability
end

function Rng.pick<T>(self: Rng, list: { T }): T
	return list[self:int(1, #list)]
end

return Rng
