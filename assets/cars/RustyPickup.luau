--!strict
--[[
	Rusty Pickup — the free starter car (bible §5.2), in the blocky-parts look (.claude/skills/roblox-blocky-parts-style):
	one long lower body, a wedge-chamfered hood, a roomy cab (4 studs of headroom) with a sloped glass windshield and
	framed rear glass (you can see the driver), fender flares over tucked-in wheels, an open bed,
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
	-- Faces stacked toward the front stay 0.05+ apart so nothing flickers: frame -8.0, grille -8.1, bars -8.17.
	box("GrilleFrame", { -1.75, 2.85, -8 }, { 1.75, 4.35, -7.9 }, "Chrome", { Material = "Metal" })
	box("Grille", { -1.5, 3, -8.1 }, { 1.5, 4.2, -7.9 }, "Black")
	for _, x in { -0.75, 0, 0.75 } do
		box("GrilleBar", { x - 0.12, 3.05, -8.17 }, { x + 0.12, 4.15, -8.1 }, "Chrome", { Material = "Metal" })
	end
	for _, x in { -2.2, 2.2 } do
		box("HeadlightBezel", { x - 0.55, 3.4, -8 }, { x + 0.55, 4.3, -7.9 }, "Concrete")
		box("Headlight", { x - 0.42, 3.5, -8.1 }, { x + 0.42, 4.2, -8 }, "HeadLight")
		box("TurnSignal", { x - 0.4, 3.1, -8.05 }, { x + 0.4, 3.35, -7.9 }, "Orange")
	end
	box("FrontBumper", { -3.1, 2.4, -8.45 }, { 3.1, 3, -7.9 }, "Concrete")
	box("BumperGuard", { -1.1, 3, -8.5 }, { 1.1, 3.35, -8.2 }, "MetalDark")

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
		-- Two-tone: a darker rocker stripe low along each side, a door handle, rear mud flaps
		box("RockerStripe", { side * 2.8, 2.6, -3.3 }, { side * 2.88, 2.95, 3.3 }, "PickupPaintDark")
		box("DoorHandle", { side * 2.8, 4.05, 0.5 }, { side * 2.9, 4.25, 1 }, "Chrome", { Material = "Metal" })
		box("MudFlap", { side * 2.95, 2, 7.05 }, { side * 4, 3.4, 7.2 }, "Black", { Material = "Rubber" })
	end

	-- Cab: sloped glass windshield between wedge pillars, side glass, roof, framed rear glass, mirrors, inside
	-- (the glass and the pillars sit side by side, never overlapping: overlapping slopes flicker)
	wedge("Windshield", { 5, 3.4, 1.6 }, { 0, 6.1, -2.2 }, nil, "Glass", glass)
	for _, side in { -1, 1 } do
		wedge("APillar", { 0.3, 3.4, 1.6 }, { side * 2.65, 6.1, -2.2 }, nil, paint)
		box("SideWindow", { side * 2.6, 4.5, -1.4 }, { side * 2.75, 7.7, 1.8 }, "Glass", glass)
		box("RearPost", { side * 2, 4.4, 1.8 }, { side * 2.8, 7.8, 2.1 }, paint)
		box("MirrorArm", { side * 2.75, 5.8, -2.25 }, { side * 3, 5.95, -2.15 }, "MetalDark")
		box("Mirror", { side * 3, 5.6, -2.4 }, { side * 3.4, 6.2, -2 }, "BedLiner")
	end
	box("Roof", { -2.85, 7.8, -1.5 }, { 2.85, 8.2, 2.15 }, paint)
	-- A raised roof panel with beveled front and back edges
	box("RoofPanel", { -2.55, 8.2, -0.9 }, { 2.55, 8.5, 1.55 }, paint)
	wedge("RoofBevel", { 5.1, 0.3, 0.6 }, { 0, 8.35, -1.2 }, nil, paint)
	wedge("RoofBevel", { 5.1, 0.3, 0.6 }, { 0, 8.35, 1.85 }, 180, paint)
	box("RearSill", { -2, 4.4, 1.8 }, { 2, 5, 2.1 }, paint)
	box("RearHeader", { -2, 7.4, 1.8 }, { 2, 7.8, 2.1 }, paint)
	box("RearWindow", { -2, 5, 1.9 }, { 2, 7.4, 2 }, "Glass", glass)
	box("Dashboard", { -2.5, 4.4, -2.8 }, { 2.5, 5.2, -2 }, "BedLiner")
	F.part({
		Name = "SteeringWheel",
		Shape = "Cylinder",
		Size = { 0.3, 1.4, 1.4 },
		Position = { -1.3, 5.5, -1.7 },
		Yaw = 90,
		Rotation = { 0, 0, 20 },
		Color = "BedLiner",
	})
	box("SeatBack", { -2.4, 3.6, 1.2 }, { 2.4, 6.3, 1.7 }, "BedLiner", { Material = "Fabric" })

	-- Bed: liner floor, side walls with rail caps, tailgate, rear lights and bumper
	box("BedFloor", { -2.5, 4.4, 2.4 }, { 2.5, 4.5, 7.6 }, "BedLiner")
	for _, side in { -1, 1 } do
		box("BedSide", { side * 2.5, 4.4, 2.1 }, { side * 2.8, 5.8, 7.9 }, paint)
		box("BedRail", { side * 2.45, 5.8, 2.05 }, { side * 2.85, 6.05, 7.95 }, "PickupPaintDark")
		box("TailLight", { side * 2.2, 4.6, 7.9 }, { side * 2.75, 5.5, 8.05 }, "TailLight")
	end
	box("Tailgate", { -2.5, 4.4, 7.6 }, { 2.5, 5.8, 7.9 }, paint)
	box("TailgateCap", { -2.5, 5.8, 7.55 }, { 2.5, 6.05, 7.95 }, "PickupPaintDark")
	box("TailgatePanel", { -1.9, 4.65, 7.9 }, { 1.9, 5.45, 7.98 }, "PickupPaintDark")
	box("TailgateHandle", { -0.5, 5.15, 7.98 }, { 0.5, 5.35, 8.06 }, "Chrome", { Material = "Metal" })
	box("RearBumper", { -3, 2.4, 7.9 }, { 3, 3.2, 8.4 }, "Concrete")
	box("Hitch", { -0.3, 2.5, 8.4 }, { 0.3, 2.8, 9 }, "MetalDark")
	box("HitchBall", { -0.25, 2.8, 8.65 }, { 0.25, 3.2, 8.95 }, "Chrome", { Material = "Metal" })
	-- In the bed: a spare tire leaning on the cab and a red toolbox
	F.part({
		Name = "SpareTire",
		Shape = "Cylinder",
		Size = { 1, 3, 3 },
		Position = { -1.2, 6, 2.95 },
		Yaw = 90,
		Color = "Black",
		Material = "Rubber",
	})
	F.part({
		Name = "SpareRim",
		Shape = "Cylinder",
		Size = { 1.1, 1.6, 1.6 },
		Position = { -1.2, 6, 2.95 },
		Yaw = 90,
		Color = "MetalDark",
	})
	box("Toolbox", { 0.6, 4.5, 2.5 }, { 2.3, 5.5, 3.5 }, "Red")
	box("ToolboxLid", { 0.5, 5.5, 2.45 }, { 2.4, 5.7, 3.55 }, "MetalDark")
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
	box("Rust", { 2.8, 4.6, 5.4 }, { 2.86, 5.3, 6.8 }, "Rust", { Material = "CorrodedMetal" })
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
			Body = body,
		}, prompts)
	end,
}
