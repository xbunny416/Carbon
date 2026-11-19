--!strict
--[[
	Builder — tiny DSL for blockout maps, run by Lune (maps/build.luau) to produce .rbxmx models that Rojo puts into
	the place. Positions are in studs relative to the current origin (see `within`); rotations are degrees.

	`spread(factor, fill)` multiplies the horizontal (X / Z) positions of everything built inside it, keeping sizes:
	decor laid out for a smaller platform spreads over a bigger one without stretching the objects.

	Gameplay markers (spawn points, prop/structure spots) are tagged parts. They are semi-transparent so they can be
	seen and moved in Studio's Edit mode; MapService hides them at runtime.
]]
local roblox = require("@lune/roblox")
local csv = require("../../tools/csv")
local Palette = require("./Palette")

local Instance = roblox.Instance
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Color3 = roblox.Color3
local Enum = roblox.Enum

export type Vec = { number }

export type PartSpec = {
	Name: string?,
	Size: Vec,
	Position: Vec,
	Rotation: Vec?,
	Yaw: number?, -- degrees around Y applied before Rotation (furniture turned as a whole: maps/lib/Furniture)
	Axes: { Right: Vec, Up: Vec }?, -- the part's X and Y directions (instead of Yaw / Rotation): exact slants, e.g. wedges
	Color: string,
	Material: string?,
	Shape: string?, -- "Block" (default), "Cylinder" (axis along X), "Ball", "Wedge"
	Transparency: number?,
	CanCollide: boolean?,
	CastShadow: boolean?,
	Tags: { string }?,
	Attributes: { [string]: any }?,
}

local Builder = {}

local strings = csv.readStrings()
local parentStack: { any } = {}
local originStack: { Vec } = { { 0, 0, 0 } }
local spreadStack: { number } = { 1 }

