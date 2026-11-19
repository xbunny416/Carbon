--!strict
--[[
	Buildings — the town's many-part buildings for CarOff (maps/layouts/Town.luau places them). Each one is built in
	a Props frame: `at` is its anchor on the ground, local -Z is its front, `yaw` turns it (see Props.frame).
	Sign text comes from GameStrings keys.
]]
local B = require("./Builder")
local Props = require("./Props")

type Vec = B.Vec

local Buildings = {}

--[[
	The motel: a two-floor row of 8 rooms with doors, windows and wall AC units, a balcony walkway with railings,
	stairs at the right end and an office with a glass front on the left. Anchor: the middle of the front wall.
	Players spawn on the welcome mats in front of the middle rooms (returned count).
]]
function Buildings.motel(at: Vec, yaw: number): number
	local F = Props.frame(at, yaw)
	local spawns = 0
	B.model("Motel", function()
		F.box({
			Name = "Walkway",
			From = { -78, -1, -9 },
			To = { 82, 0.6, 22 },
			Color = "Concrete",
			Material = "Concrete",
		})
		F.box({ Name = "Curb", From = { -78, -1, -9.6 }, To = { 82, 0.8, -9 }, Color = "ConcreteLight" })

		-- Office (hollow, with a counter inside behind the glass)
		B.model("Office", function()
			local wall = { Color = "Adobe", Material = "Plaster", CastShadow = true }
			local function wallBox(from: Vec, to: Vec)
				local spec = table.clone(wall) :: any
				spec.Name, spec.From, spec.To = "Wall", from, to
				F.box(spec)
			end
			wallBox({ -75, 0.6, 19 }, { -53, 12, 20 })
			wallBox({ -75, 0.6, -1 }, { -74, 12, 19 })
			wallBox({ -54, 0.6, -1 }, { -53, 12, 19 })
			wallBox({ -74, 0.6, -1 }, { -59, 2.2, 0 })
			wallBox({ -74, 8.6, -1 }, { -54, 12, 0 })
			wallBox({ -59, 0.6, -1 }, { -58, 8.6, 0 })
			F.box({
				Name = "Window",
				From = { -74, 2.2, -0.6 },
				To = { -59, 8.6, -0.4 },
				Color = "Glass",
				Material = "Glass",
				Transparency = 0.45,
			})
			F.box({
				Name = "Door",
				From = { -58, 0.6, -0.6 },
				To = { -54, 8.6, -0.4 },
				Color = "Glass",
				Material = "Glass",
				Transparency = 0.5,
				CanCollide = false,
			})
			for _, x in { -69, -64 } do
				F.box({
					Name = "Mullion",
					From = { x - 0.15, 2.2, -0.7 },
					To = { x + 0.15, 8.6, -0.3 },
					Color = "White",
				})
			end
			F.box({ Name = "Roof", From = { -76, 12, -2 }, To = { -52, 13, 21 }, Color = "ConcreteLight" })
			F.box({
				Name = "Parapet",
				From = { -76, 13, -2.4 },
				To = { -52, 16, -1.6 },
				Color = "Adobe",
				Material = "Plaster",
			})
			F.sign({
				Name = "OfficeSign",
				Size = { 14, 2.6, 0.3 },
				Position = { -64, 14.5, -2.55 },
				Color = "Black",
				Key = "Map.Motel.Office",
				TextColor = "NeonPink",
				Glow = true,
			})
			F.box({ Name = "Awning", From = { -76, 10.6, -6 }, To = { -52, 11.4, -1 }, Color = "MotelTeal" })
			F.box({ Name = "AwningTrim", From = { -76, 10.2, -6.3 }, To = { -52, 11.4, -6 }, Color = "MotelPink" })
			F.box({
				Name = "Counter",
				From = { -71, 0.6, 5 },
				To = { -60, 4.2, 7.5 },
				Color = "Wood",
				Material = "WoodPlanks",
			})
			F.box({ Name = "CounterTop", From = { -71.3, 4.2, 4.7 }, To = { -59.7, 4.6, 7.8 }, Color = "WoodDark" })
			F.ball({ Name = "Bell", Center = { -62, 4.9, 6 }, Diameter = 0.6, Color = "Chrome", Material = "Metal" })
			F.box({ Name = "KeyBoard", From = { -69, 5, 18.6 }, To = { -62, 9, 19 }, Color = "WoodDark" })
			F.box({
				Name = "Rug",
				From = { -72, 0.6, -0.2 },
				To = { -60, 0.7, 4 },
				Color = "MotelPink",
				Material = "Fabric",
			})
			F.box({
				Name = "CeilingLight",
				From = { -68, 11.7, 6 },
				To = { -62, 12, 10 },
				Color = "NeonWhite",
				Material = "Neon",
			})
		end)

		-- Rooms: one solid block dressed with doors, windows, AC units and lamps on both floors
		F.box({
			Name = "Rooms",
			From = { -53, 0.6, 0 },
			To = { 75, 22.6, 20 },
			Color = "Stucco",
			Material = "Plaster",
			CastShadow = true,
		})
		F.box({ Name = "Cornice", From = { -54, 21.6, -0.6 }, To = { 76, 22.6, 0 }, Color = "White" })
		F.box({ Name = "Baseboard", From = { -53, 0.6, -0.3 }, To = { 75, 1.4, 0 }, Color = "MotelTeal" })
		for floor = 0, 1 do
			local fy = 0.6 + floor * 11
			for room = 0, 8 do
				local x = -53 + room * 16
				F.box({
					Name = "Pilaster",
					From = { x - 0.4, fy, -0.4 },
					To = { x + 0.4, fy + 10.4, 0 },
					Color = "White",
				})
			end
			for room = 0, 7 do
				local xc = -53 + room * 16 + 8
				local doorColor = if room % 2 == 0 then "MotelTeal" else "MotelPink"
				F.box({ Name = "Door", From = { xc - 5, fy, -0.3 }, To = { xc - 1.4, fy + 7.6, 0 }, Color = doorColor })
				F.box({
					Name = "Lintel",
					From = { xc - 5.4, fy + 7.6, -0.4 },
					To = { xc - 1, fy + 8.1, 0 },
					Color = "White",
				})
				F.ball({ Name = "Knob", Center = { xc - 1.9, fy + 3.6, -0.45 }, Diameter = 0.35, Color = "Chrome" })
				F.box({
					Name = "Window",
					From = { xc + 0.6, fy + 3.2, -0.25 },
					To = { xc + 6.2, fy + 7.2, 0 },
					Color = "Glass",
					Material = "Glass",
				})
				F.box({
					Name = "Sill",
					From = { xc + 0.3, fy + 2.9, -0.5 },
					To = { xc + 6.5, fy + 3.2, 0 },
					Color = "White",
				})
				F.box({
					Name = "Header",
					From = { xc + 0.3, fy + 7.2, -0.4 },
					To = { xc + 6.5, fy + 7.5, 0 },
					Color = "White",
				})
				F.box({ Name = "AC", From = { xc + 2, fy + 0.9, -1.4 }, To = { xc + 5, fy + 2.6, 0 }, Color = "Metal" })
				F.box({
					Name = "Grille",
					From = { xc + 2.3, fy + 1.2, -1.45 },
					To = { xc + 4.7, fy + 2.3, -1.4 },
					Color = "MetalDark",
				})
				F.box({
					Name = "Lamp",
					From = { xc - 0.8, fy + 6, -0.5 },
					To = { xc - 0.2, fy + 7, 0 },
					Color = "WarmLight",
					Material = "Neon",
				})
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

		-- Balcony walkway, posts and railing
		F.box({
			Name = "Balcony",
			From = { -53, 10.6, -7 },
			To = { 82, 11.6, 0 },
			Color = "Concrete",
			Material = "Concrete",
		})
		F.box({ Name = "BalconyTrim", From = { -53, 10.2, -7.3 }, To = { 82, 11.8, -7 }, Color = "MotelTeal" })
		for room = 0, 8 do
			local x = -53 + room * 16
			F.box({ Name = "Post", From = { x - 0.4, 0.6, -6.9 }, To = { x + 0.4, 10.6, -6.1 }, Color = "White" })
		end
		F.box({ Name = "Post", From = { 81, 0.6, -6.9 }, To = { 81.8, 10.6, -6.1 }, Color = "White" })
		F.box({ Name = "Handrail", From = { -53, 14.8, -7 }, To = { 82, 15.2, -6.6 }, Color = "MotelTeal" })
		F.box({ Name = "Rail", From = { -53, 12.2, -7 }, To = { 82, 12.5, -6.6 }, Color = "MotelTeal" })
		F.box({ Name = "Handrail", From = { 81.6, 14.8, -7 }, To = { 82, 15.2, 0 }, Color = "MotelTeal" })
		for x = -51, 80, 4 do
			F.box({ Name = "Baluster", From = { x - 0.15, 11.6, -6.9 }, To = { x + 0.15, 14.8, -6.7 }, Color = "White" })
		end

		-- Roof with an overhang over the balcony, a pink fascia and AC units
		F.box({
			Name = "Roof",
			From = { -54, 22.6, -8 },
			To = { 76, 23.6, 21 },
			Color = "ConcreteLight",
			CastShadow = true,
		})
		F.box({ Name = "Fascia", From = { -54, 22.2, -8.4 }, To = { 76, 24.4, -8 }, Color = "MotelPink" })
		for _, x in { -30, 10, 50 } do
			F.box({
				Name = "RoofAC",
				From = { x - 3, 23.6, 6 },
				To = { x + 3, 26.6, 12 },
				Color = "Metal",
				Material = "Metal",
			})
			F.column({ Name = "Fan", Base = { x, 26.6, 9 }, Height = 0.3, Diameter = 4, Color = "MetalDark" })
		end

		-- Stairs at the right end, from the back up to the balcony
		for step = 1, 11 do
			local z0 = (11 - step) * 1.8
			F.box({
				Name = "Step",
				From = { 76, 0.6, z0 },
				To = { 80, 0.6 + step, z0 + 1.8 },
				Color = "Concrete",
				Material = "Concrete",
			})
		end
		F.part({
			Name = "StairRail",
			Size = { 0.3, 0.3, 22.65 },
			Position = { 80.3, 9.6, 9.9 },
			Rotation = { 29.05, 0, 0 },
			Color = "MotelTeal",
		})
		for _, z in { 1, 10, 19 } do
			F.box({ Name = "RailPost", From = { 80.15, 0.6, z - 0.15 }, To = { 80.45, 15, z + 0.15 }, Color = "White" })
		end

		-- Vending machine and planters on the walkway
		F.box({ Name = "Vending", From = { 69.5, 0.6, -3.6 }, To = { 73.5, 7.6, -0.6 }, Color = "GasRed" })
		F.box({
			Name = "VendingFront",
			From = { 70, 2.6, -3.7 },
			To = { 73, 7, -3.6 },
			Color = "NeonWhite",
			Material = "Neon",
		})
		for _, x in { -50, 66 } do
			F.box({
				Name = "Planter",
				From = { x - 1.5, 0.6, -5 },
				To = { x + 1.5, 2.6, -2 },
				Color = "Adobe",
				Material = "Plaster",
			})
			F.ball({ Name = "Cactus", Center = { x, 3.2, -3.5 }, Diameter = 1.8, Color = "Cactus" })
		end
	end)
	return spawns
