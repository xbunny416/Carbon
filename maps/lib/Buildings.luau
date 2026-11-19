--!strict
--[[
	Buildings — the town's buildings for CarOff (maps/layouts/Town.luau places them), in the blocky-parts look
	(.claude/skills/roblox-blocky-parts-style): chunky boxes, wedge bevels and gable roofs, muted colors, built-in
	materials, medium detail (frames, trims, ledges; no tiny bits), Neon only on real lights.
	Each one is built in a Props frame: `at` is its anchor on the ground, local -Z is its front, `yaw` turns it (see
	Props.frame). Sign text comes from GameStrings keys.
]]
local B = require("./Builder")
local Props = require("./Props")

type Vec = B.Vec
type Frame = Props.Frame

local Buildings = {}

-- A box between two corners with a color and (optional) material.
local function box(
	F: Frame,
	name: string,
	from: Vec,
	to: Vec,
	color: string,
	material: string?,
	extra: { [string]: any }?
)
	local spec: { [string]: any } = { Name = name, From = from, To = to, Color = color, Material = material }
	for key, value in extra or {} do
		spec[key] = value
	end
	return F.box(spec)
end

--[[
	A gable roof over x0..x1 / z0..z1 starting at height `y`: two wedges rising `rise` studs to a ridge along X in
	the middle, plus a darker ridge cap. Its triangular ends close the gables.
]]
local function gable(
	F: Frame,
	x0: number,
	x1: number,
	z0: number,
	z1: number,
	y: number,
	rise: number,
	color: string,
	material: string
)
	local half = (z1 - z0) / 2
	for _, side in { { z0 + half / 2, 0 }, { z1 - half / 2, 180 } } do
		F.part({
			Name = "Roof",
			Shape = "Wedge",
			Size = { x1 - x0, rise, half },
			Position = { (x0 + x1) / 2, y + rise / 2, side[1] },
			Yaw = side[2],
			Color = color,
			Material = material,
			CastShadow = true,
		})
	end
	local mid = (z0 + z1) / 2
	box(
		F,
		"RidgeCap",
		{ x0 - 0.2, y + rise - 0.3, mid - 0.5 },
		{ x1 + 0.2, y + rise + 0.3, mid + 0.5 },
		"RoofDark",
		material
	)
end

-- A window on a solid wall facing -Z at `z`: a trim frame and an opaque dark pane set in it, with a ledge below.
local function wallWindow(F: Frame, x0: number, x1: number, y0: number, y1: number, z: number)
	box(F, "WindowFrame", { x0, y0, z - 0.25 }, { x1, y1, z }, "Concrete")
	box(F, "Window", { x0 + 0.4, y0 + 0.4, z - 0.4 }, { x1 - 0.4, y1 - 0.4, z - 0.25 }, "WindowDark")
	box(F, "Ledge", { x0 - 0.2, y0 - 0.35, z - 0.6 }, { x1 + 0.2, y0, z }, "ConcreteLight", "Concrete")
end

