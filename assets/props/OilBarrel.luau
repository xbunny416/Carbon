--!strict
--[[
	Oil barrel — the floating fuel pickup (bible §5.4, Services/OilService), in the blocky-parts look: a dark steel
	drum with two orange bands, a lid with a bung and a soft warm glow so it's easy to spot from a distance (a real
	light, so a PointLight rather than Neon). Anchored and non-colliding: cars drive through it to pick it up.
	PrimaryPart = Drum, centered on the model's pivot.
]]
local B = require("../../maps/lib/Builder")
local Props = require("../../maps/lib/Props")

local OilBarrel = {}

function OilBarrel.build(): any
	local drum: any
	local root = B.root("OilBarrel", function()
		local F = Props.frame({ 0, 0, 0 }, 0)
		drum = F.column({
			Name = "Drum",
			Base = { 0, -1.8, 0 },
			Height = 3.6,
			Diameter = 2.6,
			Color = "MetalDark",
			Material = "Metal",
		})
		for _, y in { -0.9, 0.9 } do
			F.column({ Name = "Band", Base = { 0, y - 0.25, 0 }, Height = 0.5, Diameter = 2.75, Color = "Orange" })
		end
		F.column({ Name = "Lid", Base = { 0, 1.8, 0 }, Height = 0.2, Diameter = 2.3, Color = "Black" })
		F.box({ Name = "Bung", From = { 0.4, 2, -0.3 }, To = { 1, 2.3, 0.3 }, Color = "Orange" })
	end)
	for _, part in root:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.CastShadow = true
		end
	end
	B.light(drum, "WarmLight", 14, 1.2)
	root.PrimaryPart = drum
	return root
end

return OilBarrel
