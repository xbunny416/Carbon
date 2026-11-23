--!strict
--[[
	MapService — readies the generated map (Workspace.Desert, from maps/layouts) at runtime: gameplay markers (parts
	tagged "Marker") are semi-transparent pads in Studio's Edit mode and hidden in a running game.
	A Baseplate and SpawnLocation left over from Studio's Baseplate template are buried under the desert ground (it is
	1 stud up, Config.World.Map.Origin); any SpawnLocation outside the map's spawn pads (Workspace.Desert.Spawn) is
	turned off so players always spawn in the center, and Studio's Output says the leftovers can be deleted.
]]
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local MapService = {}

local function hide(instance: Instance)
	if instance:IsA("BasePart") then
		instance.Transparency = 1
	end
end

local function disableStraySpawns()
	local desert = workspace:FindFirstChild("Desert")
	local pads = desert and desert:FindFirstChild("Spawn")
	local stray = 0
	for _, instance in workspace:GetDescendants() do
		if instance:IsA("SpawnLocation") and not (pads and instance:IsDescendantOf(pads)) then
			instance.Enabled = false
			stray += 1
		end
	end
	if RunService:IsStudio() and (stray > 0 or workspace:FindFirstChild("Baseplate")) then
		warn("[Map] Workspace has a Baseplate / SpawnLocation from Studio's template; they're unused, delete them.")
	end
end

function MapService.Init(_self: any)
	for _, marker in CollectionService:GetTagged("Marker") do
		hide(marker)
	end
	CollectionService:GetInstanceAddedSignal("Marker"):Connect(hide)
	disableStraySpawns()
end

return MapService