--[[
	The motel: a two-floor row of 8 rooms (framed doors and windows, wall AC units) on a brick base, a balcony walkway
	with a solid half-wall railing and posts, stairs at the right end, a flat roof with a beveled teal fascia, and an
	office with a glass front and a gable roof on the left. Anchor: the middle of the front wall. Players spawn on the
	welcome mats in front of the middle rooms (returns how many).
]]
function Buildings.motel(at: Vec, yaw: number): number
	local F = Props.frame(at, yaw)
	local spawns = 0
	B.model("Motel", function()
		box(F, "Walkway", { -78, -1, -9 }, { 82, 0.6, 22 }, "Concrete", "Concrete")
		box(F, "Curb", { -78, -1, -9.6 }, { 82, 0.8, -9 }, "ConcreteLight", "Concrete")

		-- Office: hollow (walk in through the glass door), counter inside, gable roof
		B.model("Office", function()
			for _, wall in
				{
					{ { -75, 0.6, 19 }, { -53, 12, 20 } },
					{ { -75, 0.6, -1 }, { -74, 12, 19 } },
					{ { -54, 0.6, -1 }, { -53, 12, 19 } },
					{ { -74, 8.6, -1 }, { -54, 12, 0 } },
					{ { -59, 0.6, -1 }, { -58, 8.6, 0 } },
				}
			do
				box(F, "Wall", wall[1], wall[2], "Stucco", "Plaster", { CastShadow = true })
			end
			box(F, "Sill", { -74, 0.6, -1 }, { -59, 2.2, 0 }, "Brick", "Brick")
			box(F, "SillLedge", { -74.2, 2.2, -1.3 }, { -58.8, 2.5, 0 }, "ConcreteLight", "Concrete")
			box(F, "Window", { -74, 2.5, -0.6 }, { -59, 8.6, -0.4 }, "Glass", "Glass", { Transparency = 0.5 })
			for _, x in { -69, -64 } do
				box(F, "Mullion", { x - 0.2, 2.5, -0.75 }, { x + 0.2, 8.5, -0.25 }, "OffWhite")
			end
			box(
				F,
				"Door",
				{ -58, 0.6, -0.6 },
				{ -54, 8.6, -0.4 },
				"Glass",
				"Glass",
				{ Transparency = 0.5, CanCollide = false }
			)
			box(F, "DoorHeader", { -58.3, 8.6, -1.3 }, { -53.7, 9.1, 0 }, "Concrete")
			F.sign({
				Name = "OfficeSign",
				Size = { 13, 2.2, 0.3 },
				Position = { -66, 10.4, -1.15 },
				Color = "MotelTeal",
				Key = "Map.Motel.Office",
				TextColor = "OffWhite",
			})
			gable(F, -76, -53, -3, 21, 12, 4.5, "RoofBrown", "RoofShingles")
			box(F, "Counter", { -71, 0.6, 5 }, { -60, 4.2, 7.5 }, "Wood", "WoodPlanks")
			box(F, "CounterTop", { -71.3, 4.2, 4.7 }, { -59.7, 4.6, 7.8 }, "WoodDark", "Wood")
			box(F, "KeyBoard", { -69, 5, 18.6 }, { -62, 9, 19 }, "WoodDark", "Wood")
			box(F, "Rug", { -72, 0.6, -0.2 }, { -60, 0.7, 4 }, "MotelPink", "Fabric")
			box(F, "CeilingLight", { -68, 11.7, 6 }, { -62, 12, 10 }, "NeonWhite", "Neon")
		end)

		-- Rooms: one solid block on a brick base, dressed with framed doors and windows on both floors
		box(F, "Rooms", { -53, 0.6, 0 }, { 75, 22.6, 20 }, "Stucco", "Plaster", { CastShadow = true })
		box(F, "Base", { -53.15, 0.6, -0.15 }, { 75.15, 1.6, 20.15 }, "Brick", "Brick")
		for floor = 0, 1 do
			local fy = 0.6 + floor * 11
			for room = 0, 8 do
				local x = -53 + room * 16
				box(F, "Pilaster", { x - 0.4, fy, -0.3 }, { x + 0.4, fy + 10, 0 }, "OffWhite")
			end
			for room = 0, 7 do
				local xc = -53 + room * 16 + 8
				local doorColor = if room % 2 == 0 then "MotelTeal" else "MotelPink"
				box(F, "DoorFrame", { xc - 5.4, fy, -0.25 }, { xc - 1, fy + 8.1, 0 }, "Concrete")
				box(F, "Door", { xc - 5, fy, -0.4 }, { xc - 1.4, fy + 7.6, -0.25 }, doorColor)
				wallWindow(F, xc + 0.3, xc + 6.5, fy + 2.9, fy + 7.5, 0)
				if floor == 0 then
					box(F, "AC", { xc + 2, fy + 1.2, -1.3 }, { xc + 5, fy + 2.4, -0.15 }, "Metal")
				end
				if floor == 0 and room >= 2 and room <= 5 then
					spawns += 1
					F.spawn({
						Name = `SpawnMat{spawns}`,
						Size = { 5, 0.2, 3 },
						Position = { xc - 3.2, 0.7, -2.5 },
						Color = "MotelPink",
						Material = "Fabric",
					})
				end
			end
		end

		-- Balcony walkway on posts, with a solid half-wall railing
		box(F, "Balcony", { -53, 10.6, -7 }, { 82, 11.6, 0 }, "Concrete", "Concrete")
		box(F, "BalconyTrim", { -53, 10.3, -7.3 }, { 82, 11.7, -7 }, "MotelTeal")
		for room = 0, 8 do
			local x = -53 + room * 16
			box(F, "Post", { x - 0.4, 0.6, -6.9 }, { x + 0.4, 10.6, -6.1 }, "OffWhite")
		end
		box(F, "Post", { 81, 0.6, -6.9 }, { 81.8, 10.6, -6.1 }, "OffWhite")
		box(F, "Railing", { -53, 11.6, -7 }, { 82, 14.2, -6.6 }, "Stucco", "Plaster")
		box(F, "RailingCap", { -53.2, 14.2, -7.2 }, { 82.2, 14.6, -6.4 }, "MotelTeal")
		box(F, "Railing", { 81.6, 11.6, -6.6 }, { 82, 14.2, 0 }, "Stucco", "Plaster")
		box(F, "RailingCap", { 81.4, 14.2, -6.4 }, { 82.2, 14.6, 0 }, "MotelTeal")

		-- Flat roof with an overhang, a teal fascia beveled on top, and AC units
		box(F, "Roof", { -54, 22.6, -8 }, { 76, 23.6, 21 }, "RoofDark", "Slate", { CastShadow = true })
		box(F, "Fascia", { -54, 22.2, -8.6 }, { 76, 23.6, -8 }, "MotelTeal")
		F.part({
			Name = "FasciaBevel",
			Shape = "Wedge",
			Size = { 130, 0.8, 2 },
			Position = { 11, 24, -7.6 },
			Color = "MotelTeal",
		})
		for _, x in { -30, 10, 50 } do
			box(F, "RoofAC", { x - 3, 23.6, 6 }, { x + 3, 26.4, 12 }, "Metal", "Metal")
			box(F, "RoofACTop", { x - 2.4, 26.4, 6.6 }, { x + 2.4, 26.8, 11.4 }, "MetalDark")
		end

		-- Stairs at the right end, from the back up to the balcony, with a sloped side wall
		for step = 1, 11 do
			local z0 = (11 - step) * 1.8
			box(F, "Step", { 76, 0.6, z0 }, { 80, 0.6 + step, z0 + 1.8 }, "Concrete", "Concrete")
		end
		F.part({
			Name = "StairWall",
			Shape = "Wedge",
			Size = { 0.6, 11, 19.8 },
			Position = { 80.3, 6.1, 9.9 },
			Yaw = 180,
			Color = "Stucco",
			Material = "Plaster",
		})

		-- Vending machine (lit front) and brick planters on the walkway
		box(F, "Vending", { 69.5, 0.6, -3.6 }, { 73.5, 7.6, -0.6 }, "GasRed")
		box(F, "VendingFront", { 70, 2.6, -3.75 }, { 73, 7, -3.6 }, "NeonWhite", "Neon")
		for _, x in { -50, 66 } do
			box(F, "Planter", { x - 1.5, 0.6, -5 }, { x + 1.5, 2.4, -2 }, "Brick", "Brick")
			box(F, "Cactus", { x - 0.6, 2.4, -4.1 }, { x + 0.6, 4.6, -2.9 }, "Cactus")
		end
	end)
	return spawns
