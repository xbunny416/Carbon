--!strict
--[[
	Props — reusable many-part pieces for CarOff's desert maps: a turned building frame, cacti, bushes, rocks, mesas,
	edge cliffs, telephone poles, jump ramps, signposts, old car wrecks, drums and tires.

	Positions are studs from the current Builder origin and yaws are degrees around Y. `Props.frame(at, yaw)` builds
	an assembly in its own frame: local -Z is its front, and the whole frame is turned `yaw` degrees (0 = front faces
	-Z, 180 = +Z, 90 = -X, -90 = +X). Random sizes come from the caller's Rng, so the same seed builds the same map.
]]
local B = require("./Builder")
local Rng = require("./Rng")

type Vec = B.Vec

local Props = {}

local function snap(value: number): number
	return math.floor(value * 1000 + 0.5) / 1000
end

local function trig(yaw: number): (number, number)
	local r = math.rad(yaw)
	return math.floor(math.cos(r) * 1e9 + 0.5) / 1e9, math.floor(math.sin(r) * 1e9 + 0.5) / 1e9
end

-- Turns an offset (x, z) by `yaw` degrees around Y, the same way CFrame.Angles(0, yaw, 0) turns a part.
function Props.rotate(x: number, z: number, yaw: number): (number, number)
	local c, s = trig(yaw)
	return snap(x * c + z * s), snap(-x * s + z * c)
end

local function totalYaw(yaw: number): number?
	return if yaw % 360 == 0 then nil else yaw
end

export type Frame = {
	spec: (spec: any) -> any,
	part: (spec: any) -> any,
	box: (spec: any) -> any,
	column: (spec: any) -> any,
	ball: (spec: any) -> any,
	sign: (spec: any) -> any,
	truss: (spec: any) -> any,
	spawn: (spec: any) -> any,
	marker: (tag: string, name: string, position: Vec, attributes: { [string]: any }?, facing: number?) -> any,
	at: (x: number, y: number, z: number) -> Vec,
}

-- Builds parts relative to `at`, in a frame turned `yaw` degrees around Y.
function Props.frame(at: Vec, yaw: number): Frame
	local F = {} :: Frame

	-- A world-space position for a point given in the frame.
	function F.at(x: number, y: number, z: number): Vec
		local rx, rz = Props.rotate(x, z, yaw)
		return { at[1] + rx, at[2] + y, at[3] + rz }
	end

	-- A part spec moved into the frame (its Rotation stays local, applied after the yaw).
	function F.spec(spec: any): any
		local copy = table.clone(spec)
		copy.Position = F.at(spec.Position[1], spec.Position[2], spec.Position[3])
		copy.Yaw = totalYaw((spec.Yaw or 0) + yaw)
		return copy
	end

	function F.part(spec: any): any
		return B.part(F.spec(spec))
	end

	-- A box between two corners: From = { x, y, z } and To = { x, y, z } instead of Size and Position.
	function F.box(spec: any): any
		local from, to = spec.From, spec.To
		local copy = table.clone(spec)
		copy.From, copy.To = nil, nil
		copy.Size = { math.abs(to[1] - from[1]), math.abs(to[2] - from[2]), math.abs(to[3] - from[3]) }
		copy.Position = { (from[1] + to[1]) / 2, (from[2] + to[2]) / 2, (from[3] + to[3]) / 2 }
		return F.part(copy)
	end

	-- An upright cylinder standing on Base = { x, y, z }, Height tall and Diameter wide.
	function F.column(spec: any): any
		local copy = table.clone(spec)
		local base = spec.Base
		copy.Base, copy.Height, copy.Diameter = nil, nil, nil
		copy.Shape = "Cylinder"
		copy.Size = { spec.Height, spec.Diameter, spec.Diameter }
		copy.Position = { base[1], base[2] + spec.Height / 2, base[3] }
		copy.Rotation = { 0, 0, 90 }
		return F.part(copy)
	end

	-- A ball at Center = { x, y, z }, Diameter wide.
	function F.ball(spec: any): any
		local copy = table.clone(spec)
		copy.Center, copy.Diameter = nil, nil
		copy.Shape = "Ball"
		copy.Size = { spec.Diameter, spec.Diameter, spec.Diameter }
		copy.Position = spec.Center
		return F.part(copy)
	end

	function F.sign(spec: any): any
		return B.sign(F.spec(spec))
	end

	function F.truss(spec: any): any
		return B.truss(F.spec(spec))
	end

	function F.spawn(spec: any): any
		return B.spawnLocation(F.spec(spec))
	end

	-- A gameplay marker; `facing` is the yaw (in the frame) the thing it marks should face.
	function F.marker(tag: string, name: string, position: Vec, attributes: { [string]: any }?, facing: number?): any
		local turned = totalYaw((facing or 0) + yaw)
		return B.marker(tag, name, F.at(position[1], position[2], position[3]), attributes, turned and { 0, turned, 0 })
	end

	return F
