--!strict
--[[
	Cars (bible §5.2): how each car drives, the starter car, and the rules for flipping and spawning.
	Speeds are studs/s, accelerations studs/s², angles degrees. Every Models entry needs a builder in
	assets/cars/<Name>.luau (`lune run assets/build` makes ReplicatedStorage.Assets.Models.Cars.<Name>). Tank is the
	fuel tank (bible §5.3); Health is for ramming (build order 1.5).
]]
export type CarStats = {
	TopSpeed: number, -- forward
	ReverseSpeed: number,
	Acceleration: number, -- what the motors can give the car
	Braking: number, -- pressing against the way the car rolls
	Coasting: number, -- slowdown with no throttle
	SteerAngle: number, -- front wheel angle at a standstill...
	SteerAngleAtTopSpeed: number, -- ...shrinking to this at top speed, so fast turns don't roll the car
	SteerSpeed: number, -- how fast the front wheels turn (degrees/s)
	Sag: number, -- studs the springs sink under the car's weight
	DampingRatio: number, -- 0 = bouncy, 1 = no bounce
	Tank: number,
	Health: number,
}

type CarsConfig = {
	Starter: string,
	Models: { [string]: CarStats },
	MotorMargin: number,
	FlippedBelowUp: number,
	FlipMaxSpeed: number,
	FlipDelay: number,
	FlipLift: number,
	FlipRange: number,
	SpawnCooldown: number,
	RespawnFuel: number,
	SpawnSide: number,
	ExitSide: number,
	EnterRange: number,
}

local Cars: CarsConfig = {
	Starter = "RustyPickup",
	Models = {
		RustyPickup = {
			TopSpeed = 60,
			ReverseSpeed = 22,
			Acceleration = 28,
			Braking = 60,
			Coasting = 6,
			SteerAngle = 40,
			SteerAngleAtTopSpeed = 18,
			SteerSpeed = 220,
			Sag = 0.5,
			DampingRatio = 0.55,
			Tank = 100,
			Health = 100,
		},
	},
	-- Motor torque is worked out from the car's mass and Acceleration, times this (covers the driver, slopes, sand).
	MotorMargin = 2.2,
	-- Upside down (or on its side) when the car's up direction points up less than this (1 = upright, -1 = roof).
	FlippedBelowUp = 0.3,
	FlipMaxSpeed = 5, -- only a car that has (almost) stopped can be flipped
	FlipDelay = 1, -- seconds between pressing Flip and the car turning over
	FlipLift = 4, -- studs the car is lifted when righted
	FlipRange = 30, -- studs: the owner can flip it from this close, not only from the seat
	SpawnCooldown = 15, -- seconds between two Spawn car presses
	RespawnFuel = 25, -- a car spawned again keeps the old car's fuel, but gets at least this much
	SpawnSide = 9, -- studs beside you where a spawned car appears
	ExitSide = 5, -- studs to the car's left where the driver lands when getting out
	EnterRange = 16, -- studs: the server's limit for the Drive prompt (a bit more than the prompt's own range)
}

return Cars
