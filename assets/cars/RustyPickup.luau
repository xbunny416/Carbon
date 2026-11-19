--!strict
--[[
	Rusty Pickup — the free starter car (bible §5.2): a faded teal pickup with rust patches, chrome bumpers, a
	glass cab you can see the driver through and an open bed (oil barrels ride there from 1.4). Front = -Z.
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
	local glass = { Material = "Glass", Transparency = 0.62 }
	local chrome = { Material = "Metal" }
	local rust = { Material = "CorrodedMetal" }

	-- Engine bay, hood and grille
	box("FrontBody", { -2.8, 2.6, -7.9 }, { 2.8, 4.6, -2.6 }, paint)
	box("Hood", { -2.7, 4.6, -7.7 }, { 2.7, 4.95, -2.7 }, paint)
	box("HoodRidge", { -0.5, 4.95, -7.5 }, { 0.5, 5.1, -2.9 }, "PickupPaintDark")
	box("Grille", { -2.1, 2.9, -8.05 }, { 2.1, 4.4, -7.9 }, "Chrome", chrome)
	for _, y in { 3.3, 3.75, 4.15 } do
		box("GrilleBar", { -2, y - 0.08, -8.12 }, { 2, y + 0.08, -8.05 }, "MetalDark")
	end
	for _, x in { -2.35, 2.35 } do
		F.ball({
			Name = "Headlight",
			Center = { x, 3.95, -7.95 },
			Diameter = 0.95,
			Color = "NeonWhite",
			Material = "Neon",
		})
	end
	box("FrontBumper", { -3.3, 2.3, -8.45 }, { 3.3, 3, -7.9 }, "Chrome", chrome)

	-- Cab: doors, pillars, roof, glass, mirrors, dashboard and bench
	box("CabLower", { -2.8, 2.6, -2.6 }, { 2.8, 4.6, 1.6 }, paint)
	for _, side in { -1, 1 } do
		local x = side * 2.82
		box("DoorSeam", { x - 0.03, 2.8, -2.3 }, { x + 0.03, 4.55, -2.2 }, "BedLiner")
		box("DoorSeam", { x - 0.03, 2.8, 1.15 }, { x + 0.03, 4.55, 1.25 }, "BedLiner")
		box("DoorHandle", { x - 0.06, 4.1, 0.4 }, { x + 0.06, 4.3, 0.9 }, "Chrome", chrome)
		box("RunningBoard", { side * 2.8, 2.45, -3.2 }, { side * 3.4, 2.7, 3.2 }, "MetalDark")
		box("APillar", { side * 2.45, 4.6, -2.6 }, { side * 2.75, 7.4, -2.3 }, paint)
		box("BPillar", { side * 2.45, 4.6, 1.2 }, { side * 2.75, 7.4, 1.6 }, paint)
		box("SideWindow", { side * 2.62, 4.75, -2.3 }, { side * 2.7, 7.3, 1.2 }, "Glass", glass)
		box("Mirror", { side * 2.75, 5.4, -2.3 }, { side * 3.4, 6.1, -2 }, "BedLiner")
		for _, z in { -5.2, 5.2 } do
			box("Fender", { side * 2.75, 3.85, z - 1.5 }, { side * 4.3, 4.6, z + 1.5 }, paint)
			for _, ends in { { -2, 0 }, { 2, 180 } } do
				F.part({
					Name = "FenderEnd",
					Shape = "Wedge",
					Size = { 1.55, 0.75, 1 },
					Position = { side * 3.525, 4.225, z + ends[1] },
					Yaw = ends[2],
					Color = paint,
				})
			end
		end
	end
	box("Roof", { -2.75, 7.4, -2.7 }, { 2.75, 7.8, 1.7 }, paint)
	box("Windshield", { -2.45, 4.7, -2.5 }, { 2.45, 7.35, -2.4 }, "Glass", glass)
	box("RearWindow", { -2.45, 4.9, 1.3 }, { 2.45, 7.2, 1.4 }, "Glass", glass)
	box("Dashboard", { -2.5, 4.6, -2.4 }, { 2.5, 5.3, -1.8 }, "BedLiner")
	F.part({
		Name = "SteeringWheel",
		Shape = "Cylinder",
		Size = { 0.2, 1.5, 1.5 },
		Position = { -1.3, 5.5, -1.6 },
		Yaw = 90,
		Rotation = { 0, 0, 20 },
		Color = "BedLiner",
	})
	box("SeatBack", { -2.6, 3.6, 0.7 }, { 2.6, 6.2, 1.2 }, "BedLiner", { Material = "Fabric" })
	box("Antenna", { 2.55, 7.8, -2.6 }, { 2.62, 10.2, -2.53 }, "MetalDark")

	-- Bed
	box("BedBase", { -2.8, 2.6, 1.6 }, { 2.8, 4, 7.9 }, paint)
	box("BedFloor", { -2.5, 4, 1.9 }, { 2.5, 4.1, 7.6 }, "BedLiner")
	for _, side in { -1, 1 } do
		box("BedSide", { side * 2.5, 4, 1.6 }, { side * 2.8, 5.6, 7.9 }, paint)
		box("BedRail", { side * 2.45, 5.6, 1.55 }, { side * 2.85, 5.75, 7.95 }, "MetalDark")
		box("TailLight", { side * 2.3, 4.2, 7.9 }, { side * 2.75, 5.2, 8 }, "TailLight", { Material = "Neon" })
	end
	box("BedFront", { -2.5, 4, 1.6 }, { 2.5, 5.6, 1.9 }, paint)
	box("Tailgate", { -2.5, 4, 7.6 }, { 2.5, 5.6, 7.9 }, paint)
	box("TailgateHandle", { -0.5, 5.1, 7.9 }, { 0.5, 5.3, 7.97 }, "Chrome", chrome)
	box("RearBumper", { -3.2, 2.3, 7.9 }, { 3.2, 3, 8.4 }, "Chrome", chrome)
	box("Plate", { -0.9, 2.95, 8.4 }, { 0.9, 3.6, 8.45 }, "OffWhite")
	F.part({
		Name = "Exhaust",
		Shape = "Cylinder",
		Size = { 1.2, 0.4, 0.4 },
		Position = { 1.9, 2.3, 8.3 },
		Yaw = 90,
		Color = "MetalDark",
	})

	-- Rust patches
	box("Rust", { -2.84, 3, -6.5 }, { -2.81, 3.9, -4.6 }, "Rust", rust)
	box("Rust", { 2.81, 3.1, 3 }, { 2.84, 3.8, 5.2 }, "Rust", rust)
	box("Rust", { 0.8, 4.4, 7.9 }, { 2, 5.2, 7.94 }, "Rust", rust)
	box("Rust", { 1.2, 4.95, -6.8 }, { 2.3, 5, -5.6 }, "Rust", rust)
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
			Cargo = { 0, 4.1, 4.75 },
			Body = body,
		}, prompts)
	end,
}