end

-- A straight wire (or rail) between two points at the same height.
function Props.wire(from: Vec, to: Vec, thickness: number, color: string): any
	local dx, dz = to[1] - from[1], to[3] - from[3]
	local length = math.sqrt(dx * dx + dz * dz)
	return B.part({
		Name = "Wire",
		Size = { thickness, thickness, snap(length) },
		Position = { (from[1] + to[1]) / 2, (from[2] + to[2]) / 2, (from[3] + to[3]) / 2 },
		Yaw = snap(math.deg(math.atan2(dx, dz))),
		Color = color,
		CanCollide = false,
		CastShadow = false,
	})
end

-- A saguaro in blocks: a square trunk with a darker rib strip, a narrower cap and 0-3 elbowed arms. Solid (cars crash
-- into it).
function Props.saguaro(at: Vec, height: number, yaw: number, rng: Rng.Rng)
	local F = Props.frame(at, yaw)
	local d = math.clamp(snap(height * 0.12), 1.4, 2.6)
	B.model("Saguaro", function()
		F.box({ Name = "Trunk", From = { -d / 2, -0.5, -d / 2 }, To = { d / 2, height, d / 2 }, Color = "Cactus" })
		F.box({
			Name = "Rib",
			From = { -d * 0.2, 0, -d / 2 - 0.15 },
			To = { d * 0.2, height - 0.3, -d / 2 },
			Color = "CactusDark",
		})
		F.box({
			Name = "Top",
			From = { -d * 0.4, height, -d * 0.4 },
			To = { d * 0.4, height + 0.6, d * 0.4 },
			Color = "Cactus",
		})
		local arms = rng:int(0, 3)
		for index = 1, arms do
			local armYaw = if index == 3 then 90 else 0
			local side = if index == 2 then -1 else 1
			local armY = rng:range(height * 0.35, height * 0.6)
			local reach = rng:range(1.8, 3)
			local rise = rng:range(height * 0.18, height * 0.32)
			local a = snap(d * 0.7) / 2
			local G = Props.frame(F.at(0, 0, 0), yaw + armYaw)
			local tip = side * (d / 2 + reach)
			G.box({
				Name = "Arm",
				From = { math.min(0, tip), armY - a, -a },
				To = { math.max(0, tip), armY + a, a },
				Color = "Cactus",
			})
			G.box({
				Name = "ArmUp",
				From = { tip - side * a * 2, armY - a, -a },
				To = { tip, armY + rise, a },
				Color = "Cactus",
			})
		end
	end)
end

-- A small barrel cactus: a squat block with a pink flower on top.
function Props.barrelCactus(at: Vec, size: number)
	local F = Props.frame(at, 0)
	local h = size / 2
	B.model("BarrelCactus", function()
		F.box({ Name = "Body", From = { -h, -0.2, -h }, To = { h, size * 0.7, h }, Color = "Cactus" })
		F.box({
			Name = "Flower",
			From = { -h * 0.3, size * 0.7, -h * 0.3 },
			To = { h * 0.3, size * 0.85, h * 0.3 },
			Color = "Flower",
		})
	end)
