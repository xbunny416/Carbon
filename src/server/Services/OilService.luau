--!strict
--[[
	OilService — the oil barrels (bible §5.4; numbers in Config.Oil). They are the game's only fuel.
	  - Every SpawnEvery seconds, while fewer than MaxBarrels are out, one barrel (cloned from
	    ReplicatedStorage.Assets.Models.OilBarrel) appears floating HoverHeight above a random spot of open desert
	    ground: away from the spawn center and the edge cliffs, never inside rocks, cacti or a mesa (a random spot
	    each time — there are no fixed oil spots). Untouched barrels vanish after Lifetime seconds.
	  - Every Tick, a car within PickupRadius of a barrel whose tank isn't full takes it: FuelPerBarrel fuel, a
	    "+fuel" notice for its owner, and a stalled car starts again (FuelService).
	Barrels live in Workspace.Oil, tagged "OilBarrel", anchored; the BaseCFrame attribute is where they float
	(Controllers/OilController bobs and spins them on each client).
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local FuelRules = require(Shared:WaitForChild("FuelRules"))
local Net = require(Shared:WaitForChild("Net"))

local CarService = require(script.Parent:WaitForChild("CarService"))

local OilService = {}

local ATTEMPTS = 40 -- random spots tried per barrel before giving up until the next turn

local folder: Folder
local random = Random.new()
local barrels: { [Model]: number } = {} -- barrel -> time it appeared

local function groundModel(): Instance?
	local desert = workspace:FindFirstChild("Desert")
	return desert and desert:FindFirstChild("Ground")
end

-- A random open spot of desert ground, as the CFrame a barrel floats at (nil if none was found this time).
local function findSpot(): CFrame?
	local ground = groundModel()
	if not ground then
		return nil
	end
	local map = Config.World.Map
	local origin = Vector3.new(map.Origin[1], map.Origin[2], map.Origin[3])
	local reach = map.Size / 2 - Config.Oil.EdgeMargin
	local down = RaycastParams.new()
	down.FilterType = Enum.RaycastFilterType.Include
	down.FilterDescendantsInstances = { ground }
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = { ground, folder }
	overlap.RespectCanCollide = true
	for _ = 1, ATTEMPTS do
		local x, z = random:NextNumber(-reach, reach), random:NextNumber(-reach, reach)
		if math.max(math.abs(x), math.abs(z)) >= Config.Oil.CenterClear then
			local hit = workspace:Raycast(origin + Vector3.new(x, 300, z), Vector3.new(0, -400, 0), down)
			if hit then
				local at = hit.Position + Vector3.new(0, Config.Oil.HoverHeight, 0)
				local clear = workspace:GetPartBoundsInRadius(at, Config.Oil.Clearance, overlap)
				-- Nothing solid around it, and open sky above (not under a rock arch or a mesa overhang).
				if #clear == 0 and not workspace:Raycast(at, Vector3.new(0, 200, 0)) then
					return CFrame.new(at) * CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0)
				end
			end
		end
	end
	return nil
end

local function spawnBarrel()
	local template = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Models"):FindFirstChild("OilBarrel")
	local spot = findSpot()
	if not template or not template:IsA("Model") or not spot then
		return
	end
	local barrel = template:Clone()
	barrel:PivotTo(spot)
	barrel:SetAttribute("BaseCFrame", spot)
	barrel:AddTag("OilBarrel")
	barrel.Parent = folder
	barrels[barrel] = os.clock()
end

local function remove(barrel: Model)
	barrels[barrel] = nil
	barrel:Destroy()
end

local function pickups()
	for player, car in CarService.all() do
		local chassis = car.PrimaryPart
		if chassis then
			for barrel in barrels do
				local fuel = tonumber(car:GetAttribute("Fuel")) or 0
				local max = tonumber(car:GetAttribute("FuelMax")) or fuel
				if not FuelRules.canTakeOil(fuel, max) then
					break
				end
				local at = barrel:GetPivot().Position
				if (at - chassis.Position).Magnitude <= Config.Oil.PickupRadius then
					remove(barrel)
					local after = FuelRules.addOil(fuel, max, Config.Oil.FuelPerBarrel)
					car:SetAttribute("Fuel", after)
					Net.fireClient("Notify", player, "Oil.Picked", { math.floor(after - fuel + 0.5) })
				end
			end
		end
	end
end

function OilService.Init(_self: any)
	local existing = workspace:FindFirstChild("Oil")
	if existing and existing:IsA("Folder") then
		folder = existing
	else
		folder = Instance.new("Folder")
		folder.Name = "Oil"
		folder.Parent = workspace
	end
	-- Barrels already in the place (e.g. left from an edit) are not tracked: clear them.
	for _, barrel in CollectionService:GetTagged("OilBarrel") do
		barrel:Destroy()
	end
end

function OilService.Start(_self: any)
	local sinceSpawn = Config.Oil.SpawnEvery
	local sinceTick = 0
	RunService.Heartbeat:Connect(function(dt: number)
		sinceSpawn += dt
		sinceTick += dt
		if sinceTick >= Config.Oil.Tick then
			sinceTick = 0
			pickups()
		end
		if sinceSpawn >= Config.Oil.SpawnEvery then
			sinceSpawn = 0
			local now = os.clock()
			local count = 0
			for barrel, born in barrels do
				if barrel.Parent == nil or now - born > Config.Oil.Lifetime then
					remove(barrel)
				else
					count += 1
				end
			end
			if count < Config.Oil.MaxBarrels then
				spawnBarrel()
			end
		end
	end)
end

return OilService
