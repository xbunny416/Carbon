--!strict
--[[
	MapService — readies the generated maps (Workspace.Desert and Workspace.Town, from maps/layouts) at runtime:
	gameplay markers (parts tagged "Marker": CarSpawn, PumpBay, OilSpot) are semi-transparent pads so they can be
	seen and moved in Studio's Edit mode; in a running game they are hidden. The systems that use them (cars, pumps,
	oil) find them by their own tag.
	A Baseplate and SpawnLocation left over from Studio's Baseplate template are buried under the desert ground (it is
	1 stud up, Config.World.Map.Origin); any SpawnLocation outside Workspace.Town is turned off so players always
	spawn at the motel, and Studio's Output says the leftovers can be deleted.
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
	local town = workspace:FindFirstChild("Town")
	local stray = 0
	for _, instance in workspace:GetDescendants() do
		if instance:IsA("SpawnLocation") and not (town and instance:IsDescendantOf(town)) then
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