end

-- A sage bush: 2-3 offset leafy cubes, each turned a little (cars drive through it).
function Props.bush(at: Vec, size: number, rng: Rng.Rng)
	B.model("Bush", function()
		for index = 1, rng:int(2, 3) do
			local s = snap(size * rng:range(0.6, 1))
			local x, z = rng:range(-size * 0.4, size * 0.4), rng:range(-size * 0.4, size * 0.4)
			Props.frame(at, index * 25).box({
				Name = "Leaves",
				From = { x - s / 2, -0.1, z - s / 2 },
				To = { x + s / 2, s * 0.7, z + s / 2 },
				Color = if index == 1 then "Sage" else "SageDark",
				Material = "LeafyGrass",
				CanCollide = false,
			})
		end
	end)
end

-- A boulder: a tilted rock with a smaller one leaning on it.
function Props.boulder(at: Vec, size: number, yaw: number, rng: Rng.Rng)
	local F = Props.frame(at, yaw)
	B.model("Boulder", function()
		F.part({
			Name = "Rock",
			Size = { size, snap(size * 0.7), snap(size * 0.85) },
			Position = { 0, size * 0.22, 0 },
			Rotation = { rng:range(-12, 12), rng:range(0, 90), rng:range(-12, 12) },
			Color = "Boulder",
			Material = "Rock",
		})
		local small = snap(size * rng:range(0.35, 0.55))
		F.part({
			Name = "Rock",
			Size = { small, snap(small * 0.8), small },
			Position = { size * 0.5, small * 0.3, rng:range(-size * 0.3, size * 0.3) },
			Rotation = { rng:range(-20, 20), rng:range(0, 90), rng:range(-20, 20) },
			Color = "MesaDark",
			Material = "Rock",
		})
	end)
end

-- A dead desert tree: a bare trunk and a few crooked branches.
function Props.deadTree(at: Vec, height: number, yaw: number, rng: Rng.Rng)
	local F = Props.frame(at, yaw)
	B.model("DeadTree", function()
		F.column({ Name = "Trunk", Base = { 0, -0.5, 0 }, Height = height + 0.5, Diameter = 1.2, Color = "DeadWood" })
		for index = 1, 3 do
			local angle = (index - 2) * 40 + rng:range(-10, 10)
			local length = rng:range(height * 0.3, height * 0.5)
			local y = height * (0.55 + 0.15 * index)
			local x, z = Props.rotate(length * 0.4, 0, index * 120)
			F.part({
				Name = "Branch",
				Size = { 0.6, length, 0.6 },
				Position = { x, y, z },
				Yaw = index * 120,
				Rotation = { 0, 0, -math.abs(angle) - 25 },
				Color = "DeadWood",
				CanCollide = false,
			})
		end
	end)
end