end

-- The motel's pylon sign: a lit MOTEL board, an arrow and a VACANCY board, readable from both sides.
function Buildings.motelSign(at: Vec, yaw: number)
	local F = Props.frame(at, yaw)
	B.model("MotelSign", function()
		box(F, "Base", { -5.5, -0.5, -1.5 }, { 5.5, 1.5, 1.5 }, "Brick", "Brick")
		for _, x in { -3.9, 3.9 } do
			box(F, "Post", { x - 0.6, 1.5, -0.6 }, { x + 0.6, 29.4, 0.6 }, "MetalDark", "Metal")
		end
		local board = box(F, "Board", { -9, 20, -1 }, { 9, 28, 1 }, "MotelTeal")
		B.light(board, "WarmLight", 24, 1)
		box(F, "BoardCap", { -9.4, 28, -1.3 }, { 9.4, 28.6, 1.3 }, "RoofDark")
		box(F, "VacancyBoard", { -6, 12.5, -0.6 }, { 6, 15.5, 0.6 }, "Black")
		for _, face in { 0, 180 } do
			local z = if face == 0 then -1.15 else 1.15
			F.sign({
				Name = "MotelText",
				Size = { 16, 6, 0.3 },
				Position = { 0, 24, z },
				Yaw = face,
				Color = "MotelTeal",
				Key = "Map.Motel.Sign",
				TextColor = "OffWhite",
				Glow = true,
			})
			F.sign({
				Name = "VacancyText",
				Size = { 11, 2.4, 0.2 },
				Position = { 0, 14, if face == 0 then -0.7 else 0.7 },
				Yaw = face,
				Color = "Black",
				Key = "Map.Motel.Vacancy",
				TextColor = "Yellow",
				Glow = true,
			})
		end
		box(F, "Arrow", { -12, 16.6, -0.5 }, { 6, 18.4, 0.5 }, "Orange")
		for _, tip in { { 18.7, { 0, 0, 0 } }, { 16.3, { 0, 0, 180 } } } do
			F.part({
				Name = "ArrowTip",
				Shape = "Wedge",
				Size = { 1, 2.4, 4 },
				Position = { -14, tip[1], 0 },
				Yaw = 90,
				Rotation = tip[2],
				Color = "Orange",
			})
		end
	end)
end

