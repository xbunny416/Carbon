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
	["in a turn the inner wheels roll slower than the outer ones, rear inner slowest"] = function()
		local base, track = 5.2, 3.55
		expect.equal(CarRules.wheelFactor(0, -track, -base, base), 1, "straight: all the same")
		local left = 30 -- positive = left turn
		local fl = CarRules.wheelFactor(left, -track, -base, base)
		local fr = CarRules.wheelFactor(left, track, -base, base)
		local rl = CarRules.wheelFactor(left, -track, base, base)
		local rr = CarRules.wheelFactor(left, track, base, base)
		expect.truthy(fl < fr and rl < rr, "left wheels slower in a left turn")
		expect.truthy(rl < fl, "rear inner wheel is the slowest")
		near(CarRules.wheelFactor(-left, track, base, base), rl, "a right turn mirrors a left one")
		expect.truthy(rr > 1 and rl < 1, "around the car's own speed")
	end,
	["no two differently colored wedges overlap on the same slope (that flickered on the windshield)"] = function()
		local problems: { string } = {}
		for name in Config.Cars.Models do
			local car = built.Models.Cars:FindFirstChild(name)
			local wedges: { any } = {}
			for _, part in car:GetDescendants() do
				if part.ClassName == "WedgePart" then
					table.insert(wedges, part)
				end
			end
			for i, a in wedges do
				for j = i + 1, #wedges do
					local b = wedges[j]
					local aligned = a.CFrame.RightVector:Dot(b.CFrame.RightVector) > 0.9999
						and a.CFrame.UpVector:Dot(b.CFrame.UpVector) > 0.9999
					local offset = a.CFrame:PointToObjectSpace(b.CFrame.Position)
					local sameSlope = math.abs(a.Size.Y - b.Size.Y) < 0.01
						and math.abs(a.Size.Z - b.Size.Z) < 0.01
						and math.abs(offset.Y) < 0.01
						and math.abs(offset.Z) < 0.01
					local overlapX = (a.Size.X + b.Size.X) / 2 - math.abs(offset.X)
					if a.Color ~= b.Color and aligned and sameSlope and overlapX > 0.01 then
						table.insert(problems, `{name}: {a.Name} / {b.Name}`)
					end
				end
			end
		end
		expect.equal(#problems, 0, table.concat(problems, "; "))
	end,
	["grip cancels sliding, capped, and downforce grows with speed"] = function()
		expect.truthy(CarRules.grip(5, stats.Grip, 1000) < 0, "pushes against a slide to the right")
		near(CarRules.grip(-2, 6, 1000), 12, "cancels at the given rate")
		near(CarRules.grip(100, 6, 50), -50, "capped")
		near(CarRules.downforce(-30, 0.5), 15, "either way of travel")
		near(CarRules.downforce(0, stats.Downforce), 0, "none standing still")
	end,
	["the turn assist steers toward the bicycle-model turn rate, capped"] = function()
		near(CarRules.targetTurnRate(30, 0, 10.4), 0, "straight")
		expect.truthy(CarRules.targetTurnRate(30, 20, 10.4) > 0, "left turn going forward turns left")
		expect.truthy(CarRules.targetTurnRate(-10, 20, 10.4) < 0, "reversing turns the other way")
		near(CarRules.turnAssist(1, 0.5, 4, 100), 2, "closes the gap at the response rate")
		near(CarRules.turnAssist(10, 0, 5, stats.TurnLimit), stats.TurnLimit, "capped")
		near(CarRules.yawInertia(12, 6, 0), 36, "box inertia")
	end,
	["every car has its zeroed Assist force and TurnAssist torque"] = function()
		for name in Config.Cars.Models do
			local chassis = built.Models.Cars:FindFirstChild(name).Chassis
			local force, torque = chassis:FindFirstChild("Assist"), chassis:FindFirstChild("TurnAssist")
			expect.truthy(force ~= nil and force.ClassName == "VectorForce", `{name} Assist`)
			expect.truthy(torque ~= nil and torque.ClassName == "Torque", `{name} TurnAssist`)
			expect.equal(force.Force.Magnitude, 0, `{name} Assist starts at zero`)
			expect.equal(torque.Torque.Magnitude, 0, `{name} TurnAssist starts at zero`)
		end
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
