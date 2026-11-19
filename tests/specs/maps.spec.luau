--!strict
-- The committed map models match their layouts, and the lobby has what the game needs.
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local Roblox = require("../roblox")
local expect = require("../expect")

local Lobby = require("../../maps/layouts/Lobby")

local Config = Roblox.require(Roblox.game.ReplicatedStorage.Shared.Config)

local function tagged(root: any, tag: string): { any }
	local found = {}
	for _, instance in root:GetDescendants() do
		if instance:HasTag(tag) then
			table.insert(found, instance)
		end
	end
	return found
end

local lobby = Lobby.build(Config.World.LobbyOrigin)

return {
	["generated .rbxmx files are up to date (run: lune run maps/build)"] = function()
		local path = "maps/generated/Lobby.rbxmx"
		expect.truthy(fs.isFile(path), `{path} exists`)
		expect.equal(fs.readFile(path) == roblox.serializeModel({ lobby }, true), true, path)
	end,
	["the lobby has spawn pads"] = function()
		expect.truthy(#tagged(lobby, "LobbySpawn") >= 1, "lobby spawns")
	end,
}
