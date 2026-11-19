--!strict
--[[
	The town in the middle of the desert (bible §5.1): the spawn and the safe zone, a square TownHalfSize studs from
	the center each way, inside a low adobe wall with a gate on each street.
	  - Two streets cross at a roundabout around the water tower.
	  - +X / +Z corner: the motel (players spawn on its welcome mats), its pool and neon sign, and the parking lot
	    with the 12 car spawn bays (tagged CarSpawn, cars face -Z toward the street).
	  - -X / +Z corner: the gas station, its 6 pump bays (tagged PumpBay: sell, refuel, repair), shop, oil tanks and
	    price sign.
	  - +X / -Z corner: the garage (the Phase 2 car shop). -X / -Z corner: trailers, a windmill and a billboard.
	Directions: the Builder's +Z is "North" and +X "East", a mirror of a compass (facing +Z, +X is on your *left*).
]]
local B = require("../lib/Builder")
local Buildings = require("../lib/Buildings")
local Props = require("../lib/Props")
local Rng = require("../lib/Rng")

local Layout = {}

Layout.Id = "Town"

local SEED = 4171
local STREET = 15 -- half width of the two main streets
local ROUND = 48 -- roundabout radius
-- Surface heights above the town ground, at least 0.1 studs apart so they never flicker: streets and lots, the
-- roundabout (laid over the street ends), and road markings.
local PAVED = 0.2
local ROUNDABOUT = 0.3
local MARKING = 0.35
local BAY_WIDTH = 11
local FIRST_BAY = 64 -- x of the first bay's left line