-- A fenced pool deck with lounge chairs (wedge backrests) and a pitched umbrella. Anchor: the middle of the deck.
function Buildings.pool(at: Vec, yaw: number)
	local F = Props.frame(at, yaw)
	B.model("Pool", function()
		for _, deck in
			{
				{ { -18, -0.5, -14 }, { 18, 1.2, -8 } },
				{ { -18, -0.5, 8 }, { 18, 1.2, 14 } },
				{ { -18, -0.5, -8 }, { -13, 1.2, 8 } },
				{ { 13, -0.5, -8 }, { 18, 1.2, 8 } },
			}
		do
			box(F, "Deck", deck[1], deck[2], "ConcreteLight", "Concrete")
		end
		box(F, "Water", { -13, -0.5, -8 }, { 13, 0.8, 8 }, "PoolWater", nil, { Transparency = 0.25 })
		for _, coping in
			{
				{ { -13.6, 1.2, -8.6 }, { 13.6, 1.5, -8 } },
				{ { -13.6, 1.2, 8 }, { 13.6, 1.5, 8.6 } },
				{ { -13.6, 1.2, -8 }, { -13, 1.5, 8 } },
				{ { 13, 1.2, -8 }, { 13.6, 1.5, 8 } },
			}
		do
			box(F, "Coping", coping[1], coping[2], "OffWhite")
		end
		for _, x in { 10.6, 12 } do
			box(F, "LadderRail", { x - 0.15, 0.8, -7.8 }, { x + 0.15, 3.6, -7.5 }, "Chrome", "Metal")
		end
		for index, x in { -9, -3, 3 } do
			local cushion = if index % 2 == 0 then "MotelPink" else "MotelTeal"
			box(F, "Lounger", { x - 1.1, 1.2, 9.2 }, { x + 1.1, 2, 13 }, "OffWhite")
			box(F, "Cushion", { x - 1, 2, 9.4 }, { x + 1, 2.3, 11.4 }, cushion, "Fabric")
			F.part({
				Name = "Backrest",
				Shape = "Wedge",
				Size = { 2.2, 1.6, 2 },
				Position = { x, 2.8, 12.4 },
				Color = cushion,
				Material = "Fabric",
			})
		end
		box(F, "UmbrellaPole", { 8.8, 1.2, 10.8 }, { 9.2, 8.6, 11.2 }, "OffWhite")
		for _, side in { { 9.25, 0 }, { 12.75, 180 } } do
			F.part({
				Name = "Umbrella",
				Shape = "Wedge",
				Size = { 7, 1.4, 3.5 },
				Position = { 9, 9.3, side[1] },
				Yaw = side[2],
				Color = "MotelPink",
				Material = "Fabric",
			})
		end
		local corners = { F.at(-18, 1.2, -14), F.at(18, 1.2, -14), F.at(18, 1.2, 14), F.at(-18, 1.2, 14) }
		for index = 1, 3 do
			Props.fence(corners[index], corners[index + 1], 4, 4, "OffWhite")
		end
		Props.fence(corners[4], F.at(-18, 1.2, 4), 4, 4, "OffWhite")
	end)
end