--[[
	A mesa: stacked rock layers that get smaller toward the top, a dark caprock and scree slopes leaning on some
	sides. `radius` is half its width; it is a bit narrower in depth.
]]
function Props.mesa(at: Vec, radius: number, height: number, yaw: number, rng: Rng.Rng)
	local F = Props.frame(at, yaw)
	local aspect = rng:range(0.6, 1)
	local layers = rng:int(3, 4)
	local colors = { "Sandstone", "Mesa", "MesaLight", "Mesa" }
	local model = B.model("Mesa", function()
		local width, depth = radius * 2, snap(radius * 2 * aspect)
		local y = -1
		local lastW, lastD, lastX, lastZ = width, depth, 0, 0
		for layer = 1, layers do
			local h = snap(height / layers * rng:range(0.85, 1.15))
			local shrink = 1 - 0.1 * (layer - 1)
			local w, d = snap(width * shrink * rng:range(0.92, 1)), snap(depth * shrink * rng:range(0.92, 1))
			local ox, oz = rng:range(-radius * 0.06, radius * 0.06), rng:range(-radius * 0.06, radius * 0.06)
			F.part({
				Name = "Layer",
				Size = { w, h, d },
				Position = { ox, y + h / 2, oz },
				Color = colors[layer],
				Material = "Sandstone",
				CastShadow = true,
			})
			y += h
			lastW, lastD, lastX, lastZ = w, d, ox, oz
		end
		F.part({
			Name = "Caprock",
			Size = { snap(lastW * 1.04), 1.6, snap(lastD * 1.04) },
			Position = { lastX, y + 0.5, lastZ },
			Color = "MesaDark",
			Material = "Slate",
		})
		for side = 0, 3 do
			if rng:chance(0.6) then
				local half = if side % 2 == 0 then depth / 2 else width / 2
				local along = if side % 2 == 0 then width else depth
				local sh = snap(height * rng:range(0.12, 0.18))
				local sl = snap(sh * 1.6)
				local cx, cz = Props.rotate(rng:range(-along * 0.2, along * 0.2), -(half + sl / 2 - 0.5), side * 90)
				F.part({
					Name = "Scree",
					Shape = "Wedge",
					Size = { snap(along * rng:range(0.3, 0.6)), sh, sl },
					Position = { cx, sh / 2 - 0.5, cz },
					Yaw = side * 90,
					Color = "SandDark",
					Material = "Sandstone",
				})
			end
		end
	end)
	return model
end