end

-- The motel's neon pylon sign: MOTEL, an arrow and VACANCY, readable from both sides.
function Buildings.motelSign(at: Vec, yaw: number)
	local F = Props.frame(at, yaw)
	B.model("MotelSign", function()
		F.box({
			Name = "Base",
			From = { -5.5, -0.5, -1.5 },
			To = { 5.5, 1.5, 1.5 },
			Color = "Adobe",
			Material = "Plaster",
		})
		for _, x in { -3.9, 3.9 } do
			F.box({
				Name = "Post",
				From = { x - 0.6, 1.5, -0.6 },
				To = { x + 0.6, 30, 0.6 },
				Color = "MetalDark",
				Material = "Metal",
			})
		end
		local board = F.box({ Name = "Board", From = { -9, 20, -1 }, To = { 9, 28, 1 }, Color = "MotelTeal" })
		B.light(board, "NeonPink", 28, 1.5)
		for _, face in { 0, 180 } do
			local z = if face == 0 then -1.15 else 1.15
			F.sign({
				Name = "MotelText",
				Size = { 16, 6, 0.3 },
				Position = { 0, 24, z },
				Yaw = face,
				Color = "MotelTeal",
				Key = "Map.Motel.Sign",
				TextColor = "NeonPink",
				Glow = true,
			})
			F.sign({
				Name = "VacancyText",
				Size = { 11, 2.4, 0.2 },
				Position = { 0, 14, if face == 0 then -0.7 else 0.7 },
				Yaw = face,
				Color = "Black",
				Key = "Map.Motel.Vacancy",
				TextColor = "NeonOrange",
				Glow = true,
			})
		end
		local neon = { Color = "NeonPink", Material = "Neon" }
		for _, box in
			{
				{ { -9.3, 27.9, -1.3 }, { 9.3, 28.4, 1.3 } },
				{ { -9.3, 19.6, -1.3 }, { 9.3, 20.1, 1.3 } },
				{ { -9.4, 19.6, -1.3 }, { -8.9, 28.4, 1.3 } },
				{ { 8.9, 19.6, -1.3 }, { 9.4, 28.4, 1.3 } },
			}
		do
			local spec = table.clone(neon) :: any
			spec.Name, spec.From, spec.To = "Neon", box[1], box[2]
			F.box(spec)
		end
		F.box({ Name = "VacancyBoard", From = { -6, 12.5, -0.6 }, To = { 6, 15.5, 0.6 }, Color = "Black" })
		F.box({
			Name = "Arrow",
			From = { -12, 16.6, -0.5 },
			To = { 6, 18.4, 0.5 },
			Color = "NeonOrange",
			Material = "Neon",
		})
		F.part({
			Name = "ArrowTip",
			Shape = "Wedge",
			Size = { 1, 2.4, 4 },
			Position = { -14, 18.7, 0 },
			Yaw = 90,
			Color = "NeonOrange",
			Material = "Neon",
		})
		F.part({
			Name = "ArrowTip",
			Shape = "Wedge",
			Size = { 1, 2.4, 4 },
			Position = { -14, 16.3, 0 },
			Yaw = 90,
			Rotation = { 0, 0, 180 },
			Color = "NeonOrange",
			Material = "Neon",
		})
		F.ball({ Name = "Star", Center = { 0, 30.4, 0 }, Diameter = 2.4, Color = "NeonYellow", Material = "Neon" })
	end)