--[[
	The gas station: a canopy (red fascia, glowing light panels) over 3 pump islands — 6 pump bays, one on each side
	of every island, tagged PumpBay — a shop with a glass front on a brick base and a wedge awning, and two oil
	storage tanks. Anchor: the middle of the canopy; cars pull in heading +Z (the frame's back).
]]
function Buildings.gasStation(at: Vec, yaw: number)
	local F = Props.frame(at, yaw)
	local bays = 0
	B.model("GasStation", function()
		box(F, "Pad", { -66, -0.5, -28 }, { 66, 0.3, 28 }, "Concrete", "Concrete")

		for _, ix in { -40, 0, 40 } do
			B.model("PumpIsland", function()
				box(F, "Island", { ix - 2.5, 0.3, -14 }, { ix + 2.5, 1.1, 14 }, "ConcreteLight", "Concrete")
				for _, z in { -15.5, 15.5 } do
					box(F, "Bollard", { ix - 0.5, 0.3, z - 0.5 }, { ix + 0.5, 3.7, z + 0.5 }, "Yellow")
				end
				for _, z in { -6, 6 } do
					box(F, "Pump", { ix - 1.2, 1.1, z - 1.6 }, { ix + 1.2, 7.1, z + 1.6 }, "OffWhite")
					box(F, "Hood", { ix - 1.35, 7.1, z - 1.75 }, { ix + 1.35, 8.3, z + 1.75 }, "GasRed")
					box(F, "Display", { ix - 1.3, 5, z - 1 }, { ix + 1.3, 6.4, z + 1 }, "Black")
					box(F, "Stripe", { ix - 1.32, 2, z - 1.72 }, { ix + 1.32, 2.4, z + 1.72 }, "GasRed")
					box(F, "Holster", { ix - 1.6, 3, z + 0.3 }, { ix + 1.6, 4.2, z + 1.2 }, "Black")
				end
				box(F, "Bin", { ix - 0.8, 1.1, 9.7 }, { ix + 0.8, 4, 11.3 }, "MetalDark")
				for _, z in { -11, 11 } do
					box(F, "Column", { ix - 0.9, 1.1, z - 0.9 }, { ix + 0.9, 16, z + 0.9 }, "OffWhite")
					box(F, "ColumnBase", { ix - 1.1, 1.1, z - 1.1 }, { ix + 1.1, 3, z + 1.1 }, "GasRed")
				end
				for _, side in { -1, 1 } do
					local bx = ix + side * 9
					bays += 1
					F.marker("PumpBay", `PumpBay{bays}`, { bx, 0.3, 0 }, { Index = bays }, 180)
					local panel = box(F, "CanopyLight", { bx - 2, 15.8, -8 }, { bx + 2, 16, 8 }, "NeonWhite", "Neon")
					if side == 1 then
						B.light(panel, "WarmLight", 26, 1)
					end
				end
			end)
		end

		box(F, "Canopy", { -62, 16, -25 }, { 62, 18.5, 25 }, "OffWhite", nil, { CastShadow = true })
		for _, z in { -25.2, 25.2 } do
			box(F, "Fascia", { -62.4, 15.6, z - 0.2 }, { 62.4, 19.4, z + 0.2 }, "GasRed")
			box(F, "Stripe", { -62.6, 17.2, z - 0.3 }, { 62.6, 17.8, z + 0.3 }, "OffWhite")
		end
		for _, x in { -62.2, 62.2 } do
			box(F, "Fascia", { x - 0.2, 15.6, -25 }, { x + 0.2, 19.4, 25 }, "GasRed")
		end

		-- Shop: hollow, glass front on a brick base, shelves and a lit cooler inside
		B.model("Shop", function()
			box(F, "Floor", { -36, -0.5, 39 }, { 36, 0.3, 71 }, "ConcreteLight", "Concrete")
			for _, wall in
				{
					{ { -35, 0.3, 69 }, { 35, 13, 70 } },
					{ { -35, 0.3, 40 }, { -34, 13, 69 } },
					{ { 34, 0.3, 40 }, { 35, 13, 69 } },
					{ { -34, 9, 40 }, { 34, 13, 41 } },
					{ { -34, 2, 40 }, { -32, 9, 41 } },
					{ { -4, 2, 40 }, { -3.5, 9, 41 } },
					{ { 3.5, 2, 40 }, { 4, 9, 41 } },
					{ { 32, 2, 40 }, { 34, 9, 41 } },
				}
			do
				box(F, "Wall", wall[1], wall[2], "Stucco", "Plaster", { CastShadow = true })
			end
			for _, base in { { -34, -3.5 }, { 3.5, 34 } } do
				box(F, "BrickBase", { base[1], 0.3, 40 }, { base[2], 2, 41 }, "Brick", "Brick")
				box(F, "SillLedge", { base[1], 2, 39.7 }, { base[2], 2.3, 41 }, "ConcreteLight", "Concrete")
			end
			for _, x in { -18, 18 } do
				box(F, "Window", { x - 14, 2.3, 40.4 }, { x + 14, 9, 40.6 }, "Glass", "Glass", { Transparency = 0.45 })
			end
			box(
				F,
				"Door",
				{ -3.5, 0.3, 40.4 },
				{ 3.5, 9, 40.6 },
				"Glass",
				"Glass",
				{ Transparency = 0.5, CanCollide = false }
			)
			box(F, "DoorFrame", { -0.15, 0.3, 40.3 }, { 0.15, 8.9, 40.7 }, "Chrome", nil, { CanCollide = false })
			box(F, "Roof", { -36, 13, 39 }, { 36, 14, 71 }, "RoofDark", "Slate")
			box(F, "Parapet", { -36.2, 12, 38.6 }, { 36.2, 15.5, 39.4 }, "GasRed")
			F.sign({
				Name = "ShopSign",
				Size = { 30, 3, 0.3 },
				Position = { 0, 13.75, 38.45 },
				Color = "GasRed",
				Key = "Map.Gas.Shop",
				TextColor = "OffWhite",
			})
			F.part({
				Name = "Awning",
				Shape = "Wedge",
				Size = { 70, 1.6, 4.5 },
				Position = { 0, 10, 37.75 },
				Color = "GasRed",
				Material = "Fabric",
			})
			for _, x in { -18, 18 } do
				box(F, "Shelf", { x - 8, 0.3, 52 }, { x + 8, 5.2, 54.5 }, "OffWhite")
				box(F, "Goods", { x - 7.5, 1.4, 51.8 }, { x + 7.5, 2.4, 52 }, "Yellow")
				box(F, "Goods", { x - 7.5, 3.4, 51.8 }, { x + 7.5, 4.4, 52 }, "Red")
			end
			box(F, "Counter", { 22, 0.3, 44 }, { 31, 4, 47 }, "Wood", "WoodPlanks")
			box(F, "Register", { 25, 4, 45 }, { 27.5, 5.6, 46.5 }, "Black")
			box(F, "Cooler", { -31, 0.3, 66 }, { -6, 9, 69 }, "OffWhite")
			box(F, "CoolerGlow", { -30.5, 1.5, 65.8 }, { -6.5, 8.5, 66 }, "NeonWhite", "Neon")
			box(F, "IceChest", { -33, 0.3, 35 }, { -27, 4.5, 38.6 }, "OffWhite")
			box(F, "IceBand", { -33.15, 2.6, 34.85 }, { -26.85, 3.4, 38.75 }, "Teal")
			for _, x in { 28.5, 30, 31.5 } do
				F.column({ Name = "Propane", Base = { x, 0.3, 37 }, Height = 3.6, Diameter = 1.3, Color = "OffWhite" })
			end
		end)

		-- Oil storage tanks behind the canopy, on saddles inside a low wall
		B.model("OilTanks", function()
			for _, x in { 52, 62 } do
				F.part({
					Name = "Tank",
					Shape = "Cylinder",
					Size = { 32, 9, 9 },
					Position = { x, 7.6, 46 },
					Yaw = 90,
					Color = "TankWhite",
					Material = "Metal",
					CastShadow = true,
				})
				for _, z in { 38, 54 } do
					F.part({
						Name = "Band",
						Shape = "Cylinder",
						Size = { 0.6, 9.3, 9.3 },
						Position = { x, 7.6, z },
						Yaw = 90,
						Color = "GasRed",
					})
				end
				for _, z in { 34, 46, 58 } do
					box(F, "Saddle", { x - 3.5, 0, z - 1 }, { x + 3.5, 4, z + 1 }, "ConcreteDark", "Concrete")
				end
			end
			F.truss({ Name = "Ladder", Size = { 2, 12, 2 }, Position = { 46, 6, 46 }, Color = "MetalDark" })
			F.part({
				Name = "Pipe",
				Shape = "Cylinder",
				Size = { 14, 0.8, 0.8 },
				Position = { 51, 1.6, 30 },
				Color = "Metal",
			})
			for _, bund in
				{
					{ { 44, -0.5, 27 }, { 70, 1.6, 28 } },
					{ { 44, -0.5, 64 }, { 70, 1.6, 65 } },
					{ { 69, -0.5, 28 }, { 70, 1.6, 64 } },
				}
			do
				box(F, "Bund", bund[1], bund[2], "Concrete", "Concrete")
			end
		end)
	end)
end

-- The gas station's tall sign: GAS and WE BUY OIL, readable from both sides, on a brick planter.
function Buildings.gasSign(at: Vec, yaw: number)
	local F = Props.frame(at, yaw)
	B.model("GasSign", function()
		box(F, "Planter", { -6, -0.5, -2 }, { 6, 2, 2 }, "Brick", "Brick")
		for _, x in { -4, 4 } do
			box(F, "Post", { x - 0.6, 2, -0.6 }, { x + 0.6, 25, 0.6 }, "OffWhite")
		end
		box(F, "Board", { -7, 18, -0.8 }, { 7, 25, 0.8 }, "GasRed")
		box(F, "LowerBoard", { -7, 12, -0.8 }, { 7, 16.5, 0.8 }, "OffWhite")
		box(F, "Cap", { -7.4, 25, -1 }, { 7.4, 25.8, 1 }, "RoofDark")
		for _, face in { 0, 180 } do
			local z = if face == 0 then -0.9 else 0.9
			F.sign({
				Name = "GasText",
				Size = { 12, 5.6, 0.2 },
				Position = { 0, 21.5, z },
				Yaw = face,
				Color = "GasRed",
				Key = "Map.Gas.Sign",
				TextColor = "OffWhite",
			})
			F.sign({
				Name = "BuyOilText",
				Size = { 12.4, 3.6, 0.2 },
				Position = { 0, 14.25, z },
				Yaw = face,
				Color = "OffWhite",
				Key = "Map.Gas.BuyOil",
				TextColor = "GasRed",
			})
		end
		for _, x in { -3.5, 3.5 } do
			box(F, "Shrub", { x - 1.1, 2, -1.1 }, { x + 1.1, 3.6, 1.1 }, "Sage", "LeafyGrass")
		end
	end)
end

-- The car garage (where the Phase 2 garage shop goes): three roll-up doors on a brick base under a gable roof.
function Buildings.garage(at: Vec, yaw: number)
	local F = Props.frame(at, yaw)
	B.model("Garage", function()
		box(F, "Body", { -30, -0.5, 0 }, { 30, 15, 26 }, "AdobeLight", "Plaster", { CastShadow = true })
		box(F, "Base", { -30.2, -0.5, -0.2 }, { 30.2, 1.8, 26.2 }, "Brick", "Brick")
		gable(F, -31, 31, -1.5, 27.5, 15, 5, "RoofBrown", "CorrodedMetal")
		F.sign({
			Name = "GarageSign",
			Size = { 26, 2.4, 0.3 },
			Position = { 0, 13.4, -0.35 },
			Color = "MotelTeal",
			Key = "Map.Garage.Sign",
			TextColor = "OffWhite",
		})
		for _, x in { -18, 0, 18 } do
			box(F, "Door", { x - 6.5, 0.2, -0.45 }, { x + 6.5, 11, -0.2 }, "Metal", "Metal")
			for _, y in { 3, 5.6, 8.2 } do
				box(F, "Groove", { x - 6.5, y, -0.6 }, { x + 6.5, y + 0.3, -0.45 }, "MetalDark")
			end
			box(F, "Header", { x - 7, 11, -0.6 }, { x + 7, 11.8, 0 }, "GasRed")
		end
		for _, x in { -30.1, 30.1 } do
			box(F, "SideWindowFrame", { x - 0.2, 5, 8 }, { x + 0.2, 10, 18 }, "Concrete")
			box(F, "SideWindow", { x - 0.35, 5.4, 8.4 }, { x + 0.35, 9.6, 17.6 }, "WindowDark")
		end
		box(F, "Toolbox", { 25, 0, -3.5 }, { 29, 4, -1.5 }, "GasRed")
	end)
	Props.tires(F.at(-34, 0, -3), 4)
	Props.tires(F.at(-34, 0, 2), 3)
	Props.drum(F.at(33, 0, -2), "Teal")
	Props.drum(F.at(33.5, 0, 1), "Rust")
end

-- A mobile home with a low gable roof, framed windows, a wooden stoop and a propane tank. Anchor: the middle of its
-- front wall.
function Buildings.trailer(at: Vec, yaw: number, stripe: string)
	local F = Props.frame(at, yaw)
	B.model("Trailer", function()
		box(F, "Skirt", { -20, -0.5, 0.5 }, { 20, 1.6, 12.5 }, "MetalDark")
		box(F, "Body", { -21, 1.6, 0 }, { 21, 9.6, 13 }, "OffWhite", nil, { CastShadow = true })
		box(F, "Stripe", { -21.15, 5, -0.15 }, { 21.15, 6, 13.15 }, stripe)
		gable(F, -21.4, 21.4, -0.6, 13.6, 9.6, 1.6, "TankWhite", "SmoothPlastic")
		for _, x in { -14, -2, 14 } do
			box(F, "WindowFrame", { x - 2.8, 6.2, -0.4 }, { x + 2.8, 8.9, 0 }, "Concrete")
			box(F, "Window", { x - 2.4, 6.5, -0.55 }, { x + 2.4, 8.6, -0.4 }, "WindowDark")
		end
		box(F, "Door", { 4.5, 1.6, -0.3 }, { 8, 8.6, 0 }, "Wood", "Wood")
		box(F, "Stoop", { 3.5, -0.5, -4 }, { 9, 0.6, -2 }, "Wood", "WoodPlanks")
		box(F, "Stoop", { 3.5, -0.5, -2 }, { 9, 1.4, 0 }, "Wood", "WoodPlanks")
		box(F, "RoofAC", { -16, 10.6, 4 }, { -12, 12.2, 8 }, "Metal")
		F.part({
			Name = "PropaneTank",
			Shape = "Cylinder",
			Size = { 5, 2.6, 2.6 },
			Position = { 23.5, 1.3, 6 },
			Yaw = 90,
			Color = "OffWhite",
		})
		box(F, "ChairSeat", { -8.2, -0.5, -4.2 }, { -5.8, 1.4, -1.8 }, stripe)
		box(F, "ChairBack", { -8.2, 1.4, -2.2 }, { -5.8, 3.6, -1.8 }, stripe)
	end)
end

-- The town's water tower: square braced legs, a balcony, a tank with a red band and the game's name, and a
-- climbable ladder.
function Buildings.waterTower(at: Vec)
	local F = Props.frame(at, 0)
	B.model("WaterTower", function()
		for _, x in { -7, 7 } do
			for _, z in { -7, 7 } do
				box(F, "Leg", { x - 0.7, 0, z - 0.7 }, { x + 0.7, 36, z + 0.7 }, "Metal", "Metal")
			end
		end
		for _, yaw in { 0, 90, 180, 270 } do
			local G = Props.frame(F.at(0, 0, 0), yaw)
			for _, y in { 12, 24 } do
				box(G, "Beam", { -6.3, y - 0.3, -7.3 }, { 6.3, y + 0.3, -6.7 }, "MetalDark")
				for _, sign in { -1, 1 } do
					G.part({
						Name = "Brace",
						Size = { 18.4, 0.4, 0.4 },
						Position = { 0, y - 6, -7 },
						Rotation = { 0, 0, sign * 40.6 },
						Color = "MetalDark",
					})
				end
			end
		end
		box(F, "Pipe", { -0.8, 0, -0.8 }, { 0.8, 36.4, 0.8 }, "Metal", "Metal")
		F.column({
			Name = "Balcony",
			Base = { 0, 35.6, 0 },
			Height = 0.8,
			Diameter = 26,
			Color = "MetalDark",
			Material = "Metal",
		})
		for index = 0, 7 do
			local angle = index * 45 + 22.5
			local x, z = Props.rotate(0, -12.6, angle)
			F.part({ Name = "Rail", Size = { 10.4, 0.4, 0.4 }, Position = { x, 39, z }, Yaw = angle, Color = "Metal" })
		end
		F.column({
			Name = "Tank",
			Base = { 0, 36.4, 0 },
			Height = 16,
			Diameter = 22,
			Color = "TankWhite",
			Material = "Metal",
			CastShadow = true,
		})
		F.column({ Name = "Band", Base = { 0, 49, 0 }, Height = 2, Diameter = 22.4, Color = "GasRed" })
		for _, step in { { 52.4, 2, 20 }, { 54.4, 2, 14 }, { 56.4, 1.6, 7 } } do
			F.column({
				Name = "Roof",
				Base = { 0, step[1], 0 },
				Height = step[2],
				Diameter = step[3],
				Color = "TankWhite",
			})
		end
		box(F, "Finial", { -1, 58, -1 }, { 1, 60, 1 }, "GasRed")
		for _, face in { 0, 180 } do
			local G = Props.frame(F.at(0, 0, 0), face)
			G.sign({
				Name = "TitleBanner",
				Size = { 14, 4.4, 0.4 },
				Position = { 0, 44, -11.4 },
				Color = "TankWhite",
				Key = "Game.Title",
				TextColor = "GasRed",
			})
		end
		F.truss({ Name = "Ladder", Size = { 2, 38, 2 }, Position = { 9.6, 19, -9.6 }, Color = "MetalDark" })
	end)
end

-- A town gate: two adobe pillars on brick bases, a beam and a hanging sign (SAFE ZONE outside, LEAVING SAFE ZONE
-- inside). The frame's front (-Z) faces out of town.
function Buildings.gate(at: Vec, yaw: number)
	local F = Props.frame(at, yaw)
	B.model("Gate", function()
		for _, x in { -23, 23 } do
			box(F, "PillarBase", { x - 3.4, -0.5, -3.4 }, { x + 3.4, 1.6, 3.4 }, "Brick", "Brick")
			box(F, "Pillar", { x - 3, 1.6, -3 }, { x + 3, 15, 3 }, "Adobe", "Plaster", { CastShadow = true })
			box(F, "PillarCap", { x - 3.6, 15, -3.6 }, { x + 3.6, 16.2, 3.6 }, "AdobeLight", "Plaster")
			for _, z in { -3.6, 3 } do
				box(F, "Lantern", { x - 0.8, 11, z }, { x + 0.8, 13, z + 0.6 }, "WarmLight", "Neon")
			end
		end
		box(F, "Beam", { -26, 16.2, -1 }, { 26, 18.2, 1 }, "Wood", "WoodPlanks", { CastShadow = true })
		for _, x in { -9, 9 } do
			box(F, "Chain", { x - 0.2, 15.6, -0.2 }, { x + 0.2, 16.2, 0.2 }, "MetalDark")
		end
		box(F, "SignBoard", { -12, 11.2, -0.4 }, { 12, 15.6, 0.4 }, "Wood", "WoodPlanks")
		for _, side in { { -0.55, 0, "Map.Gate.Outside" }, { 0.55, 180, "Map.Gate.Inside" } } do
			F.sign({
				Name = "GateText",
				Size = { 23, 4, 0.2 },
				Position = { 0, 13.4, side[1] },
				Yaw = side[2],
				Color = "Wood",
				Material = "WoodPlanks",
				Key = side[3],
				TextColor = "OffWhite",
			})
		end
	end)
end

-- A roadside billboard with the game's name on it, facing the frame's front (-Z).
function Buildings.billboard(at: Vec, yaw: number)
	local F = Props.frame(at, yaw)
	B.model("Billboard", function()
		for _, x in { -11, 11 } do
			box(F, "Post", { x - 0.7, -0.5, 0.3 }, { x + 0.7, 23.4, 1.7 }, "Wood", "Wood")
		end
		box(F, "Brace", { -13, 5.7, 0.7 }, { 13, 6.3, 1.3 }, "Wood", "Wood")
		box(F, "Back", { -16, 12, -0.4 }, { 16, 24, 0.4 }, "OffWhite")
		box(F, "Cap", { -16.4, 24, -0.7 }, { 16.4, 24.6, 0.7 }, "RoofDark")
		F.sign({
			Name = "Ad",
			Size = { 31, 11, 0.2 },
			Position = { 0, 18, -0.5 },
			Color = "MotelTeal",
			Key = "Game.Title",
			TextColor = "OffWhite",
		})
		box(F, "Catwalk", { -16, 11.4, -2.6 }, { 16, 12, -0.4 }, "Wood", "WoodPlanks")
		for _, x in { -10, 0, 10 } do
			box(F, "Lamp", { x - 0.6, 12, -3 }, { x + 0.6, 12.6, -2.4 }, "MetalDark")
		end
	end)
end

-- A farm windmill: a braced lattice tower with a 12-blade wheel and a tail vane.
function Buildings.windmill(at: Vec, yaw: number)
	local F = Props.frame(at, yaw)
	B.model("Windmill", function()
		for _, x in { -3, 3 } do
			for _, z in { -3, 3 } do
				box(F, "Leg", { x - 0.35, -0.5, z - 0.35 }, { x + 0.35, 30, z + 0.35 }, "Metal", "Metal")
			end
		end
		for _, y in { 8, 16, 24 } do
			box(F, "Ring", { -3.35, y, -3.35 }, { 3.35, y + 0.4, 3.35 }, "MetalDark")
		end
		box(F, "Platform", { -3.6, 30, -3.6 }, { 3.6, 30.6, 3.6 }, "Wood", "WoodPlanks")
		box(F, "Hub", { -0.8, 32.2, -3.4 }, { 0.8, 33.8, -1.8 }, "MetalDark")
		for blade = 0, 11 do
			local angle = blade * 30
			local x, y = Props.rotate(3.6, 0, -angle)
			F.part({
				Name = "Blade",
				Size = { 0.9, 5, 0.2 },
				Position = { x, 33 + y, -2.8 },
				Rotation = { 0, 0, angle - 90 },
				Color = if blade % 2 == 0 then "OffWhite" else "GasRed",
			})
		end
		box(F, "Tail", { -0.2, 31.5, 0 }, { 0.2, 34.5, 7 }, "OffWhite")
		box(F, "TailBoom", { -0.25, 32.75, -2 }, { 0.25, 33.25, 4 }, "MetalDark")
	end)
end

return Buildings