local function current(): any
	return parentStack[#parentStack]
end

local function origin(): Vec
	return originStack[#originStack]
end

local function color(value: string): any
	local hex = (Palette :: any)[value] or value
	return Color3.fromHex(hex)
end

-- A colour (a Palette name or a hex) with each channel scaled by `factor` (below 1: darker), as a hex string.
function Builder.shade(value: string, factor: number): string
	local c = color(value)
	local function channel(x: number): number
		return math.clamp(math.floor(x * factor * 255 + 0.5), 0, 255)
	end
	return string.format("#%02X%02X%02X", channel(c.R), channel(c.G), channel(c.B))
end

local function spread(): number
	return spreadStack[#spreadStack]
end

--[[
	Rotations are built here instead of with CFrame.Angles: its sine / cosine come from each OS's math library, which
	can differ in the last bit, so a map with many odd angles would serialize differently on Windows and on CI. These
	are rounded to 1e-6 first, so every OS writes the same file.
]]
local function sinCos(degrees: number): (number, number)
	local r = math.rad(degrees)
	return math.floor(math.sin(r) * 1e6 + 0.5) / 1e6, math.floor(math.cos(r) * 1e6 + 0.5) / 1e6
end

-- 3×3 matrices, row-major.
local function multiply(a: { number }, b: { number }): { number }
	local m = table.create(9, 0)
	for row = 0, 2 do
		for col = 1, 3 do
			m[row * 3 + col] = a[row * 3 + 1] * b[col] + a[row * 3 + 2] * b[col + 3] + a[row * 3 + 3] * b[col + 6]
		end
	end
	return m
end

local function aroundX(degrees: number): { number }
	local s, c = sinCos(degrees)
	return { 1, 0, 0, 0, c, -s, 0, s, c }
end

local function aroundY(degrees: number): { number }
	local s, c = sinCos(degrees)
	return { c, 0, s, 0, 1, 0, -s, 0, c }
end

local function aroundZ(degrees: number): { number }
	local s, c = sinCos(degrees)
	return { c, -s, 0, s, c, 0, 0, 0, 1 }
end

local function cframe(position: Vec, rotation: Vec?, yaw: number?, axes: { Right: Vec, Up: Vec }?): any
	local o, s = origin(), spread()
	local at = Vector3.new(position[1] * s + o[1], position[2] + o[2], position[3] * s + o[3])
	if axes then
		local right, up = axes.Right, axes.Up
		return CFrame.fromMatrix(at, Vector3.new(right[1], right[2], right[3]), Vector3.new(up[1], up[2], up[3]))
	end
	if not yaw and not rotation then
		return CFrame.new(at.X, at.Y, at.Z)
	end
	-- Same order as CFrame.Angles(0, yaw, 0) * CFrame.Angles(x, y, z) (each Angles is X, then Y, then Z).
	local m = aroundY(yaw or 0)
	if rotation then
		m = multiply(m, multiply(multiply(aroundX(rotation[1]), aroundY(rotation[2])), aroundZ(rotation[3])))
	end
	return CFrame.new(at.X, at.Y, at.Z, m[1], m[2], m[3], m[4], m[5], m[6], m[7], m[8], m[9])
end

local function applyCommon(instance: any, spec: PartSpec)
	instance.Name = spec.Name or "Part"
	instance.Anchored = true
	instance.Size = Vector3.new(spec.Size[1], spec.Size[2], spec.Size[3])
	instance.CFrame = cframe(spec.Position, spec.Rotation, spec.Yaw, spec.Axes)
	instance.Color = color(spec.Color)
	instance.Material = (Enum.Material :: any)[spec.Material or "SmoothPlastic"]
	instance.TopSurface = Enum.SurfaceType.Smooth
	instance.BottomSurface = Enum.SurfaceType.Smooth
	if spec.Transparency then
		instance.Transparency = spec.Transparency
	end
	if spec.CanCollide ~= nil then
		instance.CanCollide = spec.CanCollide
	end
	-- Small parts never cast shadows (performance on low-end phones).
	local volume = spec.Size[1] * spec.Size[2] * spec.Size[3]
	if spec.CastShadow ~= nil then
		instance.CastShadow = spec.CastShadow
	elseif volume < 64 then
		instance.CastShadow = false
	end
	for _, tag in spec.Tags or {} do
		instance:AddTag(tag)
	end
	for key, value in spec.Attributes or {} do
		instance:SetAttribute(key, value)
	end
	instance.Parent = current()
end

-- Facing names map to the yaw that points a part's Front (-Z) face that way.
local FACING: { [string]: number } = { South = 0, North = 180, East = -90, West = 90 }

function Builder.yaw(facing: string): Vec
	return { 0, assert(FACING[facing], `unknown facing {facing}`), 0 }
end

-- Creates a Model under the current parent and runs `fill` with it as the parent.
function Builder.model(name: string, fill: (() -> ())?, attributes: { [string]: any }?): any
	local model = Instance.new("Model")
	model.Name = name
	for key, value in attributes or {} do
		model:SetAttribute(key, value)
	end
	model.Parent = current()
	if fill then
		table.insert(parentStack, model)
		fill()
		table.remove(parentStack)
	end
	return model
end

function Builder.folder(name: string, fill: () -> ()): any
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = current()
	table.insert(parentStack, folder)
	fill()
	table.remove(parentStack)
	return folder
end

-- Runs `fill` with `parent` (an existing instance) as the current parent: for a pass over a model already built.
function Builder.into(parent: any, fill: () -> ())
	table.insert(parentStack, parent)
	fill()
	table.remove(parentStack)
end

-- Runs `fill` with every horizontal position (X / Z, from the current origin) multiplied by `factor`; sizes stay.
function Builder.spread(factor: number, fill: () -> ())
	table.insert(spreadStack, spread() * factor)
	fill()
	table.remove(spreadStack)
end

-- Runs `fill` with positions measured from `offset` (added to the current origin).
function Builder.within(offset: Vec, fill: () -> ())
	local o, s = origin(), spread()
	table.insert(originStack, { o[1] + offset[1] * s, o[2] + offset[2], o[3] + offset[3] * s })
	fill()
	table.remove(originStack)
end

function Builder.part(spec: PartSpec): any
	local shape = spec.Shape or "Block"
	local instance
	if shape == "Wedge" then
		instance = Instance.new("WedgePart")
	else
		instance = Instance.new("Part")
		instance.Shape = (Enum.PartType :: any)[shape]
	end
	applyCommon(instance, spec)
	return instance
end

-- A Seat players can sit on, built like a part (Shape works too). Tagged LobbySeat: a client prompt asks the server
-- to sit you down (SeatService). CanTouch is off, so walking into it never sits you down by accident.
function Builder.seat(spec: PartSpec): any
	local seat = Instance.new("Seat")
	seat.Shape = (Enum.PartType :: any)[spec.Shape or "Block"]
	applyCommon(seat, spec)
	seat.CanTouch = false
	seat:AddTag("LobbySeat")
	return seat
end

-- A climbable truss (a TrussPart: walk into it and you climb it like a ladder) built like a part. Roblox snaps its size
-- to 2-stud steps, so give it { 2, height, 2 } with an even height.
function Builder.truss(spec: PartSpec): any
	local truss = Instance.new("TrussPart")
	applyCommon(truss, spec)
	return truss
end

-- A SpawnLocation (neutral, no spawn forcefield) built like a part.
function Builder.spawnLocation(spec: PartSpec): any
	local spawn = Instance.new("SpawnLocation")
	applyCommon(spawn, spec)
	spawn.Neutral = true
	spawn.Duration = 0
	return spawn
end

-- A box whose top surface sits at Position.Y (handy for floors and platforms).
function Builder.slab(spec: PartSpec): any
	local position = { spec.Position[1], spec.Position[2] - spec.Size[2] / 2, spec.Position[3] }
	local copy = table.clone(spec) :: any
	copy.Position = position
	return Builder.part(copy)
end

-- An invisible-at-runtime gameplay marker standing on the surface at `position`.
function Builder.marker(tag: string, name: string, position: Vec, attributes: { [string]: any }?, facing: Vec?): any
	return Builder.part({
		Name = name,
		Size = { 2, 0.4, 2 },
		Position = { position[1], position[2] + 0.2, position[3] },
		Rotation = facing,
		Color = "NeonTeal",
		Material = "Neon",
		Transparency = 0.5,
		CanCollide = false,
		CastShadow = false,
		Tags = { tag, "Marker" },
		Attributes = attributes,
	})
end

-- Looks up player-facing text in GameStrings.csv (no text is hard-coded in layouts).
function Builder.text(key: string): string
	return assert(strings[key], `GameStrings.csv has no key "{key}"`)
end

-- An image filling a SurfaceGui: `crop` is { x, y, width, height } in the image's pixels (maps/lib/Art).
local function image(gui: any, id: number, crop: { number })
	local picture = Instance.new("ImageLabel")
	picture.Name = "Picture"
	picture.BackgroundTransparency = 1
	picture.Size = roblox.UDim2.fromScale(1, 1)
	picture.Image = `rbxassetid://{id}`
	picture.ImageRectOffset = roblox.Vector2.new(crop[1], crop[2])
	picture.ImageRectSize = roblox.Vector2.new(crop[3], crop[4])
	picture.Parent = gui
end

-- A picture on a part's face `face` (a NormalId name, default Front): `crop` of image `id` (maps/lib/Art).
function Builder.picture(board: any, id: number, crop: { number }, face: string?): any
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Picture"
	gui.Face = (Enum.NormalId :: any)[face or "Front"]
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.Parent = board
	image(gui, id, crop)
	return gui
end

--[[
	A sign: a board part with a SurfaceGui label on its Front face. Text comes from a localization key. With an
	`Image` (an id and its crop, maps/lib/Art), the picture fills the board and the text is a headline in a band
	`Headline` high across its top.
]]
function Builder.sign(spec: PartSpec & {
	Key: string,
	TextColor: string,
	Glow: boolean?,
	Image: { Id: number, Crop: { number }, Headline: number }?,
}): any
	local board = Builder.part(spec)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Label"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = if spec.Glow then 0 else 1
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.BackgroundTransparency = 1
	label.Size = roblox.UDim2.fromScale(1, 1)
	label.FontFace = roblox.Font.fromName("Bangers")
	label.TextScaled = true
	label.TextColor3 = color(spec.TextColor)
	label.Text = Builder.text(spec.Key)
	label:SetAttribute("LocKey", spec.Key)
	if spec.Image then
		gui.PixelsPerStud = 20
		image(gui, spec.Image.Id, spec.Image.Crop)
		label.ZIndex = 2
		label.Position = roblox.UDim2.fromScale(0.05, 0.02)
		label.Size = roblox.UDim2.fromScale(0.9, spec.Image.Headline - 0.03)
		label.TextStrokeColor3 = color("Black")
		label.TextStrokeTransparency = 0
	end
	label.Parent = gui
	return board
end

-- A point light. `shadows`: it casts soft shadows (Future lighting) — only the few main lamps, it costs frame time.
function Builder.light(parentPart: any, lightColor: string, range: number, brightness: number, shadows: boolean?): any
	local light = Instance.new("PointLight")
	light.Color = color(lightColor)
	light.Range = range
	light.Brightness = brightness
	light.Shadows = shadows == true
	if shadows then
		light:AddTag("ShadowLight") -- Low Graphics turns these shadows off (VfxController)
	end
	light.Parent = parentPart
	return light
end

-- Starts a new top-level model (returned) for a map file.
function Builder.root(name: string, fill: () -> (), attributes: { [string]: any }?): any
	parentStack = {}
	originStack = { { 0, 0, 0 } }
	spreadStack = { 1 }
	local root = Instance.new("Model")
	root.Name = name
	for key, value in attributes or {} do
		root:SetAttribute(key, value)
	end
	table.insert(parentStack, root)
	fill()
	table.remove(parentStack)
	return root
end

Builder.roblox = roblox
Builder.Enum = Enum

return Builder
