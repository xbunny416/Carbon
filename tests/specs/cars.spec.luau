--!strict
-- Driving math (Shared/CarRules) and the drivable car assets (assets/cars, bible §5.2).
local Roblox = require("../roblox")
local expect = require("../expect")

local Assets = require("../../assets/Assets")

local Shared = Roblox.game.ReplicatedStorage.Shared
local Config = Roblox.require(Shared.Config)
local CarRules = Roblox.require(Shared.CarRules)

local stats = Config.Cars.Models[Config.Cars.Starter]
local built = Assets.build()

local function near(a: number, b: number, label: string)
	expect.truthy(math.abs(a - b) < 1e-6, `{label}: {a} vs {b}`)
end

return {
	["the starter car has stats and every stat is positive"] = function()
		expect.truthy(stats ~= nil, "starter stats")
		for name, model in Config.Cars.Models do
			for key, value in model :: any do
				expect.truthy(type(value) == "number" and value > 0, `{name}.{key}`)
			end
			expect.truthy(model.DampingRatio <= 1 and model.SteerAngleAtTopSpeed <= model.SteerAngle, name)
		end
	end,
	["springs hold the car up by exactly Sag"] = function()
		local mass, gravity = 300, 196.2
		local stiffness, damping = CarRules.spring(mass, gravity, 4, 0.5, 0.5)
		near(stiffness * 0.5, mass * gravity / 4, "spring force at sag = weight per wheel")
		near(damping, 0.5 * 2 * math.sqrt(stiffness * mass / 4), "damping ratio")
	end,
	["wheel torque gives the asked acceleration"] = function()
		near(CarRules.wheelTorque(300, 28, 1.7, 4, 1) * 4 / 1.7, 300 * 28, "force = mass x acceleration")
		near(CarRules.wheelTorque(300, 28, 1.7, 4, 1.5), CarRules.wheelTorque(300, 28, 1.7, 4, 1) * 1.5, "margin")
	end,
	["throttle drives, reverses, brakes against the roll and coasts when let go"] = function()
		local speed, mode = CarRules.drive(1, 0, stats)
		expect.equal(speed, stats.TopSpeed)
		expect.equal(mode, "Drive")
		speed, mode = CarRules.drive(-1, 0, stats)
		expect.equal(speed, -stats.ReverseSpeed)
		expect.equal(mode, "Drive")
		speed, mode = CarRules.drive(-1, 20, stats)
		expect.equal(speed, 0)
		expect.equal(mode, "Brake")
		speed, mode = CarRules.drive(1, -10, stats)
		expect.equal(mode, "Brake")
		speed, mode = CarRules.drive(0, 30, stats)
		expect.equal(speed, 0)
		expect.equal(mode, "Coast")
	end,
	["forward spins the wheels the negative way around +X"] = function()
		near(CarRules.wheelSpin(17, 1.7), -10, "17 studs/s on 1.7-stud wheels")
		near(CarRules.wheelSpin(-17, 1.7), 10, "reverse")
	end,
	["steering: right is a negative hinge angle, and less at speed"] = function()
		near(CarRules.steerAngle(1, 0, stats), -stats.SteerAngle, "full right at a standstill")
		near(CarRules.steerAngle(-1, 0, stats), stats.SteerAngle, "full left")
		near(CarRules.steerAngle(1, stats.TopSpeed * 2, stats), -stats.SteerAngleAtTopSpeed, "at top speed")
		near(CarRules.steerAngle(0, 10, stats), 0, "straight")
	end,
	["a car can be flipped only upside down and stopped"] = function()
		local c = Config.Cars
		expect.equal(CarRules.canFlip(-1, 0, c.FlippedBelowUp, c.FlipMaxSpeed), true)
		expect.equal(CarRules.canFlip(0, 1, c.FlippedBelowUp, c.FlipMaxSpeed), true)
		expect.equal(CarRules.canFlip(1, 0, c.FlippedBelowUp, c.FlipMaxSpeed), false)
		expect.equal(CarRules.canFlip(-1, 20, c.FlippedBelowUp, c.FlipMaxSpeed), false)
	end,
	["every car asset is drivable: chassis, seat, prompt, 4 wheels on springs, front steering, all welded"] = function()
		local folder = built.Models.Cars
		for name in Config.Cars.Models do
			local car = folder:FindFirstChild(name)
			expect.truthy(car ~= nil, `{name} asset`)
			expect.equal(car.PrimaryPart and car.PrimaryPart.Name, "Chassis")
			expect.equal(car:GetAttribute("CarId"), name)
			expect.truthy(type(car:GetAttribute("WheelRadius")) == "number", `{name} WheelRadius`)
			local seat = car:FindFirstChild("DriverSeat")
			expect.truthy(seat ~= nil and seat.ClassName == "VehicleSeat" and seat.CanTouch == false, `{name} seat`)
			local prompt = car:FindFirstChild("DriverPrompt", true)
			expect.truthy(prompt ~= nil and prompt.ClassName == "ProximityPrompt", `{name} prompt`)
			local wheels = car:FindFirstChild("Wheels"):GetChildren()
			expect.equal(#wheels, 4, `{name} wheels`)
			local steering = 0
			for _, wheel in wheels do
				for _, part in { "Strut", "Wheel" } do
					expect.truthy(wheel:FindFirstChild(part), `{name}.{wheel.Name}.{part}`)
				end
				for _, constraint in { "Slide", "Spring", "Motor" } do
					expect.truthy(wheel:FindFirstChild(constraint), `{name}.{wheel.Name}.{constraint}`)
				end
				if wheel:FindFirstChild("Steer") then
					steering += 1
				end
			end
			expect.equal(steering, 2, `{name} front wheels steer`)
			local welded: { [any]: boolean } = {}
			for _, w in car:GetDescendants() do
				if w.ClassName == "WeldConstraint" then
					welded[w.Part1] = true
				end
			end
			for _, part in car:GetDescendants() do
				if part:IsA("BasePart") then
					expect.equal(part.Anchored, false, `{name}.{part.Name} unanchored`)
					local free = part.Name == "Chassis" or part.Name == "Strut" or part.Name == "Knuckle"
					if not free and part.Name ~= "Wheel" then
						expect.truthy(welded[part], `{name}.{part:GetFullName()} welded`)
					end
				end
			end
		end
	end,
}
