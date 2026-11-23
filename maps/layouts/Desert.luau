--!strict
--[[
	The whole map (bible §5.1, owner 2026-11-23: no town): one square of desert Size studs wide.
	  - Ground: an open sand center (CenterHalfSize, where players spawn on 4 pads, nothing else there) plus one ring
	    per zone (Scrublands, Mesa Flats, Badlands), each its own sand color, and an invisible wall on the border.
	    Persistent, so it never streams out under a fast car.
	  - Two dirt roads crossing in the middle out to the cliffs, a ring road on the first zone border and telephone
	    poles along the roads (no signs or ramps: owner, 2026-11-23).
	  - Mesas, boulders, saguaros, barrel cacti, sage bushes and dead trees, more rock and fewer plants toward the
	    edge, and a ring of tall cliffs on the border.
	Oil barrels are not part of the map: Services/OilService scatters them at random while the game runs.
	Everything random comes from one seeded Rng, so every build makes the same map.
]]
local B = require("../lib/Builder")
local Props = require("../lib/Props")
local Rng = require("../lib/Rng")

type Vec = B.Vec

local Layout = {}

Layout.Id = "Desert"

local SEED = 20261119
local ROAD = 12 -- half width of the two crossing dirt roads
local RING_ROAD = 10 -- half width of the ring road
local CLIFF = 125 -- the edge cliffs (and their scree) reach this far in from the border; nothing else goes there
-- Road tops sit this far above the ground, and the tire tracks are strips laid beside the road strips (not on top),
-- so no two visible surfaces share a height closer than 0.2 studs (closer ones flicker from a distance).
local ROAD_TOP = 0.2
local TRACKS = { -ROAD, -5.7, -3.3, 3.3, 5.7, ROAD } -- strip edges across a road: road, track, road, track, road

-- How each zone looks: ground, how many of each prop, mesa sizes (radius, height ranges).
local LOOKS: { [string]: any } = {
	Scrublands = {
		Ground = { "Sand", "Sand" },
		Mesas = 6,
		MesaRadius = { 12, 22 },
		MesaHeight = { 18, 34 },
		Saguaros = 45,
		BarrelCacti = 30,
		Bushes = 90,
		Boulders = 30,
		DeadTrees = 0,
	},
	MesaFlats = {
		Ground = { "SandDark", "Sand" },
		Mesas = 14,
		MesaRadius = { 22, 45 },
		MesaHeight = { 35, 75 },
		Saguaros = 40,
		BarrelCacti = 25,
		Bushes = 60,
		Boulders = 40,
		DeadTrees = 5,
	},
	Badlands = {
		Ground = { "Badland", "Ground" },
		Mesas = 8,
		MesaRadius = { 18, 32 },
		MesaHeight = { 45, 85 },
		Saguaros = 12,
		BarrelCacti = 10,
		Bushes = 30,
		Boulders = 50,
		DeadTrees = 16,
	},
}

-- The 4 road arms from the middle: each frame's -Z points away from the center.
local ROAD_YAWS = { 0, 90, 180, 270 }

