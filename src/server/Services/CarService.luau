--!strict
--[[
	CarService — every player's car (bible §5.2).
	  - Spawns the starter car (Config.Cars.Starter, from ReplicatedStorage.Assets.Models.Cars) in a free CarSpawn bay
	    when the player's character first appears; removes it when they leave. Cars live in Workspace.Cars, tagged
	    "Car" with the owner's UserId in the OwnerUserId attribute.
	  - Sets each car's springs and motor strengths from its mass and its Config.Cars stats; the motor torques go in
	    the car's DriveTorque / BrakeTorque / CoastTorque attributes for CarController.
	  - The Drive prompt seats the owner (nobody else); the driver's client then owns the car's physics and runs the
	    motors. A parked car belongs to the server, its motors holding it like a parking brake.
	  - ExitCar puts the driver down beside the car, FlipCar rights an upside-down car that has stopped (after
	    Config.Cars.FlipDelay), ResetCar sends the car back to a free bay with its owner in it, TowCar does the same
	    for a car that ran out of fuel (no cooldown).
	  - Every car carries its tank in the Fuel / FuelMax attributes and Stalled (FuelService burns and refills it).
	    A stalled car belongs to the server, so its driver's client can't run the motors.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local CarsConfig = require(Shared:WaitForChild("Config"):WaitForChild("Cars"))
local CarRules = require(Shared:WaitForChild("CarRules"))
local Net = require(Shared:WaitForChild("Net"))

type CarStats = CarsConfig.CarStats

local CarService = {}

local WHEELS = 4

local folder: Folder
local cars: { [Player]: Model } = {}
local lastReset: { [Player]: number } = {}
local flipping: { [Player]: boolean } = {}

-- The player's car, if it still exists.
function CarService.get(player: Player): Model?
	local car = cars[player]
	if car and car.Parent and car.PrimaryPart then
		return car
	end
	return nil
end

local function seatOf(car: Model): VehicleSeat?
	local seat = car:FindFirstChild("DriverSeat")
	return if seat and seat:IsA("VehicleSeat") then seat else nil
end

local function humanoidOf(player: Player): Humanoid?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		return humanoid
	end
	return nil
end

-- True while `player` sits in their own car's driver seat.
function CarService.isDriving(player: Player): boolean
	local car = CarService.get(player)
	local seat = car and seatOf(car)
	local humanoid = humanoidOf(player)
	return seat ~= nil and humanoid ~= nil and seat.Occupant == humanoid
end

local function setOwner(car: Model, player: Player?)
	local chassis = car.PrimaryPart
	if chassis then
		local ok, err = pcall(function()
			chassis:SetNetworkOwner(player)
		end)
		if not ok then
			warn(`[Cars] network owner for {car.Name}: {err}`)
		end
	end
end

-- Springs, steering and motor strengths from the car's mass (Massless body parts don't count).
local function tune(car: Model, stats: CarStats)
	local mass = 0
	for _, part in car:GetDescendants() do
		if part:IsA("BasePart") and not part.Massless then
			mass += part:GetMass()
		end
	end
	local radius = car:GetAttribute("WheelRadius")
	local wheelRadius = if type(radius) == "number" then radius else 1.7
	local stiffness, damping = CarRules.spring(mass, workspace.Gravity, WHEELS, stats.Sag, stats.DampingRatio)
	local function torque(acceleration: number): number
		return CarRules.wheelTorque(mass, acceleration, wheelRadius, WHEELS, Config.Cars.MotorMargin)
	end
	car:SetAttribute("DriveTorque", torque(stats.Acceleration))
	car:SetAttribute("BrakeTorque", torque(stats.Braking))
	car:SetAttribute("CoastTorque", torque(stats.Coasting))
	for _, instance in car:GetDescendants() do
		if instance:IsA("SpringConstraint") then
			local rest = instance:GetAttribute("RestLength")
			instance.FreeLength = (if type(rest) == "number" then rest else 2) + stats.Sag
			instance.Stiffness = stiffness
			instance.Damping = damping
		elseif instance:IsA("HingeConstraint") and instance.Name == "Motor" then
			instance.AngularVelocity = 0
			instance.MotorMaxTorque = torque(stats.Braking)
		elseif instance:IsA("HingeConstraint") and instance.Name == "Steer" then
			instance.TargetAngle = 0
			instance.AngularSpeed = math.rad(stats.SteerSpeed)
			instance.ServoMaxTorque = mass * workspace.Gravity * wheelRadius
		end
	end
end

-- The CarSpawn bays in Index order, and whether a car stands in each.
local function freeBay(except: Model?): BasePart?
	local bays: { BasePart } = {}
	for _, marker in CollectionService:GetTagged("CarSpawn") do
		if marker:IsA("BasePart") then
			table.insert(bays, marker)
		end
	end
	table.sort(bays, function(a: BasePart, b: BasePart): boolean
		return (tonumber(a:GetAttribute("Index")) or 0) < (tonumber(b:GetAttribute("Index")) or 0)
	end)
	for _, bay in bays do
		local taken = false
		for _, car in folder:GetChildren() do
			local chassis = if car:IsA("Model") and car ~= except then car.PrimaryPart else nil
			if chassis then
				local offset = chassis.Position - bay.Position
				if Vector3.new(offset.X, 0, offset.Z).Magnitude < Config.Cars.BayClearance then
					taken = true
					break
				end
			end
		end
		if not taken then
			return bay
		end
	end
	return bays[1]
end

-- Where a driver stands after getting out: beside the driver's door, upright, facing the way the car faces.
local function exitPoint(car: Model): CFrame
	local chassis = car.PrimaryPart :: BasePart
	local right = chassis.CFrame.RightVector
	local flat = Vector3.new(right.X, 0, right.Z)
	if flat.Magnitude < 0.1 then
		flat = Vector3.xAxis
	end
	local position = chassis.Position - flat.Unit * Config.Cars.ExitSide + Vector3.new(0, 3, 0)
	local look = Vector3.new(chassis.CFrame.LookVector.X, 0, chassis.CFrame.LookVector.Z)
	return CFrame.lookAt(position, position + (if look.Magnitude > 0.1 then look.Unit else Vector3.zAxis))
end

local function exitDriver(player: Player, car: Model)
	local seat = seatOf(car)
	local humanoid = humanoidOf(player)
	if not seat or not humanoid or seat.Occupant ~= humanoid then
		return
	end
	local weld = seat:FindFirstChild("SeatWeld")
	if weld then
		weld:Destroy()
	end
	humanoid.Sit = false
	local character = player.Character
	if character then
		character:PivotTo(exitPoint(car))
	end
end

local function sitDriver(player: Player, car: Model)
	local seat = seatOf(car)
	local humanoid = humanoidOf(player)
	if seat and humanoid and seat.Occupant == nil then
		seat:Sit(humanoid)
	end
end

local function onPrompt(car: Model, player: Player)
	if car:GetAttribute("OwnerUserId") ~= player.UserId or CarService.get(player) ~= car then
		return
	end
	local humanoid = humanoidOf(player)
	local root = humanoid and humanoid.RootPart
	local chassis = car.PrimaryPart
	if not humanoid or not root or not chassis or humanoid.SeatPart ~= nil then
		return
	end
	if (root.Position - chassis.Position).Magnitude > Config.Cars.EnterRange then
		return
	end
	sitDriver(player, car)
end

-- Builds `player`'s car in a free bay (replacing any old one).
local function spawnCar(player: Player): Model?
	local old = cars[player]
	if old then
		old:Destroy()
		cars[player] = nil
	end
	local id = Config.Cars.Starter
	local stats = Config.Cars.Models[id]
	local templates = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Models"):WaitForChild("Cars")
	local template = templates:FindFirstChild(id)
	local bay = freeBay(nil)
	if not stats or not template or not template:IsA("Model") or not bay then
		warn(`[Cars] cannot spawn {id}: missing template, stats or CarSpawn bays`)
		return nil
	end
	local car = template:Clone()
	car.Name = `Car{player.UserId}`
	car:SetAttribute("OwnerUserId", player.UserId)
	car:SetAttribute("Fuel", stats.Tank)
	car:SetAttribute("FuelMax", stats.Tank)
	car:SetAttribute("Stalled", false)
	car:AddTag("Car")
	-- The bay's floor, the car's ride height (its chassis center above the ground when built) and a small drop.
	local primary = car.PrimaryPart :: BasePart
	local rideHeight = primary.Position.Y - (car:GetBoundingBox().Position.Y - car:GetExtentsSize().Y / 2)
	local floor = bay.Position - Vector3.new(0, bay.Size.Y / 2, 0)
	local rotation = bay.CFrame - bay.Position
	car:PivotTo(CFrame.new(floor + Vector3.new(0, rideHeight + 0.3, 0)) * rotation)
	tune(car, stats)
	car.Parent = folder
	setOwner(car, nil)
	cars[player] = car

	local seat = seatOf(car)
	if seat then
		seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			local occupant = seat.Occupant
			local driver = occupant and Players:GetPlayerFromCharacter(occupant.Parent)
			if occupant and driver ~= player then
				-- Only the owner drives (seats are entered through the owner-only prompt; this is a safety net).
				local weld = seat:FindFirstChild("SeatWeld")
				if weld then
					weld:Destroy()
				end
				return
			end
			setOwner(car, if occupant and car:GetAttribute("Stalled") ~= true then player else nil)
		end)
	end
	local prompt = car:FindFirstChild("DriverPrompt", true)
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.Triggered:Connect(function(who: Player)
			onPrompt(car, who)
		end)
	end
	car.Destroying:Connect(function()
		if cars[player] == car then
			cars[player] = nil
		end
	end)
	return car
