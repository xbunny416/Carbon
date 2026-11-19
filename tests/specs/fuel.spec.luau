--!strict
-- Fuel math (Shared/FuelRules, bible §5.3).
local Roblox = require("../roblox")
local expect = require("../expect")

local Shared = Roblox.game.ReplicatedStorage.Shared
local Config = Roblox.require(Shared.Config)
local FuelRules = Roblox.require(Shared.FuelRules)

local fuel = Config.Fuel
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
	["pumps refill up to a full tank"] = function()
		near(FuelRules.refill(10, tank, fuel.RefillRate, 1), 10 + fuel.RefillRate, "one second")
		expect.equal(FuelRules.refill(tank - 1, tank, fuel.RefillRate, 1), tank, "capped at full")
	end,
	["an empty tank burns a barrel, or stalls without cargo"] = function()
		local f, cargo, stalls = FuelRules.whenEmpty(0, 3, fuel.BarrelFuel, tank)
		expect.equal(f, fuel.BarrelFuel)
		expect.equal(cargo, 2)
		expect.equal(stalls, false)
		f, cargo, stalls = FuelRules.whenEmpty(0, 0, fuel.BarrelFuel, tank)
		expect.equal(f, 0)
		expect.equal(cargo, 0)
		expect.equal(stalls, true)
		f, cargo, stalls = FuelRules.whenEmpty(12, 2, fuel.BarrelFuel, tank)
		expect.equal(f, 12)
		expect.equal(stalls, false)
	end,
	["the low-fuel warning fires once, when crossing the line"] = function()
		local line = tank * fuel.LowFraction
		expect.equal(FuelRules.crossedLow(line + 1, line - 1, tank, fuel.LowFraction), true)
		expect.equal(FuelRules.crossedLow(line - 1, line - 2, tank, fuel.LowFraction), false)
		expect.equal(FuelRules.crossedLow(line - 1, line + 5, tank, fuel.LowFraction), false)
	end,
	["fuel numbers are sane"] = function()
		for key, value in fuel :: any do
			expect.truthy(type(value) == "number" and value > 0, key)
		end
		expect.truthy(fuel.LowFraction < 1, "LowFraction")
		expect.truthy(fuel.BarrelFuel <= tank, "a barrel never overfills the starter tank")
	end,
}
