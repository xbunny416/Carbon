--!strict
--[[
	Fuel (bible §5.3): every car's tank is Config.Cars.Models[...].Tank. Driving burns fuel by the distance the car
	really moves (measured on the server); an empty tank burns a cargo barrel if there is one, otherwise the car
	stalls and its owner can tow it home. Standing still in a gas station pump bay refills the tank for free.
]]
return {
	BurnPerStud = 1 / 25, -- fuel per stud driven (a 100 tank goes ~2,500 studs)
	BarrelFuel = 25, -- an empty tank burns one cargo barrel for this much fuel
	RefillRate = 25, -- fuel per second at a pump
	PumpRadius = 7, -- studs (sideways) from a PumpBay marker that count as "at the pump"
	PumpMaxSpeed = 3, -- studs/s: the car has to (almost) stop to refill
	MaxCountedSpeed = 120, -- studs/s: faster moves (a flip, a teleport) only count this much distance
	LowFraction = 0.2, -- the gauge turns red and a "low fuel" notice shows below this share of the tank
	Tick = 0.1, -- seconds between fuel updates on the server
}
