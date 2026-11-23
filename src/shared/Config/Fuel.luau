--!strict
--[[
	Fuel (bible §5.3): every car's tank is Config.Cars.Models[...].Tank. Driving burns fuel by the distance the car
	really moves (measured on the server); an empty tank stalls the car. The only way to refill is oil barrels
	(Config.Oil) — or spawning the car again (Config.Cars.RespawnFuel).
]]
return {
	BurnPerStud = 1 / 25, -- fuel per stud driven (a 100 tank goes ~2,500 studs)
	MaxCountedSpeed = 120, -- studs/s: faster moves (a flip, a teleport) only count this much distance
	LowFraction = 0.2, -- the gauge turns red and a "low fuel" notice shows below this share of the tank
	Tick = 0.1, -- seconds between fuel updates on the server
}
