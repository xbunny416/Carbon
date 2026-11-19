--!strict
--[[
	MapService — readies the generated maps (Workspace.Desert and Workspace.Town, from maps/layouts) at runtime:
	gameplay markers (parts tagged "Marker": CarSpawn, PumpBay, OilSpot) are semi-transparent pads so they can be
	seen and moved in Studio's Edit mode; in a running game they are hidden. The systems that use them (cars, pumps,
	oil) find them by their own tag.
]]
local CollectionService = game:GetService("CollectionService")

local MapService = {}

local function hide(instance: Instance)
	if instance:IsA("BasePart") then
		instance.Transparency = 1
	end
end

function MapService.Init(_self: any)
	for _, marker in CollectionService:GetTagged("Marker") do
		hide(marker)
	end
	CollectionService:GetInstanceAddedSignal("Marker"):Connect(hide)
end

return MapService
