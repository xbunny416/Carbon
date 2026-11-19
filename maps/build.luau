--!strict
--[[
	Generates the map models from the layouts in maps/layouts.
	  lune run maps/build           writes maps/generated/*.rbxmx (commit them; Rojo syncs them into the place)
	  lune run maps/build --check   exits 1 if the committed files are out of date
	Add a map: write maps/layouts/<Name>.luau with build(origin), list it below, point default.project.json at the
	generated file, restart `rojo serve`.
]]
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Shim = require("../tests/roblox")
local Lobby = require("./layouts/Lobby")

local Config = Shim.require(Shim.game.ReplicatedStorage.Shared.Config)

local OUTPUT_DIR = "maps/generated"

local function outputs(): { { file: string, model: any } }
	return {
		{ file = "Lobby.rbxmx", model = Lobby.build(Config.World.LobbyOrigin) },
	}
end

local check = table.find(process.args, "--check") ~= nil
local stale: { string } = {}

for _, output in outputs() do
	local path = `{OUTPUT_DIR}/{output.file}`
	local content = roblox.serializeModel({ output.model }, true)
	if check then
		if not fs.isFile(path) or fs.readFile(path) ~= content then
			table.insert(stale, path)
		end
	else
		fs.writeDir(OUTPUT_DIR)
		fs.writeFile(path, content)
		print(`wrote {path} ({#output.model:GetDescendants()} instances)`)
	end
end

if #stale > 0 then
	print(`Out of date (run "lune run maps/build"): {table.concat(stale, ", ")}`)
	process.exit(1)
end
