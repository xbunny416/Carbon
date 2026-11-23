--!strict
-- Fuel and oil math (Shared/FuelRules, bible §5.3 / §5.4) and the oil barrel asset.
local Roblox = require("../roblox")
local expect = require("../expect")

local Assets = require("../../assets/Assets")

local Shared = Roblox.game.ReplicatedStorage.Shared
local Config = Roblox.require(Shared.Config)
local FuelRules = Roblox.require(Shared.FuelRules)

local fuel = Config.Fuel
local oil = Config.Oil
local tank = Config.Cars.Models[Config.Cars.Starter].Tank

local function near(a: number, b: number, label: string)
	expect.truthy(math.abs(a - b) < 1e-9, `{label}: {a} vs {b}`)
end

return {
	["a full starter tank lasts about 2,500 studs"] = function()
		near(tank / fuel.BurnPerStud, 2500, "range")
		near(FuelRules.burn(tank, 250, fuel.BurnPerStud), tank - 10, "250 studs burn 10")
		expect.equal(FuelRules.burn(5, 1000, fuel.BurnPerStud), 0, "never below empty")
	end,
	["fast jumps only count up to the speed cap"] = function()
		near(FuelRules.countedDistance(6, 0.1, fuel.MaxCountedSpeed), 6, "normal driving counts fully")
		near(FuelRules.countedDistance(500, 0.1, fuel.MaxCountedSpeed), fuel.MaxCountedSpeed * 0.1, "teleport capped")
		expect.equal(FuelRules.countedDistance(-1, 0.1, fuel.MaxCountedSpeed), 0, "no negative distance")
	end,
	["an oil barrel adds fuel up to a full tank, and a full car leaves it"] = function()
		near(FuelRules.addOil(10, tank, oil.FuelPerBarrel), 10 + oil.FuelPerBarrel, "adds a barrel")
		expect.equal(FuelRules.addOil(tank - 5, tank, oil.FuelPerBarrel), tank, "capped at full")
		expect.equal(FuelRules.canTakeOil(tank, tank), false, "full tank skips the barrel")
		expect.equal(FuelRules.canTakeOil(tank - 10, tank), true, "a part-full tank takes it")
	end,
	["the low-fuel warning fires once, when crossing the line"] = function()
		local line = tank * fuel.LowFraction
		expect.equal(FuelRules.crossedLow(line + 1, line - 1, tank, fuel.LowFraction), true)
		expect.equal(FuelRules.crossedLow(line - 1, line - 2, tank, fuel.LowFraction), false)
		expect.equal(FuelRules.crossedLow(line - 1, line + 5, tank, fuel.LowFraction), false)
	end,
	["fuel and oil numbers are sane"] = function()
		for _, group in { fuel, oil } :: { any } do
			for key, value in group do
				expect.truthy(type(value) == "number" and value > 0, key)
			end
		end
		expect.truthy(fuel.LowFraction < 1, "LowFraction")
		expect.truthy(oil.FuelPerBarrel <= tank, "a barrel never more than a whole tank")
		expect.truthy(Config.Cars.RespawnFuel < tank, "spawning again is no full refill")
		local map = Config.World.Map
		expect.truthy(oil.CenterClear >= map.CenterHalfSize, "barrels stay out of the spawn center")
		expect.truthy(oil.EdgeMargin < map.Size / 2 - oil.CenterClear, "there is room for barrels")
	end,
	["the oil barrel asset floats: anchored, no collisions, with a glow"] = function()
		local barrel = Assets.build().Models:FindFirstChild("OilBarrel")
		expect.truthy(barrel ~= nil, "Models.OilBarrel")
		expect.truthy(barrel.PrimaryPart ~= nil, "PrimaryPart")
		local light = false
		for _, part in barrel:GetDescendants() do
			if part:IsA("BasePart") then
				expect.equal(part.Anchored, true, part.Name)
				expect.equal(part.CanCollide, false, part.Name)
			elseif part.ClassName == "PointLight" then
				light = true
			end
		end
		expect.truthy(light, "glow")
	end,
}