end

-- A fenced pool deck with lounge chairs and an umbrella. Anchor: the middle of the deck.
function Buildings.pool(at: Vec, yaw: number)
	local F = Props.frame(at, yaw)
	B.model("Pool", function()
		local deck = { Color = "ConcreteLight", Material = "Concrete" }
		for _, box in
			{
				{ { -18, -0.5, -14 }, { 18, 1.2, -8 } },
				{ { -18, -0.5, 8 }, { 18, 1.2, 14 } },
				{ { -18, -0.5, -8 }, { -13, 1.2, 8 } },
				{ { 13, -0.5, -8 }, { 18, 1.2, 8 } },
			}
		do
			local spec = table.clone(deck) :: any
			spec.Name, spec.From, spec.To = "Deck", box[1], box[2]
			F.box(spec)
		end
		F.box({
			Name = "Water",
			From = { -13, -0.5, -8 },
			To = { 13, 0.8, 8 },
			Color = "PoolWater",
			Material = "Glass",
			Transparency = 0.15,
		})
		for _, box in
			{
				{ { -13.6, 1.2, -8.6 }, { 13.6, 1.4, -8 } },
				{ { -13.6, 1.2, 8 }, { 13.6, 1.4, 8.6 } },
				{ { -13.6, 1.2, -8 }, { -13, 1.4, 8 } },
				{ { 13, 1.2, -8 }, { 13.6, 1.4, 8 } },
			}
		do
			F.box({ Name = "Coping", From = box[1], To = box[2], Color = "White" })
		end
		for _, x in { 10.6, 12 } do
			F.column({ Name = "LadderRail", Base = { x, 0.8, -7.6 }, Height = 3, Diameter = 0.25, Color = "Chrome" })
		end
		for index, x in { -9, -3, 3 } do
			local cushion = if index % 2 == 0 then "MotelPink" else "MotelTeal"
			F.box({ Name = "Lounger", From = { x - 1.1, 1.6, 9.2 }, To = { x + 1.1, 2, 13 }, Color = "White" })
			F.box({
				Name = "Cushion",
				From = { x - 1, 2, 9.4 },
				To = { x + 1, 2.3, 12.8 },
				Color = cushion,
				Material = "Fabric",
			})
			F.part({
				Name = "Backrest",
				Size = { 2.2, 0.3, 2.6 },
				Position = { x, 2.6, 13.6 },
				Rotation = { 40, 0, 0 },
				Color = cushion,
				Material = "Fabric",
			})
		end
		F.column({ Name = "UmbrellaPole", Base = { 9, 1.2, 11 }, Height = 8, Diameter = 0.3, Color = "White" })
		F.column({
			Name = "Umbrella",
			Base = { 9, 8.4, 11 },
			Height = 0.5,
			Diameter = 9,
			Color = "MotelPink",
			Material = "Fabric",
		})
		F.ball({ Name = "UmbrellaTop", Center = { 9, 9.1, 11 }, Diameter = 1, Color = "White" })
		local corners = { F.at(-18, 1.2, -14), F.at(18, 1.2, -14), F.at(18, 1.2, 14), F.at(-18, 1.2, 14) }
		for index = 1, 3 do
			Props.fence(corners[index], corners[index + 1], 4, 4, "White")
		end
		Props.fence(corners[4], F.at(-18, 1.2, 4), 4, 4, "White")
	end)
