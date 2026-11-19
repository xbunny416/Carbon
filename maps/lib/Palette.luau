--!strict
--[[
	Named map colors (hex). Layouts use these names (`Color = "Concrete"`), never raw hex, so a restyle is one edit
	here. CarOff's look (owner, 2026-11-19): the blocky-parts style (.claude/skills/roblox-blocky-parts-style) —
	muted, slightly desaturated, earthy colors; no pure white or black, no saturated primaries; Neon only on real
	lights. Names kept from the first palette so every layout and car follows the change.
]]
return {
	-- Base materials
	Concrete = "#A0A0A5", -- trim / foundation grey
	ConcreteDark = "#7A7A7E",
	ConcreteLight = "#B4B2AE",
	Asphalt = "#55565B",
	Metal = "#8C9094",
	MetalDark = "#5A5D63",
	Wood = "#7E6047",
	WoodDark = "#54412F",
	Brick = "#8A5A48",
	Glass = "#96AFB9", -- use with Transparency 0.4–0.6
	WindowDark = "#5D6E75", -- windows set on solid walls (opaque)
	Leaf = "#468C5A",
	Lawn = "#5FA064",
	OffWhite = "#CDC8BE",
	Black = "#23262D", -- dark details: tires, grilles
	RoofBrown = "#785F50",
	RoofDark = "#554641",
	-- Accents (muted)
	Teal = "#5F8A86",
	Orange = "#C85A28",
	Red = "#A8503F",
	Yellow = "#DCC878",
	Pink = "#B98884",
	Purple = "#7D6A86",
	NeonTeal = "#3FF2E0", -- gameplay markers only (hidden in a running game)
	NeonPink = "#B98884",
	WarmLight = "#F2D9A6", -- lamp glow (Neon)
	-- Desert ground and rock
	Sand = "#C9AE85",
	SandLight = "#D2BC96",
	SandDark = "#B89B72",
	Badland = "#A8805E",
	DirtRoad = "#8C7355",
	DirtRut = "#776147",
	Mesa = "#A0634A",
	MesaLight = "#B47A5C",
	MesaDark = "#7E4C3A",
	Sandstone = "#BE9672",
	Boulder = "#95765E",
	-- Plants
	Sage = "#8C9A74",
	SageDark = "#6F7D5C",
	Cactus = "#5A7F55",
	CactusDark = "#46664A",
	DeadWood = "#6E5541",
	Flower = "#C8858F",
	-- Town
	Adobe = "#C29A78",
	AdobeLight = "#CDB094",
	Stucco = "#D7CDB4", -- warm plaster
	MotelTeal = "#6E9690",
	MotelPink = "#B98884",
	GasRed = "#A8503F",
	White = "#CDC8BE",
	Chrome = "#A9ADB1",
	Rust = "#8A5A3E",
	TankWhite = "#C3C0B8",
	PoolWater = "#7FA7B3",
	RoadLine = "#DCC878",
	NeonOrange = "#C85A28",
	NeonYellow = "#DCC878",
	NeonWhite = "#EDE3CC", -- lamp glow (Neon)
	-- Cars
	PickupPaint = "#7E958F",
	PickupPaintDark = "#64776F",
	BedLiner = "#3A3B3E",
	TailLight = "#C85A28",
	HeadLight = "#DCC878",
}
