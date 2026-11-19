--!strict
--[[
	FuelController — the fuel gauge (bible §5.3; the tank itself is Services/FuelService). While you drive your car,
	a FUEL bar at the bottom of the screen shows the car's Fuel / FuelMax attributes: orange, red below
	Config.Fuel.LowFraction. When your car is out of fuel (its Stalled attribute) and you sit in it or stand by it, a
	Tow home button asks the server to send it back to town (Net TowCar).
]]
local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Localization = require(Shared:WaitForChild("Localization"))
local Net = require(Shared:WaitForChild("Net"))

local Kit = require(script.Parent.Parent:WaitForChild("Ui"):WaitForChild("Kit"))
local InputController = require(script.Parent:WaitForChild("InputController"))

local REFRESH = 0.1
local FILL = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local POP = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local FuelController = {}

local player = Players.LocalPlayer
local gauge: Frame
local fill: Frame
local tow: TextButton
local towScale: UIScale
local shownFraction = -1

local function myCar(): Model?
	for _, car in CollectionService:GetTagged("Car") do
		if car:IsA("Model") and car:GetAttribute("OwnerUserId") == player.UserId and car.PrimaryPart then
			return car
		end
	end
	return nil
end

local function number(car: Model, name: string): number
	local value = car:GetAttribute(name)
	return if type(value) == "number" then value else 0
end

local function build()
	local gui = Kit.screen("Fuel", 3)
	gui.Enabled = true
	gauge = Kit.panel(
		gui,
		UDim2.fromScale(0.26, 0.06),
		UDim2.fromScale(0.5, 0.95),
		Vector2.new(0.5, 0.5),
		Vector2.new(340, 48)
	)
	gauge.Name = "Gauge"
	gauge.Visible = false
	local label = Kit.label(gauge, Localization.format("Fuel.Label"), UDim2.fromScale(0.2, 1), 20)
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.1, 0.5)
	label.Font = Kit.TitleFont
	local track = Instance.new("Frame")
	track.Name = "Track"
	track.AnchorPoint = Vector2.new(0.5, 0.5)
	track.Position = UDim2.fromScale(0.61, 0.5)
	track.Size = UDim2.fromScale(0.76, 0.7)
	track.BackgroundColor3 = Kit.Colors.Button
	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, 8)
	trackCorner.Parent = track
	track.Parent = gauge
	fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.AnchorPoint = Vector2.new(0.5, 0.5)
	fill.Position = UDim2.fromScale(0.5, 0.5)
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Kit.Colors.Accent
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 8)
	fillCorner.Parent = fill
	fill.Parent = track

	tow = Kit.button(gui, Localization.format("Fuel.Tow"), UDim2.fromScale(0.18, 0.07))
	tow.Name = "TowHome"
	tow.AnchorPoint = Vector2.new(0.5, 0.5)
	tow.Position = UDim2.fromScale(0.5, 0.78)
	tow.BackgroundColor3 = Kit.Colors.Accent
	tow.TextColor3 = Kit.Colors.OnAccent
	tow.Visible = false
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(260, 56)
	limit.Parent = tow
	towScale = Instance.new("UIScale")
	towScale.Parent = tow
	tow.Activated:Connect(function()
		Net.fire("TowCar")
	end)
end

local function setFraction(fraction: number)
	if math.abs(fraction - shownFraction) < 0.002 then
		return
	end
	shownFraction = fraction
	-- Anchored in the middle: the bar's center moves with its width so it stays pinned to the left end.
	TweenService:Create(fill, FILL, {
		Size = UDim2.fromScale(fraction, 1),
		Position = UDim2.fromScale(fraction / 2, 0.5),
	}):Play()
	fill.BackgroundColor3 = if fraction < Config.Fuel.LowFraction then Kit.Colors.Live else Kit.Colors.Accent
end

local function setTowVisible(visible: boolean)
	if tow.Visible == visible then
		return
	end
	tow.Visible = visible
	if visible then
		towScale.Scale = 0.8
		TweenService:Create(towScale, POP, { Scale = 1 }):Play()
		if InputController.getDevice() == "Gamepad" then
			GuiService.SelectedObject = tow
		end
	elseif GuiService.SelectedObject == tow then
		GuiService.SelectedObject = nil
	end
end

local function refresh()
	local car = myCar()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	local driving = car ~= nil and seat ~= nil and seat.Parent == car
	if car and driving then
		local max = number(car, "FuelMax")
		setFraction(if max > 0 then math.clamp(number(car, "Fuel") / max, 0, 1) else 0)
	end
	gauge.Visible = driving
	local root = humanoid and humanoid.RootPart
	local chassis = car and car.PrimaryPart
	local near = driving
		or (chassis ~= nil and root ~= nil and (root.Position - chassis.Position).Magnitude <= Config.Cars.FlipRange)
	setTowVisible(car ~= nil and car:GetAttribute("Stalled") == true and near)
end

function FuelController.Start(_self: any)
	build()
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt
		if elapsed >= REFRESH then
			elapsed = 0
			refresh()
		end
	end)
end

return FuelController
