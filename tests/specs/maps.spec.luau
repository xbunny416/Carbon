--!strict
-- The committed map models match their layouts, and the maps have what the game needs (bible §5.1).
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local Roblox = require("../roblox")
local expect = require("../expect")

local Desert = require("../../maps/layouts/Desert")
local Town = require("../../maps/layouts/Town")

local Config = Roblox.require(Roblox.game.ReplicatedStorage.Shared.Config)
local map = Config.World.Map

local function tagged(root: any, tag: string): { any }
	local found = {}
	for _, instance in root:GetDescendants() do
		if instance:HasTag(tag) then
			table.insert(found, instance)
		end
	end
	return found
end

-- Distance from the map center the zones use: max(|x|, |z|).
local function distance(part: any): number
	local position = part.CFrame.Position - roblox.Vector3.new(map.Origin[1], map.Origin[2], map.Origin[3])
	return math.max(math.abs(position.X), math.abs(position.Z))
end

local desert = Desert.build(map)
local town = Town.build(map)

-- Upward faces (tops) of the axis-aligned blocks in `roots`: { y, x0, x1, z0, z1, color, name }.
local function tops(roots: { any }): { { any } }
	local found = {}
	for _, root in roots do
		for _, part in root:GetDescendants() do
			local block = part.ClassName == "SpawnLocation" or (part.ClassName == "Part" and part.Shape.Name == "Block")
			if block and part.Transparency < 0.99 then
				local cf, size = part.CFrame, part.Size
				local aligned = true
				local extent = { 0, 0, 0 }
				for _, axis in { cf.RightVector * size.X / 2, cf.UpVector * size.Y / 2, cf.LookVector * size.Z / 2 } do
					local biggest = math.max(math.abs(axis.X), math.abs(axis.Y), math.abs(axis.Z))
					if biggest < axis.Magnitude * 0.9999 then
						aligned = false
					end
					extent[1] += math.abs(axis.X)
					extent[2] += math.abs(axis.Y)
					extent[3] += math.abs(axis.Z)
				end
				if aligned then
					local c = cf.Position
					table.insert(found, {
						c.Y + extent[2],
						c.X - extent[1],
						c.X + extent[1],
						c.Z - extent[3],
						c.Z + extent[3],
						part.Color:ToHex(),
						part:GetFullName(),
					})
				end
			end
		end
	end
	table.sort(found, function(a: { any }, b: { any }): boolean
		return a[1] < b[1]
	end)
	return found
end

return {
	["generated .rbxmx files are up to date (run: lune run maps/build)"] = function()
		for file, model in { ["Desert.rbxmx"] = desert, ["Town.rbxmx"] = town } do
			local path = `maps/generated/{file}`
			expect.truthy(fs.isFile(path), `{path} exists`)
			expect.equal(fs.readFile(path) == roblox.serializeModel({ model }, true), true, path)
		end
	end,
	["the town has a car spawn bay per player and the pump bays, all inside the safe zone"] = function()
		expect.equal(map.CarSpawns, Config.World.MaxPlayers, "car spawns = max players")
		local spawns, bays = tagged(town, "CarSpawn"), tagged(town, "PumpBay")
		expect.equal(#spawns, map.CarSpawns, "CarSpawn markers")
		expect.equal(#bays, map.PumpBays, "PumpBay markers")
		for _, marker in table.move(bays, 1, #bays, #spawns + 1, table.clone(spawns)) do
			expect.truthy(distance(marker) < map.TownHalfSize, `{marker.Name} in town`)
			expect.truthy(type(marker:GetAttribute("Index")) == "number", `{marker.Name} Index`)
		end
	end,
	["players spawn in town"] = function()
		local count = 0
		for _, instance in town:GetDescendants() do
			if instance.ClassName == "SpawnLocation" then
				count += 1
				expect.truthy(distance(instance) < map.TownHalfSize, `{instance.Name} in town`)
			end
		end
		expect.truthy(count >= 1, "spawn locations")
	end,
	["each zone has its oil spots, inside its ring and spaced apart"] = function()
		local spots = tagged(desert, "OilSpot")
		local perZone: { [string]: number } = {}
		local inner = map.TownHalfSize
		local bounds: { [string]: { number } } = {}
		for _, zone in map.Zones do
			bounds[zone.Id] = { inner, zone.MaxDistance }
			inner = zone.MaxDistance
		end
		for _, spot in spots do
			local zone = spot:GetAttribute("Zone")
			local ring = bounds[zone]
			expect.truthy(ring ~= nil, `{spot.Name} zone {zone}`)
			local d = distance(spot)
			expect.truthy(d > ring[1] and d <= ring[2], `{spot.Name} at {d} inside {zone}`)
			perZone[zone] = (perZone[zone] or 0) + 1
			for _, other in spots do
				if other ~= spot then
					local gap = (spot.CFrame.Position - other.CFrame.Position).Magnitude
					expect.truthy(gap >= map.OilSpotSpacing - 0.01, `{spot.Name} and {other.Name} {gap} apart`)
				end
			end
		end
		for _, zone in map.Zones do
			expect.equal(perZone[zone.Id] or 0, zone.OilSpots, `{zone.Id} oil spots`)
		end
	end,
	["no two differently colored tops overlap at (almost) the same height — they would flicker"] = function()
		local faces = tops({ desert, town })
		local problems: { string } = {}
		for i, a in faces do
			local j = i + 1
			while j <= #faces and faces[j][1] - a[1] < 0.06 do
				local b = faces[j]
				local overlapX = math.min(a[3], b[3]) - math.max(a[2], b[2])
				local overlapZ = math.min(a[5], b[5]) - math.max(a[4], b[4])
				if a[6] ~= b[6] and overlapX > 0.05 and overlapZ > 0.05 then
					table.insert(problems, `{a[7]} and {b[7]} at y {a[1]}`)
				end
				j += 1
			end
		end
		expect.equal(#problems, 0, table.concat(problems, "; "))
	end,
	["the ground is above Y = 0, so a Studio Baseplate left in the place hides under it"] = function()
		expect.truthy(map.Origin[2] >= 0.5, "map origin height")
	end,
	["the ground is persistent and covers the whole map"] = function()
		local ground = desert:FindFirstChild("Ground")
		expect.truthy(ground ~= nil, "Ground model")
		expect.equal(ground.ModelStreamingMode, roblox.Enum.ModelStreamingMode.Persistent)
		local area = 0
		for _, part in ground:GetChildren() do
			if part.Name ~= "EdgeWall" then
				area += part.Size.X * part.Size.Z
				expect.truthy(
					part.Size.X <= 2048 and part.Size.Z <= 2048,
					`{part.Name} within Roblox's part size limit`
				)
			end
		end
		expect.equal(area, map.Size * map.Size, "ground area")
	end,
}