end

--[[
	The gas station: a canopy over 3 pump islands (6 pump bays, one on each side of every island, tagged PumpBay), a
	shop with a glass front and shelves inside, and two oil storage tanks. Anchor: the middle of the canopy; cars pull
	in heading +Z (the frame's back).
]]
function Buildings.gasStation(at: Vec, yaw: number)
	local F = Props.frame(at, yaw)
	local bays = 0
	B.model("GasStation", function()
		F.box({
			Name = "Pad",
			From = { -66, -0.5, -28 },
			To = { 66, 0.3, 28 },
			Color = "Concrete",
			Material = "Concrete",
		})

		-- Pump islands, pumps, canopy columns and the bays beside them
		for _, ix in { -40, 0, 40 } do
			B.model("PumpIsland", function()
				F.box({
					Name = "Island",
					From = { ix - 2.5, 0.3, -14 },
					To = { ix + 2.5, 1.1, 14 },
					Color = "ConcreteLight",
				})
				for _, z in { -15.5, 15.5 } do
					F.column({ Name = "Bollard", Base = { ix, 0.3, z }, Height = 3.4, Diameter = 1, Color = "RoadLine" })
				end
				for _, z in { -6, 6 } do
					F.box({
						Name = "Pump",
						From = { ix - 1.2, 1.1, z - 1.6 },
						To = { ix + 1.2, 7.1, z + 1.6 },
						Color = "White",
					})
					F.box({
						Name = "Hood",
						From = { ix - 1.35, 7.1, z - 1.75 },
						To = { ix + 1.35, 8.3, z + 1.75 },
						Color = "GasRed",
					})
					F.box({
						Name = "Display",
						From = { ix - 1.3, 5, z - 1 },
						To = { ix + 1.3, 6.4, z + 1 },
						Color = "Black",
					})
					F.box({
						Name = "Stripe",
						From = { ix - 1.25, 2, z - 1.65 },
						To = { ix + 1.25, 2.4, z + 1.65 },
						Color = "GasRed",
					})
					F.box({
						Name = "Holster",
						From = { ix - 1.6, 3, z + 0.3 },
						To = { ix + 1.6, 4.2, z + 1.2 },
						Color = "MetalDark",
					})
					for _, side in { -1, 1 } do
						F.part({
							Name = "Hose",
							Size = { 0.25, 3.2, 0.25 },
							Position = { ix + side * 1.75, 2.5, z + 0.75 },
							Rotation = { 0, 0, side * 8 },
							Color = "Black",
						})
					end
				end
				F.column({ Name = "Bin", Base = { ix, 1.1, 10.5 }, Height = 3, Diameter = 1.6, Color = "MetalDark" })
				for _, z in { -11, 11 } do
					F.box({
						Name = "Column",
						From = { ix - 0.9, 1.1, z - 0.9 },
						To = { ix + 0.9, 16, z + 0.9 },
						Color = "White",
					})
					F.box({
						Name = "ColumnBase",
						From = { ix - 1.1, 1.1, z - 1.1 },
						To = { ix + 1.1, 3, z + 1.1 },
						Color = "GasRed",
					})
				end
				for _, side in { -1, 1 } do
					local bx = ix + side * 9
					bays += 1
					F.marker("PumpBay", `PumpBay{bays}`, { bx, 0.3, 0 }, { Index = bays }, 180)
					local panel = F.box({
						Name = "CanopyLight",
						From = { bx - 2, 15.8, -8 },
						To = { bx + 2, 16, 8 },
						Color = "NeonWhite",
						Material = "Neon",
					})
					if side == 1 then
						B.light(panel, "WarmLight", 26, 1)
					end
				end
			end)
		end

		-- Canopy roof with a red fascia and a white stripe
		F.box({ Name = "Canopy", From = { -62, 16, -25 }, To = { 62, 18.5, 25 }, Color = "White", CastShadow = true })
		for _, z in { -25.2, 25.2 } do
			F.box({ Name = "Fascia", From = { -62.4, 15.6, z - 0.2 }, To = { 62.4, 19.4, z + 0.2 }, Color = "GasRed" })
			F.box({ Name = "Stripe", From = { -62.6, 17.2, z - 0.3 }, To = { 62.6, 17.8, z + 0.3 }, Color = "White" })
		end
		for _, x in { -62.2, 62.2 } do
			F.box({ Name = "Fascia", From = { x - 0.2, 15.6, -25 }, To = { x + 0.2, 19.4, 25 }, Color = "GasRed" })
		end

		-- Shop (hollow, glass front, shelves and coolers inside)
		B.model("Shop", function()
			F.box({ Name = "Floor", From = { -36, -0.5, 39 }, To = { 36, 0.3, 71 }, Color = "ConcreteLight" })
			local wall = { Color = "Stucco", Material = "Plaster", CastShadow = true }
			for _, box in
				{
					{ { -35, 0.3, 69 }, { 35, 13, 70 } },
					{ { -35, 0.3, 40 }, { -34, 13, 69 } },
					{ { 34, 0.3, 40 }, { 35, 13, 69 } },
					{ { -34, 0.3, 40 }, { -3.5, 2, 41 } },
					{ { 3.5, 0.3, 40 }, { 34, 2, 41 } },
					{ { -34, 9, 40 }, { 34, 13, 41 } },
					{ { -34, 2, 40 }, { -32, 9, 41 } },
					{ { -4, 2, 40 }, { -3.5, 9, 41 } },
					{ { 3.5, 2, 40 }, { 4, 9, 41 } },
					{ { 32, 2, 40 }, { 34, 9, 41 } },
				}
			do
				local spec = table.clone(wall) :: any
				spec.Name, spec.From, spec.To = "Wall", box[1], box[2]
				F.box(spec)
			end
			for _, x in { -18, 18 } do
				F.box({
					Name = "Window",
					From = { x - 14, 2, 40.4 },
					To = { x + 14, 9, 40.6 },
					Color = "Glass",
					Material = "Glass",
					Transparency = 0.45,
				})
			end
			F.box({
				Name = "Door",
				From = { -3.5, 0.3, 40.4 },
				To = { 3.5, 9, 40.6 },
				Color = "Glass",
				Material = "Glass",
				Transparency = 0.5,
				CanCollide = false,
			})
			F.box({
				Name = "DoorFrame",
				From = { -0.1, 0.3, 40.3 },
				To = { 0.1, 9, 40.7 },
				Color = "Chrome",
				CanCollide = false,
			})
			F.box({ Name = "Roof", From = { -36, 13, 39 }, To = { 36, 14, 71 }, Color = "White" })
			F.box({ Name = "Parapet", From = { -36, 12, 38.6 }, To = { 36, 15.5, 39.4 }, Color = "GasRed" })
			F.sign({
				Name = "ShopSign",
				Size = { 30, 3, 0.3 },
				Position = { 0, 13.75, 38.45 },
				Color = "GasRed",
				Key = "Map.Gas.Shop",
				TextColor = "White",
			})
			for index = 0, 5 do
				F.part({
					Name = "Awning",
					Size = { 12, 0.4, 6 },
					Position = { -30 + index * 12, 10.6, 37.6 },
					Rotation = { -14, 0, 0 },
					Color = if index % 2 == 0 then "GasRed" else "White",
					Material = "Fabric",
				})
			end
			for _, x in { -18, 18 } do
				F.box({ Name = "Shelf", From = { x - 8, 0.3, 52 }, To = { x + 8, 5.2, 54.5 }, Color = "White" })
				F.box({ Name = "Goods", From = { x - 7.5, 1.4, 51.8 }, To = { x + 7.5, 2.4, 52 }, Color = "Yellow" })
				F.box({ Name = "Goods", From = { x - 7.5, 3.4, 51.8 }, To = { x + 7.5, 4.4, 52 }, Color = "Red" })
			end
			F.box({
				Name = "Counter",
				From = { 22, 0.3, 44 },
				To = { 31, 4, 47 },
				Color = "Wood",
				Material = "WoodPlanks",
			})
			F.box({ Name = "Register", From = { 25, 4, 45 }, To = { 27.5, 5.6, 46.5 }, Color = "Black" })
			F.box({ Name = "Cooler", From = { -31, 0.3, 66 }, To = { -6, 9, 69 }, Color = "White" })
			F.box({
				Name = "CoolerGlow",
				From = { -30.5, 1.5, 65.8 },
				To = { -6.5, 8.5, 66 },
				Color = "NeonWhite",
				Material = "Neon",
			})
			F.box({ Name = "IceChest", From = { -33, 0.3, 35 }, To = { -27, 4.5, 38.6 }, Color = "White" })
			F.box({ Name = "IceBand", From = { -33.1, 2.6, 34.9 }, To = { -26.9, 3.4, 38.7 }, Color = "Teal" })
			for _, x in { 27, 33 } do
				F.box({
					Name = "CagePost",
					From = { x - 0.15, 0.3, 35 },
					To = { x + 0.15, 6, 35.3 },
					Color = "MetalDark",
				})
			end
			F.box({ Name = "CageTop", From = { 27, 6, 35 }, To = { 33, 6.3, 38.6 }, Color = "MetalDark" })
			for _, x in { 28.5, 30, 31.5 } do
				F.column({ Name = "Propane", Base = { x, 0.3, 37 }, Height = 3.6, Diameter = 1.3, Color = "White" })
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
					F.box({
						Name = "Saddle",
						From = { x - 3.5, 0, z - 1 },
						To = { x + 3.5, 4, z + 1 },
						Color = "ConcreteDark",
					})
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
			for _, box in
				{
					{ { 44, -0.5, 27 }, { 70, 1.6, 28 } },
					{ { 44, -0.5, 64 }, { 70, 1.6, 65 } },
					{ { 69, -0.5, 28 }, { 70, 1.6, 64 } },
				}
			do
				F.box({ Name = "Bund", From = box[1], To = box[2], Color = "Concrete" })
			end
		end)
	end)
end

-- The gas station's tall price sign: GAS and WE BUY OIL, readable from both sides.
function Buildings.gasSign(at: Vec, yaw: number)
	local F = Props.frame(at, yaw)
	B.model("GasSign", function()
		F.box({ Name = "Planter", From = { -6, -0.5, -2 }, To = { 6, 2, 2 }, Color = "Adobe", Material = "Plaster" })
		for _, x in { -4, 4 } do
			F.box({ Name = "Post", From = { x - 0.6, 2, -0.6 }, To = { x + 0.6, 25, 0.6 }, Color = "White" })
		end
		F.box({ Name = "Board", From = { -7, 18, -0.8 }, To = { 7, 25, 0.8 }, Color = "GasRed" })
		F.box({ Name = "LowerBoard", From = { -7, 12, -0.8 }, To = { 7, 16.5, 0.8 }, Color = "White" })
		F.box({ Name = "Cap", From = { -7.4, 25, -1 }, To = { 7.4, 25.8, 1 }, Color = "White" })
		for _, face in { 0, 180 } do
			local z = if face == 0 then -0.9 else 0.9
			F.sign({
				Name = "GasText",
				Size = { 12, 5.6, 0.2 },
				Position = { 0, 21.5, z },
				Yaw = face,
				Color = "GasRed",
				Key = "Map.Gas.Sign",
				TextColor = "White",
			})
			F.sign({
				Name = "BuyOilText",
				Size = { 12.4, 3.6, 0.2 },
				Position = { 0, 14.25, z },
				Yaw = face,
				Color = "White",
				Key = "Map.Gas.BuyOil",
				TextColor = "GasRed",
			})
		end
		for _, x in { -3.5, 3.5 } do
			F.ball({ Name = "Shrub", Center = { x, 2.6, 0 }, Diameter = 2.4, Color = "Sage", Material = "Grass" })
		end
	end)
end

-- The car garage (where the Phase 2 garage shop goes): three roll-up doors under a teal sign.
function Buildings.garage(at: Vec, yaw: number)
	local F = Props.frame(at, yaw)
	B.model("Garage", function()
		F.box({
			Name = "Body",
			From = { -30, -0.5, 0 },
			To = { 30, 15, 26 },
			Color = "AdobeLight",
			Material = "Plaster",
			CastShadow = true,
		})
		F.box({
			Name = "Roof",
			From = { -31, 15, -1 },
			To = { 31, 16, 27 },
			Color = "MetalDark",
			Material = "CorrodedMetal",
		})
		F.box({ Name = "Parapet", From = { -31, 14, -0.8 }, To = { 31, 18.5, 0 }, Color = "MotelTeal" })
		F.sign({
			Name = "GarageSign",
			Size = { 28, 3.6, 0.3 },
			Position = { 0, 16.25, -0.95 },
			Color = "MotelTeal",
			Key = "Map.Garage.Sign",
			TextColor = "White",
		})
		for _, x in { -18, 0, 18 } do
			F.box({
				Name = "Door",
				From = { x - 6.5, 0.2, -0.3 },
				To = { x + 6.5, 11, 0 },
				Color = "Metal",
				Material = "Metal",
			})
			for y = 1.6, 10, 1.6 do
				F.box({
					Name = "Groove",
					From = { x - 6.5, y, -0.4 },
					To = { x + 6.5, y + 0.15, -0.3 },
					Color = "MetalDark",
				})
			end
			F.box({ Name = "Header", From = { x - 7, 11, -0.5 }, To = { x + 7, 11.8, 0 }, Color = "GasRed" })
		end
		for _, x in { -30.1, 30.1 } do
			F.box({
				Name = "SideWindow",
				From = { x - 0.1, 5, 8 },
				To = { x + 0.1, 10, 18 },
				Color = "Glass",
				Material = "Glass",
			})
		end
		F.box({ Name = "Toolbox", From = { 25, 0, -3.5 }, To = { 29, 4, -1.5 }, Color = "GasRed" })
	end)
	Props.tires(F.at(-34, 0, -3), 4)
	Props.tires(F.at(-34, 0, 2), 3)
	Props.drum(F.at(33, 0, -2), "Teal")
	Props.drum(F.at(33.5, 0, 1), "Rust")
end

-- A mobile home with a wooden stoop, a satellite dish and a propane tank. Anchor: the middle of its front wall.
function Buildings.trailer(at: Vec, yaw: number, stripe: string)
	local F = Props.frame(at, yaw)
	B.model("Trailer", function()
		F.box({ Name = "Skirt", From = { -20, -0.5, 0.5 }, To = { 20, 1.6, 12.5 }, Color = "MetalDark" })
		F.box({
			Name = "Body",
			From = { -21, 1.6, 0 },
			To = { 21, 9.6, 13 },
			Color = "White",
			Material = "Metal",
			CastShadow = true,
		})
		F.box({ Name = "Stripe", From = { -21.1, 5, -0.1 }, To = { 21.1, 6, 13.1 }, Color = stripe })
		F.box({ Name = "Roof", From = { -21.2, 9.6, -0.3 }, To = { 21.2, 10.2, 13.3 }, Color = "TankWhite" })
		for _, x in { -14, -2, 14 } do
			F.box({
				Name = "Window",
				From = { x - 2.5, 6.4, -0.2 },
				To = { x + 2.5, 8.6, 0 },
				Color = "Glass",
				Material = "Glass",
			})
		end
		F.box({ Name = "Door", From = { 4.5, 1.6, -0.2 }, To = { 8, 8.6, 0 }, Color = "Wood" })
		F.box({ Name = "Stoop", From = { 3.5, -0.5, -4 }, To = { 9, 1.6, 0 }, Color = "Wood", Material = "WoodPlanks" })
		F.part({
			Name = "Dish",
			Shape = "Cylinder",
			Size = { 0.4, 4, 4 },
			Position = { -15, 12, 7 },
			Rotation = { 0, 0, 35 },
			Color = "TankWhite",
		})
		F.part({
			Name = "PropaneTank",
			Shape = "Cylinder",
			Size = { 5, 2.6, 2.6 },
			Position = { 23.5, 1.3, 6 },
			Yaw = 90,
			Color = "White",
		})
		F.box({ Name = "Chair", From = { -8, -0.5, -4 }, To = { -6, 1.6, -2 }, Color = stripe })
	end)
end

-- The town's water tower: braced legs, a balcony, a tank with a red band and the game's name, and a climbable ladder.
function Buildings.waterTower(at: Vec)
	local F = Props.frame(at, 0)
	B.model("WaterTower", function()
		for _, x in { -7, 7 } do
			for _, z in { -7, 7 } do
				F.column({
					Name = "Leg",
					Base = { x, 0, z },
					Height = 36,
					Diameter = 1.4,
					Color = "Metal",
					Material = "Metal",
				})
			end
		end
		for _, yaw in { 0, 90, 180, 270 } do
			local G = Props.frame(F.at(0, 0, 0), yaw)
			for _, y in { 12, 24 } do
				G.box({
					Name = "Beam",
					From = { -7, y - 0.25, -7.25 },
					To = { 7, y + 0.25, -6.75 },
					Color = "MetalDark",
				})
				for _, sign in { -1, 1 } do
					G.part({
						Name = "Brace",
						Size = { 18.4, 0.35, 0.35 },
						Position = { 0, y - 6, -7 },
						Rotation = { 0, 0, sign * 40.6 },
						Color = "MetalDark",
					})
				end
			end
		end
		F.column({
			Name = "Pipe",
			Base = { 0, 0, 0 },
			Height = 36.4,
			Diameter = 1.6,
			Color = "Metal",
			Material = "Metal",
		})
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
			F.part({ Name = "Rail", Size = { 10.4, 0.3, 0.3 }, Position = { x, 39, z }, Yaw = angle, Color = "Metal" })
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
		F.ball({ Name = "Finial", Center = { 0, 58.6, 0 }, Diameter = 2.4, Color = "GasRed" })
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

-- A town gate: two adobe pillars, a beam and a hanging sign (SAFE ZONE outside, LEAVING SAFE ZONE inside). The
-- frame's front (-Z) faces out of town.
function Buildings.gate(at: Vec, yaw: number)
	local F = Props.frame(at, yaw)
	B.model("Gate", function()
		for _, x in { -23, 23 } do
			F.box({
				Name = "Pillar",
				From = { x - 3, -0.5, -3 },
				To = { x + 3, 15, 3 },
				Color = "Adobe",
				Material = "Plaster",
				CastShadow = true,
			})
			F.box({
				Name = "PillarCap",
				From = { x - 3.6, 15, -3.6 },
				To = { x + 3.6, 16.2, 3.6 },
				Color = "AdobeLight",
				Material = "Plaster",
			})
			F.box({
				Name = "Lantern",
				From = { x - 0.8, 11, -3.6 },
				To = { x + 0.8, 13, -3 },
				Color = "WarmLight",
				Material = "Neon",
			})
			F.box({
				Name = "Lantern",
				From = { x - 0.8, 11, 3 },
				To = { x + 0.8, 13, 3.6 },
				Color = "WarmLight",
				Material = "Neon",
			})
		end
		F.box({
			Name = "Beam",
			From = { -26, 16.2, -1 },
			To = { 26, 18.2, 1 },
			Color = "Wood",
			Material = "WoodPlanks",
			CastShadow = true,
		})
		for _, x in { -9, 9 } do
			F.box({ Name = "Chain", From = { x - 0.1, 15.6, -0.1 }, To = { x + 0.1, 16.2, 0.1 }, Color = "MetalDark" })
		end
		F.box({
			Name = "SignBoard",
			From = { -12, 11.2, -0.4 },
			To = { 12, 15.6, 0.4 },
			Color = "Wood",
			Material = "WoodPlanks",
		})
		F.sign({
			Name = "OutsideText",
			Size = { 23, 4, 0.2 },
			Position = { 0, 13.4, -0.55 },
			Color = "Wood",
			Material = "WoodPlanks",
			Key = "Map.Gate.Outside",
			TextColor = "OffWhite",
		})
		F.sign({
			Name = "InsideText",
			Size = { 23, 4, 0.2 },
			Position = { 0, 13.4, 0.55 },
			Yaw = 180,
			Color = "Wood",
			Material = "WoodPlanks",
			Key = "Map.Gate.Inside",
			TextColor = "OffWhite",
		})
	end)
end

-- A roadside billboard with the game's name on it, facing the frame's front (-Z).
function Buildings.billboard(at: Vec, yaw: number)
	local F = Props.frame(at, yaw)
	B.model("Billboard", function()
		for _, x in { -11, 11 } do
			F.column({ Name = "Post", Base = { x, -0.5, 1 }, Height = 25, Diameter = 1.4, Color = "Wood" })
		end
		F.part({ Name = "Brace", Size = { 0.6, 0.6, 26 }, Position = { 0, 6, 1 }, Yaw = 90, Color = "Wood" })
		F.box({ Name = "Back", From = { -16, 12, -0.4 }, To = { 16, 24, 0.4 }, Color = "White" })
		F.sign({
			Name = "Ad",
			Size = { 31, 11, 0.2 },
			Position = { 0, 18, -0.5 },
			Color = "MotelTeal",
			Key = "Game.Title",
			TextColor = "White",
		})
		F.box({
			Name = "Catwalk",
			From = { -16, 11.4, -2.6 },
			To = { 16, 12, -0.4 },
			Color = "Wood",
			Material = "WoodPlanks",
		})
		for _, x in { -10, 0, 10 } do
			F.box({ Name = "Lamp", From = { x - 0.6, 12, -3 }, To = { x + 0.6, 12.6, -2.4 }, Color = "MetalDark" })
		end
	end)
end

-- A farm windmill: a braced lattice tower with a 12-blade wheel and a tail vane.
function Buildings.windmill(at: Vec, yaw: number)
	local F = Props.frame(at, yaw)
	B.model("Windmill", function()
		for _, x in { -3, 3 } do
			for _, z in { -3, 3 } do
				F.box({
					Name = "Leg",
					From = { x - 0.3, -0.5, z - 0.3 },
					To = { x + 0.3, 30, z + 0.3 },
					Color = "Metal",
					Material = "Metal",
				})
			end
		end
		for _, y in { 8, 16, 24 } do
			F.box({ Name = "Ring", From = { -3.3, y, -3.3 }, To = { 3.3, y + 0.3, 3.3 }, Color = "MetalDark" })
		end
		F.box({
			Name = "Platform",
			From = { -3.6, 30, -3.6 },
			To = { 3.6, 30.6, 3.6 },
			Color = "Wood",
			Material = "WoodPlanks",
		})
		F.ball({ Name = "Hub", Center = { 0, 33, -2.6 }, Diameter = 1.6, Color = "MetalDark" })
		for blade = 0, 11 do
			local angle = blade * 30
			local x, y = Props.rotate(3.6, 0, -angle)
			F.part({
				Name = "Blade",
				Size = { 0.9, 5, 0.15 },
				Position = { x, 33 + y, -2.8 },
				Rotation = { 0, 0, angle - 90 },
				Color = if blade % 2 == 0 then "White" else "GasRed",
			})
		end
		F.box({ Name = "Tail", From = { -0.15, 31.5, 0 }, To = { 0.15, 34.5, 7 }, Color = "White" })
		F.box({ Name = "TailBoom", From = { -0.2, 32.8, -2 }, To = { 0.2, 33.2, 4 }, Color = "MetalDark" })
	end)
end

return Buildings
