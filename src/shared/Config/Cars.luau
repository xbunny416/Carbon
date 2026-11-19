--!strict
--[[
	Cars (bible §5.2): how each car drives, the starter car, and the rules for flipping, resetting and spawning.
	Speeds are studs/s, accelerations studs/s², angles degrees. Every Models entry needs a builder in
	assets/cars/<Name>.luau (`lune run assets/build` makes ReplicatedStorage.Assets.Models.Cars.<Name>). Tank, Cargo
	and Health are used from build-order items 1.3 (fuel), 1.4 (oil) and 1.6 (wrecks).
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
	Cargo: number,
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
	ResetCooldown: number,
	BayClearance: number,
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
			Cargo = 6,
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
	ResetCooldown = 10, -- seconds between two Reset car presses
	BayClearance = 9, -- studs: a car spawn bay is free when no car is this close
	ExitSide = 5, -- studs to the car's left where the driver lands when getting out
	EnterRange = 16, -- studs: the server's limit for the Drive prompt (a bit more than the prompt's own range)
}

return Cars
