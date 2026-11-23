--!strict
--[[
	CarController — the local player's car (bible §5.2; the server side is Services/CarService).
	  - While you sit in your own car's driver seat, every frame it reads the seat's ThrottleFloat / SteerFloat
	    (filled by Roblox's vehicle controls: W A S D / arrows, gamepad triggers + left stick, touch thumbstick) and
	    sets the wheel motors and the front-wheel steering (Shared/CarRules). The car's physics runs on this client
	    while you drive, so the motors respond at once.
	  - Jumping is off while driving (it would throw you out of the seat). Interact (E / B / the Get out button) asks
	    the server to let you out.
	  - Flip (R / Y / the Flip button, shown only while your stopped car is upside down) asks the server to turn it
	    back over.
	  - Only your own car's Drive prompt shows (in your language); other players' prompts stay hidden.
	  - A small hint at the bottom shows the key for Get out / Flip on keyboard and gamepad.
	  - A Spawn car button at the bottom (and SpawnCar: C / D-pad Down) while you're on foot asks the server to put
	    your car beside you (CarService: open ground, cooldown, fuel rules).
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local CarRules = require(Shared:WaitForChild("CarRules"))
local Localization = require(Shared:WaitForChild("Localization"))
local Net = require(Shared:WaitForChild("Net"))

local Ui = script.Parent.Parent:WaitForChild("Ui")
local Kit = require(Ui:WaitForChild("Kit"))
local KeyHint = require(Ui:WaitForChild("KeyHint"))
local InputController = require(script.Parent:WaitForChild("InputController"))

local POP = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local CarController = {}

local player = Players.LocalPlayer
local driving: Model? = nil
local canFlip = false
local hintPanel: Frame? = nil
local spawnButton: TextButton? = nil
local spawnScale: UIScale? = nil
local hintRows: { [string]: Frame } = {}

local function isMine(car: Instance): boolean
	return car:GetAttribute("OwnerUserId") == player.UserId
end

local function humanoid(): Humanoid?
	local character = player.Character
	return if character then character:FindFirstChildOfClass("Humanoid") else nil
end

-- The local player's car, if it is streamed in.
local function myCar(): Model?
	for _, car in CollectionService:GetTagged("Car") do
		if car:IsA("Model") and isMine(car) and car.PrimaryPart then
			return car
		end
	end
	return nil
end

-- The local player's car while they sit in its driver seat.
local function drivenCar(): Model?
	local h = humanoid()
	local seat = h and h.SeatPart
	if seat and seat:IsA("VehicleSeat") and seat.Name == "DriverSeat" then
		local car = seat.Parent
		if car and car:IsA("Model") and isMine(car) then
			return car
		end
	end
	return nil
end

local function promptOf(car: Instance): ProximityPrompt?
	local prompt = car:FindFirstChild("DriverPrompt", true)
	return if prompt and prompt:IsA("ProximityPrompt") then prompt else nil
end

local function setupCar(car: Instance)
	local prompt = promptOf(car)
	if not prompt then
		return
	end
	if isMine(car) then
		prompt.ActionText = Localization.format("Car.Drive")
		local id = car:GetAttribute("CarId")
		prompt.ObjectText = if type(id) == "string" then Localization.format(`Car.{id}`) else ""
	else
		prompt.Enabled = false
	end
end

---------------------------------------------------------------------------------------------------------------------
-- Driving
---------------------------------------------------------------------------------------------------------------------

local function drive(car: Model)
	local chassis = car.PrimaryPart
	local seat = car:FindFirstChild("DriverSeat")
	local wheels = car:FindFirstChild("Wheels")
	local id = car:GetAttribute("CarId")
	local radius = car:GetAttribute("WheelRadius")
	local stats = if type(id) == "string" then Config.Cars.Models[id] else nil
	if
		not chassis
		or not seat
		or not seat:IsA("VehicleSeat")
		or not wheels
		or not stats
		or type(radius) ~= "number"
	then
		return
	end
	local forward = chassis.AssemblyLinearVelocity:Dot(chassis.CFrame.LookVector)
	-- Out of fuel: no throttle (the server owns a stalled car anyway, so the motors just hold it).
	local throttle = if car:GetAttribute("Stalled") == true then 0 else seat.ThrottleFloat
	local target, mode = CarRules.drive(throttle, forward, stats)
	local torque = car:GetAttribute(`{mode}Torque`)
	local angle = CarRules.steerAngle(seat.SteerFloat, forward, stats)
	local base = car:GetAttribute("WheelBase")
	for _, wheel in wheels:GetChildren() do
		local motor = wheel:FindFirstChild("Motor")
		if motor and motor:IsA("HingeConstraint") then
			-- Each wheel at its own speed for the turn (inner wheels slower), so the wheels don't fight the steering.
			local tire = wheel:FindFirstChild("Wheel")
			local factor = 1
			if tire and tire:IsA("BasePart") and type(base) == "number" then
				local at = chassis.CFrame:PointToObjectSpace(tire.Position)
				factor = CarRules.wheelFactor(angle, at.X, at.Z, base)
			end
			motor.AngularVelocity = CarRules.wheelSpin(target * factor, radius)
			if type(torque) == "number" then
				motor.MotorMaxTorque = torque
			end
		end
		local steer = wheel:FindFirstChild("Steer")
		if steer and steer:IsA("HingeConstraint") then
			steer.TargetAngle = angle
		end
	end
end

local function refreshHints()
	local panel = hintPanel
	if not panel then
		return
	end
	local touch = InputController.getDevice() == "Touch"
	hintRows.Interact.Visible = driving ~= nil
	hintRows.Flip.Visible = canFlip
	panel.Visible = not touch and (driving ~= nil or canFlip)
end

local function setDriving(car: Model?)
	if car == driving then
		return
	end
	driving = car
	local h = humanoid()
	if h then
		h:SetStateEnabled(Enum.HumanoidStateType.Jumping, car == nil)
	end
	local mine = car or myCar()
	local prompt = mine and promptOf(mine)
	if prompt then
		prompt.Enabled = car == nil
	end
	InputController.setVisible("Interact", car ~= nil)
	refreshHints()
end

local function setCanFlip(state: boolean)
	if state == canFlip then
		return
	end
	canFlip = state
	InputController.setVisible("Flip", state)
	refreshHints()
end

local function step()
	local car = drivenCar()
	setDriving(car)
	if car then
		drive(car)
	end
	local mine = car or myCar()
	local chassis = mine and mine.PrimaryPart
	local h = humanoid()
	local root = h and h.RootPart
	local near = car ~= nil
		or (chassis ~= nil and root ~= nil and (root.Position - chassis.Position).Magnitude <= Config.Cars.FlipRange)
	setCanFlip(
		chassis ~= nil
			and near
			and CarRules.canFlip(
				chassis.CFrame.UpVector.Y,
				chassis.AssemblyLinearVelocity.Magnitude,
				Config.Cars.FlippedBelowUp,
				Config.Cars.FlipMaxSpeed
			)
	)
	-- The Spawn car button shows while you are on foot (and alive).
	local button, scale = spawnButton, spawnScale
	local onFoot = car == nil and h ~= nil and h.Health > 0
	if button and scale and button.Visible ~= onFoot then
		button.Visible = onFoot
		if onFoot then
			scale.Scale = 0.85
			TweenService:Create(scale, POP, { Scale = 1 }):Play()
		end
	end
end

---------------------------------------------------------------------------------------------------------------------
-- Hints and the Car menu screen
---------------------------------------------------------------------------------------------------------------------

local function buildHints()
	local gui = Kit.screen("CarHints", 3)
	gui.Enabled = true
	local panel = Kit.panel(
		gui,
		UDim2.fromScale(0.24, 0.07),
		UDim2.fromScale(0.5, 0.86),
		Vector2.new(0.5, 0.5),
		Vector2.new(300, 56)
	)
	panel.Name = "CarHints"
	panel.Visible = false
	for _, row in { { "Interact", "Car.Exit" }, { "Flip", "Car.FlipHint" } } do
		local frame = Instance.new("Frame")
		frame.Name = row[1]
		frame.BackgroundTransparency = 1
		frame.Size = UDim2.fromScale(1, 1)
		frame.Visible = false
		local layout = Kit.list(frame, Enum.FillDirection.Horizontal, UDim.new(0.04, 0))
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		local hint = KeyHint.new(frame, row[1], UDim2.fromScale(0.2, 1))
		hint.LayoutOrder = 1
		local square = Instance.new("UIAspectRatioConstraint")
		square.Parent = hint
		local label = Kit.label(frame, Localization.format(row[2]), UDim2.fromScale(0.72, 0.9), 22)
		label.LayoutOrder = 2
		label.TextXAlignment = Enum.TextXAlignment.Left
		frame.Parent = panel
		hintRows[row[1]] = frame
	end
	hintPanel = panel
	InputController.DeviceChanged:Connect(refreshHints)
end

-- The Spawn car button: bottom center, with the key / gamepad hint for SpawnCar on its left (none on touch).
local function buildSpawnButton()
	local gui = Kit.screen("CarSpawn", 3)
	gui.Enabled = true
	local button = Kit.button(gui, Localization.format("Controls.SpawnCar"), UDim2.fromScale(0.2, 0.075))
	button.Name = "SpawnCar"
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Position = UDim2.fromScale(0.5, 0.92)
	button.BackgroundColor3 = Kit.Colors.Accent
	button.TextColor3 = Kit.Colors.OnAccent
	button.Visible = false
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(280, 60)
	limit.Parent = button
	local padding = button:FindFirstChildOfClass("UIPadding")
	if padding then
		padding.PaddingLeft = UDim.new(0.24, 0)
	end
	local hint = KeyHint.new(button, "SpawnCar", UDim2.fromScale(0.16, 0.8))
	hint.AnchorPoint = Vector2.new(0.5, 0.5)
	hint.Position = UDim2.fromScale(-0.14, 0.5)
	local square = Instance.new("UIAspectRatioConstraint")
	square.Parent = hint
	local scale = Instance.new("UIScale")
	scale.Parent = button
	button.Activated:Connect(function()
		Net.fire("SpawnCar")
	end)
	spawnButton = button
	spawnScale = scale
end

---------------------------------------------------------------------------------------------------------------------
-- Lifecycle
---------------------------------------------------------------------------------------------------------------------

function CarController.Init(_self: any)
	InputController.setLabel("Interact", "Car.Exit")
	InputController.setVisible("Interact", false)
	InputController.setVisible("Flip", false)
end

function CarController.Start(_self: any)
	buildHints()
	buildSpawnButton()
	for _, car in CollectionService:GetTagged("Car") do
		setupCar(car)
	end
	CollectionService:GetInstanceAddedSignal("Car"):Connect(setupCar)
	InputController.ActionBegan:Connect(function(action: string)
		if action == "Interact" and driving then
			Net.fire("ExitCar")
		elseif action == "Flip" and canFlip then
			Net.fire("FlipCar")
		elseif action == "SpawnCar" and not driving then
			Net.fire("SpawnCar")
		end
	end)
	player.CharacterAdded:Connect(function()
		driving = nil
		refreshHints()
	end)
	RunService.Heartbeat:Connect(step)
end

return CarController
