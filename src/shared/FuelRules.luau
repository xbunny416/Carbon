--!strict
--[[
	FuelRules — the pure math behind the tank and oil barrels (bible §5.3, §5.4), used by Services/FuelService,
	Services/OilService and their specs.
]]
local FuelRules = {}

-- Distance that counts for burning: a move of `distance` studs in `dt` seconds, capped at `maxSpeed`.
function FuelRules.countedDistance(distance: number, dt: number, maxSpeed: number): number
	return math.clamp(distance, 0, maxSpeed * dt)
end

-- The tank after driving `distance` studs (never below 0).
function FuelRules.burn(fuel: number, distance: number, perStud: number): number
	return math.max(0, fuel - distance * perStud)
end

-- The tank after picking up an oil barrel worth `amount` (never above `max`).
function FuelRules.addOil(fuel: number, max: number, amount: number): number
	return math.min(max, fuel + amount)
end

-- Whether a car can take a barrel: only when its tank isn't full (a full car leaves it for someone else).
function FuelRules.canTakeOil(fuel: number, max: number): boolean
	return fuel < max - 0.5
end

-- Whether the tank just dropped below the low-fuel line.
function FuelRules.crossedLow(before: number, after: number, max: number, lowFraction: number): boolean
	local line = max * lowFraction
	return before >= line and after < line
end

return FuelRules
