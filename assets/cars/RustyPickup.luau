--!strict
--[[
	Rusty Pickup — the free starter car (bible §5.2), in the blocky-parts look (.claude/skills/roblox-blocky-parts-style).
	A long pickup (wheelbase 11.4) with a tall, proud front end: a raised hood with a beveled nose and a center ridge,
	a tall chrome-framed grille, headlights in bezels up high and taller front flares. A roomy cab with a high belt
	line, a sloped glass windshield and framed rear glass (you can see the driver), an open bed with a spare tire and a
	toolbox, chunky bumpers, a tow hitch, a darker rocker stripe and a couple of rust patches. Muted sage paint.
	Front = -Z. Faces stacked on top of each other stay 0.05+ studs apart, and wedges that share a slope sit side by
	side, never overlapping (both flicker otherwise).
]]
local CarKit = require("./CarKit")

local FRONT, REAR = -8.9, 8.9 -- body front and rear faces
local BASE = 5.7 -- wheel centers at z = ±BASE
local CAB_FRONT, CAB_BACK = -2.6, 2.1 -- the cab between the hood and the bed
local BELT = 5 -- top of the cab's lower body (where the side glass starts)
local HOOD = 5.6 -- top of the hood

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
	local chrome = { Material = "Metal" }

	-- Front end: a tall front clip, raised hood with a beveled nose and a ridge, grille, lights, bumper
	box("FrontBody", { -2.8, 2.6, FRONT }, { 2.8, HOOD - 0.4, CAB_FRONT }, paint)
	box("Hood", { -2.75, HOOD - 0.4, FRONT + 0.6 }, { 2.75, HOOD, CAB_FRONT }, paint)
	wedge("HoodNose", { 5.5, 0.4, 0.6 }, { 0, HOOD - 0.2, FRONT + 0.3 }, nil, paint)
	box("HoodRidge", { -0.6, HOOD, FRONT + 0.9 }, { 0.6, HOOD + 0.15, CAB_FRONT - 0.3 }, "PickupPaintDark")
	box("GrilleFrame", { -1.75, 3, FRONT - 0.1 }, { 1.75, 4.95, FRONT }, "Chrome", chrome)
	box("Grille", { -1.5, 3.15, FRONT - 0.2 }, { 1.5, 4.8, FRONT }, "Black")
	for _, x in { -0.75, 0, 0.75 } do
		box("GrilleBar", { x - 0.12, 3.2, FRONT - 0.27 }, { x + 0.12, 4.75, FRONT - 0.2 }, "Chrome", chrome)
	end
	for _, x in { -2.25, 2.25 } do
		box("HeadlightBezel", { x - 0.5, 3.9, FRONT - 0.1 }, { x + 0.5, 4.8, FRONT }, "Concrete")
		box("Headlight", { x - 0.38, 4, FRONT - 0.2 }, { x + 0.38, 4.7, FRONT - 0.1 }, "HeadLight")
		box("TurnSignal", { x - 0.4, 3.45, FRONT - 0.15 }, { x + 0.4, 3.7, FRONT }, "Orange")
	end
	box("FrontBumper", { -3.1, 2.4, FRONT - 0.55 }, { 3.1, 3.1, FRONT }, "Concrete")
	box("BumperGuard", { -1.1, 3.1, FRONT - 0.6 }, { 1.1, 3.45, FRONT - 0.3 }, "MetalDark")

	-- Cab lower body (to the belt line) and the bed's lower body
	box("CabBody", { -2.8, 2.6, CAB_FRONT }, { 2.8, BELT, CAB_BACK }, paint)
	box("BedBody", { -2.8, 2.6, CAB_BACK }, { 2.8, 4.4, REAR }, paint)

	-- Fender flares over the wheels (taller in front, chamfered ends), running boards, stripe, handles, mud flaps
	for _, side in { -1, 1 } do
		for _, axle in { { -BASE, 3.9, 0.8 }, { BASE, 3.7, 0.7 } } do
			local z, bottom, height = axle[1], axle[2], axle[3]
			box("Fender", { side * 2.8, bottom, z - 1.9 }, { side * 4.2, bottom + height, z + 1.9 }, paint)
			for _, ends in { { -2.4, 0 }, { 2.4, 180 } } do
				wedge("FenderEnd", { 1.4, height, 1 }, { side * 3.5, bottom + height / 2, z + ends[1] }, ends[2], paint)
			end
		end
		box("RunningBoard", { side * 2.8, 2.4, -3.7 }, { side * 3.4, 2.75, 3.7 }, "MetalDark")
		box("RockerStripe", { side * 2.8, 2.6, -3.8 }, { side * 2.88, 2.95, 3.8 }, "PickupPaintDark")
		box(
			"DoorLine",
			{ side * 2.8 - 0.05, 2.8, CAB_FRONT + 0.15 },
			{ side * 2.8 + 0.05, BELT - 0.1, CAB_FRONT + 0.3 },
			"PickupPaintDark"
		)
		box("DoorHandle", { side * 2.8, 4.55, 0.5 }, { side * 2.9, 4.75, 1 }, "Chrome", chrome)
		box("MudFlap", { side * 2.95, 2, BASE + 1.85 }, { side * 4, 3.4, BASE + 2 }, "Black", { Material = "Rubber" })
	end

	-- Cab top: sloped glass windshield between wedge pillars, side glass, roof with a beveled panel, framed rear
	-- glass, mirrors on arms, and inside a dashboard, steering wheel and bench
	wedge("Windshield", { 5, 2.8, 1.4 }, { 0, BELT + 1.4, CAB_FRONT + 0.7 }, nil, "Glass", glass)
	for _, side in { -1, 1 } do
		wedge("APillar", { 0.3, 2.8, 1.4 }, { side * 2.65, BELT + 1.4, CAB_FRONT + 0.7 }, nil, paint)
		box("SideWindow", { side * 2.6, BELT + 0.05, -1.2 }, { side * 2.75, 7.7, CAB_BACK - 0.3 }, "Glass", glass)
		box("RearPost", { side * 2, BELT, CAB_BACK - 0.3 }, { side * 2.8, 7.8, CAB_BACK }, paint)
		box("MirrorArm", { side * 2.8, 6.2, -2 }, { side * 3.05, 6.35, -1.9 }, "MetalDark")
		box("Mirror", { side * 3.05, 6, -2.15 }, { side * 3.45, 6.6, -1.75 }, "BedLiner")
	end
	box("Roof", { -2.85, 7.8, -1.3 }, { 2.85, 8.2, CAB_BACK + 0.05 }, paint)
	box("RoofPanel", { -2.55, 8.2, -0.7 }, { 2.55, 8.5, CAB_BACK - 0.55 }, paint)
	wedge("RoofBevel", { 5.1, 0.3, 0.6 }, { 0, 8.35, -1 }, nil, paint)
	wedge("RoofBevel", { 5.1, 0.3, 0.6 }, { 0, 8.35, CAB_BACK - 0.25 }, 180, paint)
	box("RearSill", { -2, BELT, CAB_BACK - 0.3 }, { 2, BELT + 0.4, CAB_BACK }, paint)
	box("RearHeader", { -2, 7.4, CAB_BACK - 0.3 }, { 2, 7.8, CAB_BACK }, paint)
	box("RearWindow", { -2, BELT + 0.4, CAB_BACK - 0.2 }, { 2, 7.4, CAB_BACK - 0.1 }, "Glass", glass)
	box("Dashboard", { -2.5, BELT, -2 }, { 2.5, BELT + 0.6, -1.4 }, "BedLiner")
	F.part({
		Name = "SteeringWheel",
		Shape = "Cylinder",
		Size = { 0.3, 1.4, 1.4 },
		Position = { -1.3, 5.9, -1.1 },
		Yaw = 90,
		Rotation = { 0, 0, 20 },
		Color = "BedLiner",
	})
	box("SeatBack", { -2.4, 3.6, 1.2 }, { 2.4, 6.3, 1.7 }, "BedLiner", { Material = "Fabric" })

	-- Bed: front wall, liner floor, side walls with rail caps, tailgate, rear lights, bumper and hitch
	box("BedFront", { -2.5, 4.4, CAB_BACK }, { 2.5, 5.8, CAB_BACK + 0.3 }, paint)
	box("BedFloor", { -2.5, 4.4, CAB_BACK + 0.3 }, { 2.5, 4.5, REAR - 0.3 }, "BedLiner")
	for _, side in { -1, 1 } do
		box("BedSide", { side * 2.5, 4.4, CAB_BACK }, { side * 2.8, 5.8, REAR }, paint)
		box("BedRail", { side * 2.45, 5.8, CAB_BACK - 0.05 }, { side * 2.85, 6.05, REAR + 0.05 }, "PickupPaintDark")
		box("TailLight", { side * 2.2, 4.6, REAR }, { side * 2.75, 5.5, REAR + 0.15 }, "TailLight")
	end
	box("Tailgate", { -2.5, 4.4, REAR - 0.3 }, { 2.5, 5.8, REAR }, paint)
	box("TailgateCap", { -2.5, 5.8, REAR - 0.35 }, { 2.5, 6.05, REAR + 0.05 }, "PickupPaintDark")
	box("TailgatePanel", { -1.9, 4.65, REAR }, { 1.9, 5.45, REAR + 0.08 }, "PickupPaintDark")
	box("TailgateHandle", { -0.5, 5.15, REAR + 0.08 }, { 0.5, 5.35, REAR + 0.16 }, "Chrome", chrome)
	box("RearBumper", { -3, 2.4, REAR }, { 3, 3.2, REAR + 0.5 }, "Concrete")
	box("Hitch", { -0.3, 2.5, REAR + 0.5 }, { 0.3, 2.8, REAR + 1.1 }, "MetalDark")
	box("HitchBall", { -0.25, 2.8, REAR + 0.75 }, { 0.25, 3.2, REAR + 1.05 }, "Chrome", chrome)
	F.part({
		Name = "Exhaust",
		Shape = "Cylinder",
		Size = { 1.2, 0.5, 0.5 },
		Position = { 1.9, 2.3, REAR + 0.4 },
		Yaw = 90,
		Color = "MetalDark",
	})
	-- In the bed: a spare tire leaning on the front wall and a red toolbox
	for _, part in
		{
			{ "SpareTire", { 1, 3, 3 }, "Black", "Rubber" },
			{ "SpareRim", { 1.1, 1.6, 1.6 }, "MetalDark", "Metal" },
		}
	do
		F.part({
			Name = part[1],
			Shape = "Cylinder",
			Size = part[2],
			Position = { -1.2, 6, CAB_BACK + 0.85 },
			Yaw = 90,
			Color = part[3],
			Material = part[4],
		})
	end
	box("Toolbox", { 0.6, 4.5, CAB_BACK + 0.4 }, { 2.3, 5.5, CAB_BACK + 1.4 }, "Red")
	box("ToolboxLid", { 0.5, 5.5, CAB_BACK + 0.35 }, { 2.4, 5.7, CAB_BACK + 1.45 }, "MetalDark")

	-- Rust patches
	box("Rust", { -2.85, 3, FRONT + 0.4 }, { -2.8, 3.7, FRONT + 1.2 }, "Rust", { Material = "CorrodedMetal" })
	box("Rust", { 2.8, 4.6, 6 }, { 2.86, 5.3, 7.4 }, "Rust", { Material = "CorrodedMetal" })
end

return {
	-- `stats` is the car's Config.Cars.Models entry (tire grip lives there).
	build = function(prompts: any, stats: any): any
		return CarKit.build({
			Name = "RustyPickup",
			WheelRadius = 1.7,
			WheelWidth = 1.3,
			Track = 3.55,
			Base = BASE,
			Chassis = { 5.4, 1, BASE * 2 + 5.2 },
			Seat = { -1.3, 3.3, -0.1 },
			Prompt = { -3.4, 4.6, -0.5 },
			FrontTireFriction = stats.FrontTireFriction,
			RearTireFriction = stats.RearTireFriction,
			Body = body,
		}, prompts)
	end,
}