--[[
	An edge cliff segment: `at` is the middle of its outer edge on the map border; it reaches `depth` studs inward
	(the frame's front, -Z) in three tiers that step back as they rise. Neighbouring segments overlap, so their tier
	tops and faces must never come out (almost) level — that flickers. Heights and step-backs are whole studs plus
	`offset` (below 1): give neighbours offsets at least 0.25 apart (Desert.luau alternates 0 / 0.5 along a side and
	adds 0.25 on every other side, for the corners).
]]
function Props.cliff(at: Vec, length: number, depth: number, height: number, yaw: number, rng: Rng.Rng, offset: number)
	local F = Props.frame(at, yaw)
	local tiers = { { 0.5, 0, "Mesa" }, { 0.3, 0.2, "MesaLight" }, { 0.2, 0.4, "Mesa" } }
	local half = offset
	depth = math.floor(depth)
	return B.model("Cliff", function()
		local y = -1
		local inner = 0
		for index, tier in tiers do
			local h = math.floor(height * tier[1] * rng:range(0.9, 1.1)) + (if index == 1 then half else 0)
			inner = math.floor(depth * tier[2] + rng:range(0, 6)) + half
			F.box({
				Name = "Tier",
				From = { -length / 2, y, -depth + inner },
				To = { length / 2, y + h, 10 },
				Color = tier[3],
				Material = "Sandstone",
				CastShadow = true,
			})
			y += h
		end
		F.box({
			Name = "Caprock",
			From = { -length / 2 - 1, y, -depth + inner - 1 },
			To = { length / 2 + 1, y + 1.6, 10 },
			Color = "MesaDark",
			Material = "Slate",
		})
		if rng:chance(0.5) then
			local sh = snap(height * rng:range(0.08, 0.14))
			F.part({
				Name = "Scree",
				Shape = "Wedge",
				Size = { snap(length * rng:range(0.4, 0.7)), sh, snap(sh * 1.6) },
				Position = { rng:range(-length * 0.2, length * 0.2), sh / 2 - 0.5, -depth - sh * 0.8 + 0.5 },
				Color = "SandDark",
				Material = "Sandstone",
			})
		end
	end)
end

-- A wooden telephone pole: a square post, a crossarm with three insulator blocks, and on some a transformer box.
-- Returns the two wire points (crossarm ends).
function Props.pole(at: Vec, yaw: number, transformer: boolean): (Vec, Vec)
	local F = Props.frame(at, yaw)
	B.model("Pole", function()
		F.box({ Name = "Post", From = { -0.5, -1, -0.5 }, To = { 0.5, 24, 0.5 }, Color = "DeadWood", Material = "Wood" })
		F.box({
			Name = "Crossarm",
			From = { -4.5, 21.6, -0.4 },
			To = { 4.5, 22.4, 0.4 },
			Color = "Wood",
			Material = "Wood",
		})
		for _, x in { -3.6, 0.9, 3.6 } do
			F.box({ Name = "Insulator", From = { x - 0.3, 22.4, -0.3 }, To = { x + 0.3, 23.4, 0.3 }, Color = "Glass" })
		end
		if transformer then
			F.box({ Name = "Transformer", From = { -1, 16, -2.6 }, To = { 1, 19, -0.5 }, Color = "Metal" })
		end
	end)
	return F.at(-3.6, 23, 0), F.at(3.6, 23, 0)
end

-- A wooden jump ramp (drive up from its front, -Z) with tire stacks on both sides of the lip.
function Props.ramp(at: Vec, yaw: number, width: number, length: number, height: number)
	local F = Props.frame(at, yaw)
	B.model("Ramp", function()
		F.part({
			Name = "Ramp",
			Shape = "Wedge",
			Size = { width, height, length },
			Position = { 0, height / 2 - 0.2, 0 },
			Color = "Wood",
			Material = "WoodPlanks",
			CastShadow = true,
		})
		for _, side in { -1, 1 } do
			for level = 0, 2 do
				F.column({
					Name = "Tire",
					Base = { side * (width / 2 + 1.8), level * 1.1, length / 2 - 1.5 },
					Height = 1.1,
					Diameter = 3,
					Color = "Black",
					Material = "Rubber",
				})
			end
		end
	end)
end

-- A wooden signpost; its board faces the frame's front (-Z) and shows the text of `key`.
function Props.signpost(at: Vec, yaw: number, key: string)
	local F = Props.frame(at, yaw)
	B.model("Signpost", function()
		for _, x in { -5, 5 } do
			F.box({
				Name = "Post",
				From = { x - 0.4, -0.5, 0 },
				To = { x + 0.4, 10, 0.8 },
				Color = "DeadWood",
				Material = "Wood",
			})
		end
		F.sign({
			Name = "Board",
			Size = { 13, 3.6, 0.5 },
			Position = { 0, 8, 0 },
			Color = "Wood",
			Material = "WoodPlanks",
			Key = key,
			TextColor = "OffWhite",
		})
	end)
end

-- An old car wreck (decoration), nose toward the frame's front (-Z).
function Props.oldCar(at: Vec, yaw: number, color: string)
	local F = Props.frame(at, yaw)
	B.model("OldCar", function()
		F.box({ Name = "Body", From = { -3.6, 1.2, -7.5 }, To = { 3.6, 3.4, 7.5 }, Color = color })
		F.part({
			Name = "Hood",
			Shape = "Wedge",
			Size = { 6.8, 0.8, 4.8 },
			Position = { 0, 3.8, -4.8 },
			Color = color,
		})
		F.box({ Name = "Cabin", From = { -3.2, 3.4, -2.4 }, To = { 3.2, 6.2, 3.2 }, Color = color })
		F.box({ Name = "Windshield", From = { -2.9, 3.9, -2.55 }, To = { 2.9, 5.8, -2.35 }, Color = "Black" })
		F.box({ Name = "RearWindow", From = { -2.9, 3.9, 3.15 }, To = { 2.9, 5.8, 3.35 }, Color = "Black" })
		for _, x in { -3.25, 3.25 } do
			F.box({ Name = "SideWindow", From = { x - 0.1, 4, -1.8 }, To = { x + 0.1, 5.7, 2.6 }, Color = "Black" })
		end
		F.box({
			Name = "Rust",
			From = { -3.7, 1.6, 1 },
			To = { 3.7, 2.8, 4.5 },
			Color = "Rust",
			Material = "CorrodedMetal",
		})
		for _, z in { -7.7, 7.7 } do
			F.box({ Name = "Bumper", From = { -3.8, 1.3, z - 0.3 }, To = { 3.8, 2.1, z + 0.3 }, Color = "Chrome" })
		end
		for _, x in { -2.4, 2.4 } do
			F.box({
				Name = "Headlight",
				From = { x - 0.6, 2.4, -7.75 },
				To = { x + 0.6, 3.1, -7.5 },
				Color = "HeadLight",
			})
		end
		for _, x in { -3.4, 3.4 } do
			for _, z in { -4.8, 4.8 } do
				F.part({
					Name = "Wheel",
					Shape = "Cylinder",
					Size = { 1.2, 3.2, 3.2 },
					Position = { x, 1.4, z },
					Color = "Black",
					Material = "Rubber",
				})
			end
		end
	end)
end

-- A decorative oil drum (not a pickup).
function Props.drum(at: Vec, color: string)
	local F = Props.frame(at, 0)
	B.model("Drum", function()
		F.column({ Name = "Drum", Base = { 0, 0, 0 }, Height = 3.6, Diameter = 2.4, Color = color, Material = "Metal" })
		for _, y in { 1.1, 2.4 } do
			F.column({ Name = "Rib", Base = { 0, y, 0 }, Height = 0.2, Diameter = 2.5, Color = "MetalDark" })
		end
		F.column({ Name = "Lid", Base = { 0, 3.6, 0 }, Height = 0.1, Diameter = 2.2, Color = "MetalDark" })
	end)
end

-- A stack of old tires.
function Props.tires(at: Vec, count: number)
	local F = Props.frame(at, 0)
	B.model("Tires", function()
		for level = 0, count - 1 do
			F.column({
				Name = "Tire",
				Base = { (level % 2) * 0.3, level * 1.1, 0 },
				Height = 1.1,
				Diameter = 3.2,
				Color = "Black",
				Material = "Rubber",
			})
		end
	end)
end

-- A street light: a square pole, an arm reaching over the frame's front (-Z) and a lamp head with a glowing lens.
function Props.streetLight(at: Vec, yaw: number)
	local F = Props.frame(at, yaw)
	B.model("StreetLight", function()
		F.box({
			Name = "Base",
			From = { -0.7, -0.2, -0.7 },
			To = { 0.7, 1, 0.7 },
			Color = "Concrete",
			Material = "Concrete",
		})
		F.box({ Name = "Pole", From = { -0.35, 1, -0.35 }, To = { 0.35, 18, 0.35 }, Color = "MetalDark" })
		F.box({ Name = "Arm", From = { -0.3, 17.3, -5.5 }, To = { 0.3, 17.9, 0.35 }, Color = "MetalDark" })
		F.box({ Name = "Head", From = { -0.9, 17, -6.9 }, To = { 0.9, 17.8, -4.5 }, Color = "MetalDark" })
		F.box({
			Name = "Lamp",
			From = { -0.7, 16.8, -6.7 },
			To = { 0.7, 17, -4.7 },
			Color = "NeonWhite",
			Material = "Neon",
		})
	end)
end

-- A fence along a straight line: posts every `spacing` studs and two rails.
function Props.fence(from: Vec, to: Vec, height: number, spacing: number, color: string)
	local dx, dz = to[1] - from[1], to[3] - from[3]
	local length = math.sqrt(dx * dx + dz * dz)
	local count = math.max(1, math.floor(length / spacing + 0.5))
	B.model("Fence", function()
		for index = 0, count do
			local t = index / count
			B.part({
				Name = "Post",
				Size = { 0.4, height, 0.4 },
				Position = { snap(from[1] + dx * t), from[2] + height / 2, snap(from[3] + dz * t) },
				Color = color,
			})
		end
		for _, y in { height * 0.45, height - 0.2 } do
			Props.wire({ from[1], from[2] + y, from[3] }, { to[1], from[2] + y, to[3] }, 0.25, color)
		end
	end)
end

return Props
