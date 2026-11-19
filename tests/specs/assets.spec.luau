--!strict
-- ReplicatedStorage.Assets matches Config (run: lune run assets/build) and never holds an empty id.
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local expect = require("../expect")

local Assets = require("../../assets/Assets")

local built = Assets.build()

return {
	["the committed Assets.rbxmx is up to date"] = function()
		local path = "assets/generated/Assets.rbxmx"
		expect.truthy(fs.isFile(path), `{path} exists`)
		expect.equal(fs.readFile(path) == roblox.serializeModel({ built }, true), true, path)
	end,
	["the four template folders exist"] = function()
		for _, name in { "VFX", "Sounds", "Animations", "Models" } do
			expect.truthy(built:FindFirstChild(name), name)
		end
	end,
	["no Sound or Animation has an empty id"] = function()
		for _, instance in built:GetDescendants() do
			if instance:IsA("Sound") then
				expect.truthy(instance.SoundId ~= "" and instance.SoundId ~= "rbxassetid://0", instance.Name)
			elseif instance:IsA("Animation") then
				expect.truthy(instance.AnimationId ~= "" and instance.AnimationId ~= "rbxassetid://0", instance.Name)
			end
		end
	end,
}
