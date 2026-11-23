--!strict
--[[
	OilController — makes the floating oil barrels (Services/OilService, tagged "OilBarrel") bob up and down and
	turn slowly on this client, so they read as pickups from far away. Purely visual: the server keeps each barrel
	anchored at its BaseCFrame attribute and decides pickups by distance (Config.Oil).
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local OilController = {}

local barrels: { [Model]: number } = {} -- barrel -> its own phase, so they don't all bob together

local function add(instance: Instance)
	if instance:IsA("Model") then
		barrels[instance] = math.random() * math.pi * 2
	end
end

function OilController.Start(_self: any)
	for _, barrel in CollectionService:GetTagged("OilBarrel") do
		add(barrel)
	end
	CollectionService:GetInstanceAddedSignal("OilBarrel"):Connect(add)
	CollectionService:GetInstanceRemovedSignal("OilBarrel"):Connect(function(instance: Instance)
		if instance:IsA("Model") then
			barrels[instance] = nil
		end
	end)
	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for barrel, phase in barrels do
			local base = barrel:GetAttribute("BaseCFrame")
			if barrel.Parent and typeof(base) == "CFrame" then
				local bob = math.sin(t * 2 + phase) * Config.Oil.BobHeight
				barrel:PivotTo(base * CFrame.new(0, bob, 0) * CFrame.Angles(0, t * Config.Oil.SpinSpeed + phase, 0))
			end
		end
	end)
end

return OilController