function Layout.build(map: any): any
	local half = map.TownHalfSize
	local edge = half - 4 -- lots stop inside the wall
	local rng = Rng.new(SEED)
	return B.root("Town", function()
		B.within(map.Origin, function()
			B.model("Streets", function()
				for _, yaw in { 0, 90, 180, 270 } do
					local F = Props.frame({ 0, 0, 0 }, yaw)
					F.box({
						Name = "Street",
						From = { -STREET, -0.5, -half },
						To = { STREET, PAVED, -(ROUND - 3) },
						Color = "Asphalt",
						Material = "Asphalt",
					})
					for _, x in { -(STREET - 1.4), STREET - 1.4 } do
						F.box({
							Name = "EdgeLine",
							From = { x - 0.2, PAVED, -half },
							To = { x + 0.2, MARKING, -(ROUND + 2) },
							Color = "White",
						})
					end
					for z = ROUND + 6, half - 6, 10 do
						F.box({
							Name = "Dash",
							From = { -0.3, PAVED, -z - 2.5 },
							To = { 0.3, MARKING, -z + 2.5 },
							Color = "RoadLine",
						})
					end
					Props.streetLight(F.at(STREET + 3, PAVED, -(ROUND + 40)), yaw + 90)
					Props.streetLight(F.at(-(STREET + 3), PAVED, -(ROUND + 110)), yaw - 90)
				end
				local F = Props.frame({ 0, 0, 0 }, 0)
				F.column({
					Name = "Roundabout",
					Base = { 0, -0.5, 0 },
					Height = ROUNDABOUT + 0.5,
					Diameter = ROUND * 2,
					Color = "Asphalt",
					Material = "Asphalt",
				})
				F.column({
					Name = "IslandCurb",
					Base = { 0, -0.5, 0 },
					Height = 1.5,
					Diameter = 46,
					Color = "ConcreteLight",
				})
				F.column({
					Name = "Island",
					Base = { 0, -0.5, 0 },
					Height = 1.6,
					Diameter = 43,
					Color = "SandLight",
					Material = "Sand",
				})
			end)

			Buildings.waterTower({ 0, 1.1, 0 })
			Props.saguaro({ 15, 1.1, 6 }, 14, 30, rng)
			Props.saguaro({ -11, 1.1, -14 }, 11, 200, rng)
			Props.barrelCactus({ -15, 1.1, 8 }, 2.4)
			Props.barrelCactus({ 9, 1.1, -16 }, 2)

			B.model("Walls", function()
				for _, yaw in { 0, 90, 180, 270 } do
					local F = Props.frame({ 0, 0, 0 }, yaw)
					for _, side in { -1, 1 } do
						local x0, x1 = math.min(side * 26, side * half), math.max(side * 26, side * half)
						F.box({
							Name = "Wall",
							From = { x0, -0.5, -half },
							To = { x1, 4, -half + 2 },
							Color = "Adobe",
							Material = "Plaster",
						})
						F.box({
							Name = "WallCap",
							From = { x0, 4, -half - 0.3 },
							To = { x1, 4.6, -half + 2.3 },
							Color = "AdobeLight",
							Material = "Plaster",
						})
						for x = 50, half, 25 do
							F.box({
								Name = "WallPost",
								From = { side * x - 1.3, -0.5, -half - 0.4 },
								To = { side * x + 1.3, 5.6, -half + 2.4 },
								Color = "AdobeLight",
								Material = "Plaster",
							})
						end
					end
					Buildings.gate(F.at(0, 0, -half + 1), yaw)
				end
			end)

			-- Motel corner (+X, +Z)
			B.model("MotelLot", function()
				local F = Props.frame({ 0, 0, 0 }, 0)
				F.box({
					Name = "Lot",
					From = { STREET, -0.5, STREET },
					To = { edge, PAVED, 139 },
					Color = "Asphalt",
					Material = "Asphalt",
				})
				for line = 0, 12 do
					local x = FIRST_BAY + line * BAY_WIDTH
					F.box({
						Name = "BayLine",
						From = { x - 0.25, PAVED, 100 },
						To = { x + 0.25, MARKING, 121 },
						Color = "White",
					})
				end
				for bay = 1, map.CarSpawns do
					local x = FIRST_BAY + (bay - 0.5) * BAY_WIDTH
					F.box({
						Name = "WheelStop",
						From = { x - 3, PAVED, 119.5 },
						To = { x + 3, PAVED + 0.6, 120.5 },
						Color = "ConcreteLight",
					})
					F.marker("CarSpawn", `CarSpawn{bay}`, { x, PAVED, 110 }, { Index = bay })
				end
				for _, x in { 60, 130, 190 } do
					Props.streetLight({ x, PAVED, 130 }, 0)
				end
			end)
			Buildings.motel({ 110, 0, 148 }, 0)
			Buildings.pool({ 38, 0.1, 40 }, 0)
			Buildings.motelSign({ 26, 0.1, 19 }, 0)

			-- Gas station corner (-X, +Z)
			B.model("GasLot", function()
				Props.frame({ 0, 0, 0 }, 0).box({
					Name = "Lot",
					From = { -edge, -0.5, STREET },
					To = { -STREET, PAVED, edge },
					Color = "Asphalt",
					Material = "Asphalt",
				})
			end)
			Buildings.gasStation({ -105, 0.1, 70 }, 0)
			Buildings.gasSign({ -28, 0.1, 26 }, -45)
			Props.drum({ -178, 0.1, 110 }, "GasRed")
			Props.drum({ -181, 0.1, 113 }, "Teal")
			Props.drum({ -177.5, 0.1, 115.5 }, "GasRed")

			-- Garage corner (+X, -Z)
			B.model("GarageApron", function()
				Props.frame({ 0, 0, 0 }, 0).box({
					Name = "Apron",
					From = { 60, -0.5, -60 },
					To = { 160, PAVED, -STREET },
					Color = "ConcreteLight",
					Material = "Concrete",
				})
			end)
			Buildings.garage({ 110, 0.2, -60 }, 180)
			Props.oldCar({ 145, 0.2, -38 }, 30, "MotelTeal")
			Props.oldCar({ 180, 0, -150 }, -70, "Rust")

			-- Yard corner (-X, -Z)
			Buildings.trailer({ -80, 0, -70 }, 180, "MotelTeal")
			Buildings.trailer({ -150, 0, -125 }, 90, "MotelPink")
			Buildings.windmill({ -165, 0, -45 }, 20)
			Buildings.billboard({ -60, 0, -30 }, 180)
			Props.oldCar({ -175, 0, -175 }, 20, "Rust")
			Props.oldCar({ -150, 0, -182 }, -60, "GasRed")
			Props.tires({ -130, 0, -176 }, 5)
			for _, at in { { -110, -150 }, { -40, -120 }, { -60, -175 }, { -185, -95 }, { 100, -150 }, { 60, -120 } } do
				Props.saguaro({ at[1], 0, at[2] }, rng:range(10, 18), rng:range(0, 360), rng)
				Props.bush({ at[1] + 6, 0, at[2] - 4 }, rng:range(2.5, 4), rng)
			end
		end)
	end, { MapId = Layout.Id })
end

return Layout
