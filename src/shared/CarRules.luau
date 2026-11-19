--!strict
--[[
	CarRules — the pure math behind driving (bible §5.2), shared by CarService (server: spring and motor strengths)
	and CarController (client: what the wheels do this frame). No Roblox instances, so Lune specs test it.
	Cars face -Z; their wheels spin around +X; front wheels steer around +Y.
]]
local CarsConfig = require(script.Parent.Config.Cars)

type CarStats = CarsConfig.CarStats

export type DriveMode = "Drive" | "Brake" | "Coast"

local CarRules = {}

-- Spring stiffness and damping so `wheels` springs hold up a car of `mass` sinking `sag` studs, with
-- `dampingRatio` of critical damping.
function CarRules.spring(
	mass: number,
	gravity: number,
	wheels: number,
	sag: number,
	dampingRatio: number
): (number, number)
	local load = mass / wheels
	local stiffness = load * gravity / sag
	local damping = dampingRatio * 2 * math.sqrt(stiffness * load)
	return stiffness, damping
end

-- Torque per wheel motor that pushes a car of `mass` with `acceleration` through wheels of `radius` (times `margin`).
function CarRules.wheelTorque(
	mass: number,
	acceleration: number,
	radius: number,
	wheels: number,
	margin: number
): number
	return mass * acceleration * radius / wheels * margin
end

--[[
	What the wheels should do for `throttle` (-1..1, the seat's ThrottleFloat) while the car rolls `forwardSpeed`
	along its front: the target speed (negative = reverse) and which torque to use. Pressing against the way the car
	rolls brakes before it reverses.
]]
function CarRules.drive(throttle: number, forwardSpeed: number, stats: CarStats): (number, DriveMode)
	if math.abs(throttle) < 0.05 then
		return 0, "Coast"
	elseif (throttle > 0 and forwardSpeed < -2) or (throttle < 0 and forwardSpeed > 2) then
		return 0, "Brake"
	elseif throttle > 0 then
		return stats.TopSpeed * math.min(throttle, 1), "Drive"
	end
	return stats.ReverseSpeed * math.max(throttle, -1), "Drive"
end

-- The wheel motor's angular velocity (rad/s) for a forward speed: rolling forward (-Z) spins the wheels the
-- negative way around +X.
function CarRules.wheelSpin(speed: number, radius: number): number
	return -speed / radius
end

-- Front wheel angle (degrees; positive turns left, the hinge's way) for `steer` (-1..1, positive = right) at `speed`.
function CarRules.steerAngle(steer: number, speed: number, stats: CarStats): number
	local t = math.clamp(math.abs(speed) / stats.TopSpeed, 0, 1)
	local max = stats.SteerAngle + (stats.SteerAngleAtTopSpeed - stats.SteerAngle) * t
	return -math.clamp(steer, -1, 1) * max
end

-- Whether a car whose up direction has this Y part is upside down or on its side.
function CarRules.isFlipped(upY: number, flippedBelowUp: number): boolean
	return upY < flippedBelowUp
end

-- Whether a car can be turned back over now: upside down and (almost) stopped.
function CarRules.canFlip(upY: number, speed: number, flippedBelowUp: number, maxSpeed: number): boolean
	return CarRules.isFlipped(upY, flippedBelowUp) and speed <= maxSpeed
end

return CarRules
