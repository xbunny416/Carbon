--!strict
--[[
	CarKit — turns a car body into a drivable car model for ReplicatedStorage.Assets.Models.Cars (bible §5.2).

	The body is built with the map Builder (maps/lib), front = -Z, tires touching y = 0. CarKit adds:
	  - Chassis: the heavy part every body part is welded to (body parts are Massless, so the weight sits low), the
	    model's PrimaryPart. Attachments: one per wheel and the Drive prompt.
	  - DriverSeat: a VehicleSeat (Roblox's vehicle controls fill its ThrottleFloat / SteerFloat). Touching it never
	    sits you down; the Drive prompt does (CarService).
	  - Wheels/<FL|FR|RL|RR>: a Strut sliding up and down on the chassis (PrismaticConstraint "Slide") held up by a
	    SpringConstraint "Spring", a HingeConstraint "Motor" spinning the Wheel, and on the front wheels a Knuckle
	    turned by a servo HingeConstraint "Steer".
	CarService sets the spring and motor strengths from the car's mass and Config.Cars; CarController runs the motors.
]]
local B = require("../../maps/lib/Builder")
local Props = require("../../maps/lib/Props")

local roblox = B.roblox
local Instance = roblox.Instance
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Enum = B.Enum

local CarKit = {}

export type Spec = {
	Name: string,
	WheelRadius: number,
	WheelWidth: number,
	Track: number, -- x of the wheel centers (±)
	Base: number, -- z of the wheel centers (±)
	Chassis: { number }, -- size; it sits on the wheel centers' height + half its height
	Seat: { number }, -- center of the driver's seat (its top is where you sit)
	Prompt: { number }, -- where the Drive prompt shows (by the driver's door)
	Body: (F: Props.Frame) -> (), -- builds the body parts
}

local SPRING_REST = 2 -- studs from a wheel center up to its spring's top attachment
local TRAVEL_UP, TRAVEL_DOWN = 0.7, 0.8 -- suspension travel (studs)
local SMALL = 6 -- studs³: body parts smaller than this don't collide (trim, lights, mirrors)

-- An attachment whose primary axis (X) points `axis` ("X" = sideways, "Y" = up), at `position` in `part`'s space.
local function attachment(part: any, name: string, position: any, axis: string): any
	local a = Instance.new("Attachment")
	a.Name = name
	local at = position
	a.CFrame = if axis == "Y"
		then CFrame.fromMatrix(at, Vector3.new(0, 1, 0), Vector3.new(-1, 0, 0))
		else CFrame.new(at.X, at.Y, at.Z)
	a.Parent = part
	return a
end

local function weld(folder: any, part0: any, part1: any)
	local w = Instance.new("WeldConstraint")
	w.Name = part1.Name
	w.Part0 = part0
	w.Part1 = part1
	w.Parent = folder
end

local function hidden(part: any)
	part.Transparency = 1
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
end

local function wheel(spec: Spec, folder: any, chassis: any, name: string, x: number, z: number, front: boolean)
	local r = spec.WheelRadius
	local center = Vector3.new(x, r, z)
	local local0 = center - chassis.CFrame.Position
	B.into(folder, function()
		B.model(name, function()
			local F = Props.frame({ 0, 0, 0 }, 0)
			local strut = F.box({
				Name = "Strut",
				From = { x - 0.5, r - 0.5, z - 0.5 },
				To = { x + 0.5, r + 0.5, z + 0.5 },
				Color = "MetalDark",
			})
			hidden(strut)
			local hub = strut
			if front then
				hub = F.box({
					Name = "Knuckle",
					From = { x - 0.5, r - 0.5, z - 0.5 },
					To = { x + 0.5, r + 0.5, z + 0.5 },
					Color = "MetalDark",
				})
				hidden(hub)
			end
			local tire = F.part({
				Name = "Wheel",
				Shape = "Cylinder",
				Size = { spec.WheelWidth, r * 2, r * 2 },
				Position = { x, r, z },
				Color = "Black",
				Material = "Rubber",
				CastShadow = true,
			})
			tire.CustomPhysicalProperties = roblox.PhysicalProperties.new(0.9, 1.4, 0, 3, 100)
			local side = if x < 0 then -1 else 1
			local caps = {
				F.part({
					Name = "Hubcap",
					Shape = "Cylinder",
					Size = { 0.1, r * 1.1, r * 1.1 },
					Position = { x + side * (spec.WheelWidth / 2 + 0.03), r, z },
					Color = "Chrome",
					Material = "Metal",
				}),
				F.part({
					Name = "HubNut",
					Shape = "Cylinder",
					Size = { 0.15, r * 0.35, r * 0.35 },
					Position = { x + side * (spec.WheelWidth / 2 + 0.1), r, z },
					Color = "MetalDark",
				}),
			}
			local model = tire.Parent
			for _, cap in caps do
				cap.Massless = true
				cap.CanCollide = false
				cap.CanTouch = false
				cap.CanQuery = false
				weld(model, tire, cap)
			end

			local mount = attachment(chassis, `{name}Mount`, local0, "Y")
			local top = attachment(chassis, `{name}SpringTop`, local0 + Vector3.new(0, SPRING_REST, 0), "Y")
			local slide = Instance.new("PrismaticConstraint")
			slide.Name = "Slide"
			slide.Attachment0 = mount
			slide.Attachment1 = attachment(strut, "Slide", Vector3.new(0, 0, 0), "Y")
			slide.LimitsEnabled = true
			slide.LowerLimit = -TRAVEL_DOWN
			slide.UpperLimit = TRAVEL_UP
			slide.Restitution = 0
			slide.Parent = model

			local spring = Instance.new("SpringConstraint")
			spring.Name = "Spring"
			spring.Attachment0 = top
			spring.Attachment1 = attachment(strut, "SpringBottom", Vector3.new(0, 0, 0), "Y")
			spring.Visible = false
			spring:SetAttribute("RestLength", SPRING_REST)
			spring.Parent = model

			if front then
				local steer = Instance.new("HingeConstraint")
				steer.Name = "Steer"
				steer.Attachment0 = attachment(strut, "Steer", Vector3.new(0, 0, 0), "Y")
				steer.Attachment1 = attachment(hub, "Steer", Vector3.new(0, 0, 0), "Y")
				steer.ActuatorType = Enum.ActuatorType.Servo
				steer.LimitsEnabled = true
				steer.LowerAngle = -45
				steer.UpperAngle = 45
				steer.Parent = model
			end

			local motor = Instance.new("HingeConstraint")
			motor.Name = "Motor"
			motor.Attachment0 = attachment(hub, "Axle", Vector3.new(0, 0, 0), "X")
			motor.Attachment1 = attachment(tire, "Axle", Vector3.new(0, 0, 0), "X")
			motor.ActuatorType = Enum.ActuatorType.Motor
			motor.Parent = model
		end)
	end)
end

-- Builds the drivable car model.
function CarKit.build(spec: Spec, prompts: { Keyboard: string, Gamepad: string, MaxDistance: number }): any
	local chassis: any
	local seat: any
	local root = B.root(spec.Name, function()
		local F = Props.frame({ 0, 0, 0 }, 0)
		local size = spec.Chassis
		chassis = F.part({
			Name = "Chassis",
			Size = size,
			Position = { 0, spec.WheelRadius + size[2] / 2 - 0.1, 0 },
			Color = "MetalDark",
			Material = "DiamondPlate",
			CastShadow = true,
		})
		chassis.CustomPhysicalProperties = roblox.PhysicalProperties.new(3, 0.3, 0.1, 1, 1)
		B.model("Body", function()
			spec.Body(F)
		end)
	end)

	seat = Instance.new("VehicleSeat")
	seat.Name = "DriverSeat"
	seat.Size = Vector3.new(2, 0.6, 2)
	seat.CFrame = CFrame.new(spec.Seat[1], spec.Seat[2], spec.Seat[3])
	seat.Color = roblox.Color3.fromHex("#3A3936")
	seat.Material = Enum.Material.Fabric
	seat.TopSurface = Enum.SurfaceType.Smooth
	seat.BottomSurface = Enum.SurfaceType.Smooth
	seat.CanTouch = false
	seat.HeadsUpDisplay = false
	seat.MaxSpeed = 0
	seat.Torque = 0
	seat.TurnSpeed = 0
	seat.Parent = root

	local welds = Instance.new("Folder")
	welds.Name = "Welds"
	welds.Parent = chassis
	local body = root:FindFirstChild("Body")
	for _, part in body:GetDescendants() do
		if part:IsA("BasePart") then
			part.Massless = true
			local size = part.Size
			if size.X * size.Y * size.Z < SMALL then
				part.CanCollide = false
				part.CanTouch = false
				part.CanQuery = false
			end
			weld(welds, chassis, part)
		end
	end
	seat.Massless = true
	weld(welds, chassis, seat)

	local wheels = Instance.new("Folder")
	wheels.Name = "Wheels"
	wheels.Parent = root
	for _, w in
		{
			{ "FL", -spec.Track, -spec.Base, true },
			{ "FR", spec.Track, -spec.Base, true },
			{ "RL", -spec.Track, spec.Base, false },
			{ "RR", spec.Track, spec.Base, false },
		}
	do
		wheel(spec, wheels, chassis, w[1], w[2], w[3], w[4])
	end

	local origin = chassis.CFrame.Position
	local promptPoint = Instance.new("Attachment")
	promptPoint.Name = "PromptPoint"
	promptPoint.CFrame = CFrame.new(Vector3.new(spec.Prompt[1], spec.Prompt[2], spec.Prompt[3]) - origin)
	promptPoint.Parent = chassis
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "DriverPrompt"
	prompt.ActionText = "" -- CarController fills it in (localized) for the owner
	prompt.KeyboardKeyCode = (Enum.KeyCode :: any)[prompts.Keyboard]
	prompt.GamepadKeyCode = (Enum.KeyCode :: any)[prompts.Gamepad]
	prompt.MaxActivationDistance = prompts.MaxDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptPoint

	for _, part in root:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
		end
	end
	root.PrimaryPart = chassis
	root.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	root:SetAttribute("CarId", spec.Name)
	root:SetAttribute("WheelRadius", spec.WheelRadius)
	root:SetAttribute("WheelBase", spec.Base)
	return root
end

return CarKit