end

local function onFlip(player: Player)
	local car = CarService.get(player)
	local chassis = car and car.PrimaryPart
	if not car or not chassis or flipping[player] then
		return
	end
	local function allowed(): boolean
		local humanoid = humanoidOf(player)
		local root = humanoid and humanoid.RootPart
		local near = CarService.isDriving(player)
			or (root ~= nil and (root.Position - chassis.Position).Magnitude <= Config.Cars.FlipRange)
		return near
			and CarRules.canFlip(
				chassis.CFrame.UpVector.Y,
				chassis.AssemblyLinearVelocity.Magnitude,
				Config.Cars.FlippedBelowUp,
				Config.Cars.FlipMaxSpeed
			)
	end
	if not allowed() then
		return
	end
	flipping[player] = true
	task.delay(Config.Cars.FlipDelay, function()
		flipping[player] = nil
		if CarService.get(player) ~= car or not allowed() then
			return
		end
		local look = chassis.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		local forward = if flat.Magnitude > 0.1 then flat.Unit else -Vector3.zAxis
		local position = chassis.Position + Vector3.new(0, Config.Cars.FlipLift, 0)
		car:PivotTo(CFrame.lookAt(position, position + forward))
		for _, part in car:GetDescendants() do
			if part:IsA("BasePart") then
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
			end
		end
	end)
