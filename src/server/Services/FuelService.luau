--!strict
--[[
	FuelService — every car's tank (bible §5.3; numbers in Config.Fuel). Every Config.Fuel.Tick seconds, for each
	car (Services/CarService):
	  - while its owner drives it, burns fuel by the distance the chassis really moved (capped at MaxCountedSpeed,
	    so a flip or a teleport doesn't drain the tank);
	  - when the tank is empty, burns a cargo barrel (the car's Cargo attribute, from 1.4) or stalls the car
	    (CarService.setStalled: the server takes its physics; the owner can tow it home);
	  - while it stands (almost) still in a gas station pump bay, refills it for free.
	The tank is the car's Fuel attribute (FuelMax = full), so every client can read it.
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local FuelRules = require(Shared:WaitForChild("FuelRules"))
local Net = require(Shared:WaitForChild("Net"))

local CarService = require(script.Parent:WaitForChild("CarService"))

local FuelService = {}

local last: { [Model]: Vector3 } = {}

local function number(instance: Instance, name: string, default: number): number
	local value = instance:GetAttribute(name)
	return if type(value) == "number" then value else default
end

local function atPump(position: Vector3): boolean
	for _, bay in CollectionService:GetTagged("PumpBay") do
		if bay:IsA("BasePart") then
			local offset = bay.Position - position
			if Vector3.new(offset.X, 0, offset.Z).Magnitude <= Config.Fuel.PumpRadius then
				return true
			end
		end
	end
	return false
end

local function update(player: Player, car: Model, dt: number)
	local chassis = car.PrimaryPart
	if not chassis then
		return
	end
	local fuel = number(car, "Fuel", 0)
	local max = number(car, "FuelMax", fuel)
	local position = chassis.Position
	local previous = last[car] or position
	last[car] = position
	local stalled = car:GetAttribute("Stalled") == true
	local before = fuel

	if not stalled and CarService.isDriving(player) then
		local moved = Vector3.new(position.X - previous.X, 0, position.Z - previous.Z).Magnitude
		local counted = FuelRules.countedDistance(moved, dt, Config.Fuel.MaxCountedSpeed)
		fuel = FuelRules.burn(fuel, counted, Config.Fuel.BurnPerStud)
	end
	if chassis.AssemblyLinearVelocity.Magnitude <= Config.Fuel.PumpMaxSpeed and atPump(position) then
		fuel = FuelRules.refill(fuel, max, Config.Fuel.RefillRate, dt)
	end

	if fuel <= 0 and not stalled then
		local cargo = number(car, "Cargo", 0)
		local newFuel, newCargo, stalls = FuelRules.whenEmpty(fuel, cargo, Config.Fuel.BarrelFuel, max)
		fuel = newFuel
		if newCargo ~= cargo then
			car:SetAttribute("Cargo", newCargo)
			Net.fireClient("Notify", player, "Fuel.BurnedBarrel")
		end
		if stalls then
			CarService.setStalled(player, car, true)
			Net.fireClient("Notify", player, "Fuel.Stalled")
		end
	elseif fuel > 0 and stalled then
		CarService.setStalled(player, car, false)
	end

	if FuelRules.crossedLow(before, fuel, max, Config.Fuel.LowFraction) then
		Net.fireClient("Notify", player, "Fuel.Low")
	end
	if fuel ~= before then
		car:SetAttribute("Fuel", fuel)
	end
end

function FuelService.Start(_self: any)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt
		if elapsed < Config.Fuel.Tick then
			return
		end
		local step = elapsed
		elapsed = 0
		for car in last do
			if car.Parent == nil then
				last[car] = nil
			end
		end
		for player, car in CarService.all() do
			update(player, car, step)
		end
	end)
end

return FuelService
