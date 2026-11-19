--!strict
--[[
	FuelRules — the pure math behind the tank (bible §5.3), used by Services/FuelService and its specs.
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

-- The tank after `dt` seconds at a pump (never above `max`).
function FuelRules.refill(fuel: number, max: number, rate: number, dt: number): number
	return math.min(max, fuel + rate * dt)
end

--[[
	What happens when the tank is empty: with cargo, one barrel is burned into fuel; without, the car stalls.
	Returns the new fuel, the new cargo count, and whether the car stalls.
]]
function FuelRules.whenEmpty(fuel: number, cargo: number, barrelFuel: number, max: number): (number, number, boolean)
	if fuel > 0 then
		return fuel, cargo, false
	elseif cargo > 0 then
		return math.min(max, barrelFuel), cargo - 1, false
	end
	return 0, cargo, true
end

-- Whether the tank just dropped below the low-fuel line.
function FuelRules.crossedLow(before: number, after: number, max: number, lowFraction: number): boolean
	local line = max * lowFraction
	return before >= line and after < line
end

return FuelRules