end

-- A new car in a free bay (full tank) with its owner in the driver's seat.
local function sendHome(player: Player)
	local car = spawnCar(player)
	local character = player.Character
	if car and character and humanoidOf(player) then
		character:PivotTo(exitPoint(car))
		sitDriver(player, car)
	end
end

local function onReset(player: Player)
	local now = os.clock()
	local wait = Config.Cars.ResetCooldown - (now - (lastReset[player] or -math.huge))
	if wait > 0 then
		Net.fireClient("Notify", player, "Car.ResetWait", { math.ceil(wait) })
		return
	end
	lastReset[player] = now
	sendHome(player)
	Net.fireClient("Notify", player, "Car.ResetDone")
end

local function onTow(player: Player)
	local car = CarService.get(player)
	if car and car:GetAttribute("Stalled") == true then
		sendHome(player)
		Net.fireClient("Notify", player, "Fuel.Towed")
	end
end

-- Every player's car that still exists.
function CarService.all(): { [Player]: Model }
	local live: { [Player]: Model } = {}
	for player in cars do
		local car = CarService.get(player)
		if car then
			live[player] = car
		end
	end
	return live
end

--[[
	Stalls a car (out of fuel: the server takes its physics, so the motors just hold it) or starts it again (the
	driver, if seated, gets the physics back).
]]
function CarService.setStalled(player: Player, car: Model, stalled: boolean)
	car:SetAttribute("Stalled", stalled)
	setOwner(car, if not stalled and CarService.isDriving(player) then player else nil)
	if stalled then
		for _, instance in car:GetDescendants() do
			if instance:IsA("HingeConstraint") and instance.Name == "Motor" then
				instance.AngularVelocity = 0
				instance.MotorMaxTorque = tonumber(car:GetAttribute("CoastTorque")) or 0
			end
		end
	end
end

function CarService.Init(_self: any)
	local existing = workspace:FindFirstChild("Cars")
	if existing and existing:IsA("Folder") then
		folder = existing
	else
		folder = Instance.new("Folder")
		folder.Name = "Cars"
		folder.Parent = workspace
	end

	Net.onServerEvent("ExitCar", function(player: Player)
		local car = CarService.get(player)
		if car then
			exitDriver(player, car)
		end
	end)
	Net.onServerEvent("FlipCar", onFlip)
	Net.onServerEvent("ResetCar", onReset)
	Net.onServerEvent("TowCar", onTow)

	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function()
			if not CarService.get(player) then
				task.defer(spawnCar, player)
			end
		end)
		if player.Character and not CarService.get(player) then
			task.defer(spawnCar, player)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		local car = cars[player]
		cars[player] = nil
		lastReset[player] = nil
		flipping[player] = nil
		if car then
			car:Destroy()
		end
	end)
end

return CarService
