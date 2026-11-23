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

--[[
	How fast one wheel should spin in a turn, as a share of the car's speed (an "electronic differential"): in a turn
	every wheel circles the same center, so the inner ones roll a shorter path. Forcing all four to the same speed
	makes them fight the turn (hard to steer, and stuck at low speed). `angle` is the front wheels' angle (degrees,
	positive = left, as steerAngle returns), (x, z) the wheel's place on the car (front = -Z), `base` the distance
	from the car's middle to each axle. The turn center sits level with the rear axle.
]]
function CarRules.wheelFactor(angle: number, x: number, z: number, base: number): number
	local tangent = math.tan(math.rad(math.abs(angle)))
	if tangent < 1e-3 then
		return 1
	end
	local radius = base * 2 / tangent
	local cx = if angle > 0 then -radius else radius -- a left turn circles a center on the car's left (-X)
	local function distance(px: number, pz: number): number
		return math.sqrt((px - cx) ^ 2 + (pz - base) ^ 2)
	end
	return distance(x, z) / distance(0, 0)
end

--[[
	Arcade helpers (all accelerations; multiply by mass / inertia for forces / torques). They run only while the car
	is on the ground (except airLevel), on the driver's client, through the car's Assist VectorForce and TurnAssist
	Torque (assets/cars/CarKit).
]]

-- Sideways acceleration that cancels `lateralSpeed` (studs/s, along the car's right) at `rate` per second, capped.
function CarRules.grip(lateralSpeed: number, rate: number, limit: number): number
	return math.clamp(-lateralSpeed * rate, -limit, limit)
end

-- Extra acceleration toward the ground at `speed` (studs/s): `perSpeed` studs/s² for every stud/s.
function CarRules.downforce(speed: number, perSpeed: number): number
	return math.abs(speed) * perSpeed
end

-- The turn rate (radians/s around the car's up, positive = left) the steering asks for: a car with wheels `length`
-- studs apart rolling `forwardSpeed` with front wheels at `angle` degrees (positive = left) — the bicycle model.
function CarRules.targetTurnRate(forwardSpeed: number, angle: number, length: number): number
	return forwardSpeed * math.tan(math.rad(angle)) / length
end

-- Turning acceleration (radians/s²) that moves the turn rate from `current` toward `target`, capped at `limit`.
function CarRules.turnAssist(target: number, current: number, response: number, limit: number): number
	return math.clamp((target - current) * response, -limit, limit)
end

-- Yaw moment of inertia of a box-shaped car (mass, length, width): how hard it is to turn around its up axis.
function CarRules.yawInertia(mass: number, length: number, width: number): number
	return mass * (length * length + width * width) / 12
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
