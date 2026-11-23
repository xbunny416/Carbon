--!strict
--[[
	Oil (bible §5.4): barrels float above random open ground across the desert — rare, never on fixed spots — and are
	the only fuel. Driving a car through one adds its fuel to the tank (a full tank leaves it for someone else).
	Services/OilService places and removes them; Controllers/OilController makes them bob and spin.
]]
return {
	MaxBarrels = 18, -- barrels on the whole map at once
	SpawnEvery = 8, -- seconds between new barrels while there are fewer than MaxBarrels
	Lifetime = 240, -- seconds before an untouched barrel disappears (and a new one turns up somewhere else)
	FuelPerBarrel = 30, -- fuel one barrel adds
	PickupRadius = 8, -- studs from a car's middle to a barrel to pick it up
	HoverHeight = 3.5, -- studs above the ground a barrel floats
	BobHeight = 0.6, -- studs it bobs up and down (client only)
	SpinSpeed = 1.2, -- radians per second it turns (client only)
	EdgeMargin = 140, -- studs from the map border kept clear (the edge cliffs)
	CenterClear = 80, -- studs from the middle kept clear (the spawn area)
	Clearance = 5, -- studs around a barrel that must be free of rocks, cacti and buildings
	Tick = 0.1, -- seconds between pickup checks on the server
}
