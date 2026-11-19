--!strict
--[[
	Rusty Pickup — the free starter car (bible §5.2), in the blocky-parts look (.claude/skills/roblox-blocky-parts-style):
	one long lower body, a wedge-chamfered hood, a narrower cab with a sloped glass windshield and framed rear glass
	(you can see the driver), fender flares over tucked-in wheels, an open bed (oil barrels ride there from 1.4),
	chunky bumpers, light blocks and a couple of rust patches. Muted sage paint. Front = -Z.
]]
local CarKit = require("./CarKit")

local function body(F: any)
	local paint = "PickupPaint"
	local function box(name: string, from: { number }, to: { number }, color: string, extra: { [string]: any }?)
		local spec: { [string]: any } = { Name = name, From = from, To = to, Color = color }
		for key, value in extra or {} do
			spec[key] = value
		end
		return F.box(spec)
	end
	local function wedge(
		name: string,
		size: { number },
		position: { number },
		yaw: number?,
		color: string,
		extra: { [string]: any }?
	)
		local spec: { [string]: any } =
			{ Name = name, Shape = "Wedge", Size = size, Position = position, Yaw = yaw, Color = color }
		for key, value in extra or {} do
			spec[key] = value
		end
		return F.part(spec)
	end
	local glass = { Material = "Glass", Transparency = 0.5 }

	-- Lower body, hood with a chamfered nose, grille, lights and bumper
	box("LowerBody", { -2.8, 2.6, -7.9 }, { 2.8, 4.4, 7.9 }, paint)
	box("Hood", { -2.75, 4.4, -6.6 }, { 2.75, 5, -2.6 }, paint)
	wedge("HoodNose", { 5.5, 0.6, 1.2 }, { 0, 4.7, -7.2 }, nil, paint)
	box("Grille", { -2, 3, -8.05 }, { 2, 4.2, -7.9 }, "Black")
	for _, x in { -2.2, 2.2 } do
		box("Headlight", { x - 0.45, 3.5, -8.05 }, { x + 0.45, 4.2, -7.9 }, "HeadLight")
	end
	box("FrontBumper", { -3.1, 2.4, -8.45 }, { 3.1, 3.2, -7.9 }, "Concrete")

	-- Fender flares over the wheels (chamfered ends) and running boards
	for _, side in { -1, 1 } do
		for _, z in { -5.2, 5.2 } do
			box("Fender", { side * 2.8, 3.7, z - 1.9 }, { side * 4.2, 4.4, z + 1.9 }, paint)
			for _, ends in { { -2.4, 0 }, { 2.4, 180 } } do
				wedge("FenderEnd", { 1.4, 0.7, 1 }, { side * 3.5, 4.05, z + ends[1] }, ends[2], paint)
			end
		end
		box("RunningBoard", { side * 2.8, 2.4, -3.2 }, { side * 3.4, 2.75, 3.2 }, "MetalDark")
		box("DoorLine", { side * 2.8 - 0.05, 2.8, -2.45 }, { side * 2.8 + 0.05, 4.3, -2.3 }, "PickupPaintDark")
	end

	-- Cab: sloped glass windshield between wedge pillars, side glass, roof, framed rear glass, mirrors, inside
	wedge("Windshield", { 5, 2.8, 1.4 }, { 0, 5.8, -1.9 }, nil, "Glass", glass)
	for _, side in { -1, 1 } do
		wedge("APillar", { 0.3, 2.8, 1.4 }, { side * 2.6, 5.8, -1.9 }, nil, paint)
		box("SideWindow", { side * 2.55, 4.5, -1.2 }, { side * 2.7, 7.1, 1.3 }, "Glass", glass)
		box("RearPost", { side * 2, 4.4, 1.3 }, { side * 2.75, 7.2, 1.6 }, paint)
		box("Mirror", { side * 2.75, 5.4, -1.9 }, { side * 3.3, 6, -1.5 }, "BedLiner")
	end
	box("Roof", { -2.75, 7.2, -1.3 }, { 2.75, 7.6, 1.6 }, paint)
	box("RearSill", { -2, 4.4, 1.3 }, { 2, 5, 1.6 }, paint)
	box("RearHeader", { -2, 6.9, 1.3 }, { 2, 7.2, 1.6 }, paint)
	box("RearWindow", { -2, 5, 1.4 }, { 2, 6.9, 1.5 }, "Glass", glass)
	box("Dashboard", { -2.5, 4.4, -2.5 }, { 2.5, 5.1, -1.8 }, "BedLiner")
	F.part({
		Name = "SteeringWheel",
		Shape = "Cylinder",
		Size = { 0.3, 1.4, 1.4 },
		Position = { -1.3, 5.4, -1.5 },
		Yaw = 90,
		Rotation = { 0, 0, 20 },
		Color = "BedLiner",
	})
	box("SeatBack", { -2.4, 3.6, 0.7 }, { 2.4, 6, 1.2 }, "BedLiner", { Material = "Fabric" })

	-- Bed: liner floor, side walls with rail caps, tailgate, rear lights and bumper
	box("BedFloor", { -2.5, 4.4, 1.9 }, { 2.5, 4.5, 7.6 }, "BedLiner")
	for _, side in { -1, 1 } do
		box("BedSide", { side * 2.5, 4.4, 1.6 }, { side * 2.8, 5.8, 7.9 }, paint)
		box("BedRail", { side * 2.45, 5.8, 1.55 }, { side * 2.85, 6.05, 7.95 }, "PickupPaintDark")
		box("TailLight", { side * 2.2, 4.6, 7.9 }, { side * 2.75, 5.5, 8.05 }, "TailLight")
	end
	box("Tailgate", { -2.5, 4.4, 7.6 }, { 2.5, 5.8, 7.9 }, paint)
	box("TailgateCap", { -2.5, 5.8, 7.55 }, { 2.5, 6.05, 7.95 }, "PickupPaintDark")
	box("RearBumper", { -3, 2.4, 7.9 }, { 3, 3.2, 8.4 }, "Concrete")
	F.part({
		Name = "Exhaust",
		Shape = "Cylinder",
		Size = { 1.2, 0.5, 0.5 },
		Position = { 1.9, 2.3, 8.3 },
		Yaw = 90,
		Color = "MetalDark",
	})

	-- Rust patches
	box("Rust", { -2.85, 3, -6.5 }, { -2.8, 3.9, -4.6 }, "Rust", { Material = "CorrodedMetal" })
	box("Rust", { 0.8, 4.6, 7.9 }, { 2, 5.4, 7.95 }, "Rust", { Material = "CorrodedMetal" })
end

return {
	build = function(prompts: any): any
		return CarKit.build({
			Name = "RustyPickup",
			WheelRadius = 1.7,
			WheelWidth = 1.3,
			Track = 3.55,
			Base = 5.2,
			Chassis = { 5.4, 1, 14.6 },
			Seat = { -1.3, 3.3, -0.1 },
			Prompt = { -3.4, 4.6, -0.5 },
			Cargo = { 0, 4.5, 4.75 },
			Body = body,
		}, prompts)
	end,
}
