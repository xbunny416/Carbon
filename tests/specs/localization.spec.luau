--!strict
-- GameStrings.csv must be well-formed and cover every key the game uses.
local fs = require("@lune/fs")
local csv = require("../../tools/csv")
local Roblox = require("../roblox")
local expect = require("../expect")

local Config = Roblox.require(Roblox.game.ReplicatedStorage.Shared.Config)

local CSV_PATH = "src/localization/GameStrings.csv"

local rows = csv.parse(fs.readFile(CSV_PATH))
local keys: { [string]: string } = {}
for index = 2, #rows do
	keys[rows[index][1]] = rows[index][2]
end

local function walk(dir: string, out: { string })
	for _, name in fs.readDir(dir) do
		local path = `{dir}/{name}`
		if fs.isDir(path) then
			walk(path, out)
		elseif string.sub(name, -5) == ".luau" then
			table.insert(out, path)
		end
	end
end

return {
	["header is Key,Source,Context,Example"] = function()
		expect.equal(table.concat(rows[1], ","), "Key,Source,Context,Example")
	end,
	["every row has 4 columns, a key and source text, and keys are unique"] = function()
		local seen: { [string]: boolean } = {}
		for index = 2, #rows do
			local row = rows[index]
			expect.equal(#row, 4, `row {index} columns`)
			expect.truthy(row[1] ~= "" and row[2] ~= "", `row {index} key/source`)
			expect.equal(seen[row[1]], nil, `duplicate key {row[1]}`)
			seen[row[1]] = true
		end
	end,
	["no hard-coded UI text: every Text / PlaceholderText / prompt text set in code comes from GameStrings"] = function()
		local files: { string } = {}
		walk("src", files)
		for _, path in files do
			local lineNumber = 0
			for line in string.gmatch(fs.readFile(path), "[^\n]+") do
				lineNumber += 1
				local code = string.gsub(line, "%-%-.*$", "")
				local field, value = string.match(code, '[%.%s](%a*Text)%s*=%s*"([^"]*)"')
				if field and value and string.find(value, "%a") then
					error(`{path}:{lineNumber} sets {field} to a hard-coded string: "{value}"`)
				end
			end
		end
	end,
	["strings with {n} placeholders have an example (translators see a filled-in line)"] = function()
		local missing: { string } = {}
		for index = 2, #rows do
			local row = rows[index]
			if string.find(row[2], "{%d+}") and (row[4] == nil or row[4] == "") then
				table.insert(missing, row[1])
			end
		end
		expect.equal(table.concat(missing, ", "), "", "keys without an Example")
	end,
	["every tip and control has its string"] = function()
		for index = 1, Config.World.Loading.TipCount do
			expect.truthy(keys[`Tip.{index}`], `Tip.{index}`)
		end
		for _, action in Config.Controls.Actions do
			expect.truthy(keys[`Controls.{action}`], `Controls.{action}`)
		end
	end,
	["every literal key used in code exists"] = function()
		local files: { string } = {}
		walk("src", files)
		for _, path in files do
			local source = fs.readFile(path)
			for key in string.gmatch(source, 'Localization%.format%(%s*"([^"]+)"') do
				expect.truthy(keys[key], `{path} uses missing key {key}`)
			end
			for key in string.gmatch(source, 'Net%.fire%w*%(%s*"Notify"[^"\n]*"([^"]+)"') do
				expect.truthy(keys[key], `{path} notifies with missing key {key}`)
			end
		end
	end,
}