function Layout.build(map: any): any
	local rng = Rng.new(SEED)
	local half = map.Size / 2
	local center = map.CenterHalfSize
	local ring = map.Zones[1].MaxDistance
	local reach = half - CLIFF -- nothing but cliffs past this distance from the center
	local occupied: { { number } } = {} -- { x, z, radius } of every solid thing placed so far

	local function distance(x: number, z: number): number
		return math.max(math.abs(x), math.abs(z))
	end

	local function roadDistance(x: number, z: number): number
		return math.min(math.abs(distance(x, z) - ring), math.abs(x), math.abs(z))
	end

	-- Whether a thing `radius` wide fits at (x, z): out of the open center, off the cliffs, `roadGap` clear of roads.
	local function free(x: number, z: number, radius: number, roadGap: number): boolean
		local d = distance(x, z)
		if d - radius < center + 20 or d + radius > reach or roadDistance(x, z) < radius + roadGap then
			return false
		end
		for _, other in occupied do
			local dx, dz = x - other[1], z - other[2]
			if dx * dx + dz * dz < (radius + other[3]) ^ 2 then
				return false
			end
		end
		return true
	end

	-- A random free place whose center is between `inner` and `outer` from the center (nil when none is found).
	local function place(inner: number, outer: number, radius: number, roadGap: number): (number?, number?)
		for _ = 1, 500 do
			local x, z = rng:range(-outer, outer), rng:range(-outer, outer)
			local d = distance(x, z)
			if d >= inner and d <= outer and free(x, z, radius, roadGap) then
				return x, z
			end
		end
		return nil, nil
	end

	local function zoneBounds(index: number): (number, number)
		local inner = if index == 1 then center else map.Zones[index - 1].MaxDistance
		return inner, math.min(map.Zones[index].MaxDistance, reach)
	end

	return B.root("Desert", function()
		B.within(map.Origin, function()
			local ground = B.model("Ground", function()
				local F = Props.frame({ 0, 0, 0 }, 0)
				F.box({
					Name = "Center",
					From = { -center, -8, -center },
					To = { center, 0, center },
					Color = "Sand",
					Material = "Sand",
				})
				for index, zone in map.Zones do
					local inner = if index == 1 then center else map.Zones[index - 1].MaxDistance
					local outer = zone.MaxDistance
					local look = LOOKS[zone.Id]
					for _, strip in
						{
							{ { -outer, -8, inner }, { outer, 0, outer } },
							{ { -outer, -8, -outer }, { outer, 0, -inner } },
							{ { inner, -8, -inner }, { outer, 0, inner } },
							{ { -outer, -8, -inner }, { -inner, 0, inner } },
						}
					do
						F.box({
							Name = zone.Id,
							From = strip[1],
							To = strip[2],
							Color = look.Ground[1],
							Material = look.Ground[2],
						})
					end
				end
				for _, wall in
					{
						{ { -half, -8, half }, { half, 300, half + 4 } },
						{ { -half, -8, -half - 4 }, { half, 300, -half } },
						{ { half, -8, -half }, { half + 4, 300, half } },
						{ { -half - 4, -8, -half }, { -half, 300, half } },
					}
				do
					F.box({
						Name = "EdgeWall",
						From = wall[1],
						To = wall[2],
						Color = "Sand",
						Transparency = 1,
						CastShadow = false,
					})
				end
			end)
			ground.ModelStreamingMode = B.Enum.ModelStreamingMode.Persistent

			B.model("Roads", function()
				for _, yaw in ROAD_YAWS do
					local F = Props.frame({ 0, 0, 0 }, yaw)
					-- The north-south road runs through the middle; the east-west arms stop at its edges (no overlap).
					local start = if yaw % 180 == 0 then 0 else ROAD
					for _, piece in { { start, ring - RING_ROAD }, { ring + RING_ROAD, half - 40 } } do
						for strip = 1, #TRACKS - 1 do
							local track = strip % 2 == 0
							F.box({
								Name = if track then "Rut" else "Road",
								From = { TRACKS[strip], -0.5, -piece[2] },
								To = { TRACKS[strip + 1], ROAD_TOP, -piece[1] },
								Color = if track then "DirtRut" else "DirtRoad",
								Material = "Ground",
							})
						end
					end
					-- The ring road side this frame faces (-Z), from corner to corner (the X sides stop short of the
					-- corners so the pieces never overlap).
					local long = yaw % 180 == 0
					local span = if long then ring + RING_ROAD else ring - RING_ROAD
					F.box({
						Name = "RingRoad",
						From = { -span, -0.5, -ring - RING_ROAD },
						To = { span, ROAD_TOP, -ring + RING_ROAD },
						Color = "DirtRoad",
						Material = "Ground",
					})
				end
			end)

			B.model("Roadside", function()
				for _, yaw in ROAD_YAWS do
					local F = Props.frame({ 0, 0, 0 }, yaw)
					local previous: { Vec }? = nil
					local count = 0
					for d = center + 30, reach - 10, 76 do
						if math.abs(d - ring) > RING_ROAD + 8 then
							count += 1
							local left, right = Props.pole(F.at(ROAD + 6, 0, -d), yaw, count % 4 == 0)
							if previous then
								Props.wire(previous[1], left, 0.15, "Black")
								Props.wire(previous[2], right, 0.15, "Black")
							end
							previous = { left, right }
							local at = F.at(ROAD + 6, 0, -d)
							table.insert(occupied, { at[1], at[3], 3 })
						end
					end
				end
			end)

			-- Player spawn pads in the open center, one in each corner between the roads.
			B.model("Spawn", function()
				for index, at in { { 30, 30 }, { -30, 30 }, { 30, -30 }, { -30, -30 } } do
					B.spawnLocation({
						Name = `SpawnPad{index}`,
						Size = { 8, 0.4, 8 },
						Position = { at[1], 0, at[2] },
						Color = "SandDark",
						Material = "Sand",
					})
				end
			end)

			B.model("Mesas", function()
				for zoneIndex, zone in map.Zones do
					local look = LOOKS[zone.Id]
					local inner, outer = zoneBounds(zoneIndex)
					for _ = 1, look.Mesas do
						local radius = rng:range(look.MesaRadius[1], look.MesaRadius[2])
						local height = rng:range(look.MesaHeight[1], look.MesaHeight[2])
						local footprint = radius + height * 0.3 + 6
						local x, z = place(inner, outer, footprint, 10)
						if x and z then
							table.insert(occupied, { x, z, footprint })
							local mesa = Props.mesa({ x, 0, z }, radius, height, rng:range(0, 180), rng)
							mesa.LevelOfDetail = B.Enum.ModelLevelOfDetail.StreamingMesh
						end
					end
				end
			end)

			B.model("Rocks", function()
				for zoneIndex, zone in map.Zones do
					local inner, outer = zoneBounds(zoneIndex)
					for _ = 1, LOOKS[zone.Id].Boulders do
						local size = rng:range(3, 14)
						local x, z = place(inner, outer, size * 0.7, ROAD + 2)
						if x and z then
							table.insert(occupied, { x, z, size * 0.7 })
							Props.boulder({ x, 0, z }, size, rng:range(0, 360), rng)
						end
					end
				end
			end)

			B.model("Plants", function()
				for zoneIndex, zone in map.Zones do
					local look = LOOKS[zone.Id]
					local inner, outer = zoneBounds(zoneIndex)
					for _ = 1, look.Saguaros do
						local x, z = place(inner, outer, 3, ROAD + 2)
						if x and z then
							table.insert(occupied, { x, z, 3 })
							Props.saguaro({ x, 0, z }, rng:range(10, 22), rng:range(0, 360), rng)
						end
					end
					for _ = 1, look.DeadTrees do
						local x, z = place(inner, outer, 4, ROAD + 2)
						if x and z then
							table.insert(occupied, { x, z, 4 })
							Props.deadTree({ x, 0, z }, rng:range(8, 15), rng:range(0, 360), rng)
						end
					end
					for _ = 1, look.BarrelCacti do
						local x, z = place(inner, outer, 1.5, ROAD + 1)
						if x and z then
							table.insert(occupied, { x, z, 1.5 })
							Props.barrelCactus({ x, 0, z }, rng:range(1.6, 3))
						end
					end
					for _ = 1, look.Bushes do
						local x, z = place(inner, outer, 1, ROAD)
						if x and z then
							Props.bush({ x, 0, z }, rng:range(2.5, 5), rng)
						end
					end
				end
			end)

			B.model("Cliffs", function()
				-- Neighbouring cliffs get height offsets 0.25+ apart so their tops never line up (Props.cliff).
				for side, yaw in ROAD_YAWS do
					local along = -half - 20
					local odd = false
					while along < half + 20 do
						local length = rng:range(70, 120)
						local at = Props.frame({ 0, 0, 0 }, yaw).at(along + length / 2, 0, -half)
						local offset = (if odd then 0.5 else 0) + (side % 2) * 0.25
						local cliff =
							Props.cliff(at, length + 16, rng:range(45, 75), rng:range(70, 150), yaw + 180, rng, offset)
						odd = not odd
						cliff.LevelOfDetail = B.Enum.ModelLevelOfDetail.StreamingMesh
						along += length
					end
				end
			end)
		end)
	end, { MapId = Layout.Id })
end

return Layout
