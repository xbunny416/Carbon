--!strict
-- Saved-data template, migrations and the Signal utility.
local serde = require("@lune/serde")
local task = require("@lune/task")
local Roblox = require("../roblox")
local expect = require("../expect")

Roblox.setGlobals({ task = task })

local Shared = Roblox.game.ReplicatedStorage.Shared
local Config = Roblox.require(Shared.Config)
local DataTemplate = Roblox.require(Shared.Data.Template)
local Migrations = Roblox.require(Roblox.game.ServerScriptService.Server.Data.Migrations)
local Signal = Roblox.require(Shared.Util.Signal)

return {
	["template version matches VERSION"] = function()
		expect.equal(DataTemplate.Template.Version, DataTemplate.VERSION)
	end,
	["new players start at level 1 with starting Coins and zeroed stats"] = function()
		local template = DataTemplate.Template
		expect.equal(template.Level, 1)
		expect.equal(template.XP, 0)
		expect.equal(template.Coins, Config.Economy.StartingCoins)
		for stat, value in template.Stats do
			expect.equal(value, 0, stat)
		end
	end,
	["template survives a JSON round trip (DataStore-safe)"] = function()
		local encoded = serde.encode("json", DataTemplate.Template)
		local decoded = serde.decode("json", encoded)
		expect.equal(decoded.Coins, DataTemplate.Template.Coins)
		expect.equal(decoded.Settings.MusicVolume, DataTemplate.Template.Settings.MusicVolume)
	end,
	["template settings are a mutable copy of Config defaults"] = function()
		local settings = DataTemplate.Template.Settings
		expect.equal(table.isfrozen(settings), false)
		for key, value in Config.Data.DefaultSettings do
			expect.equal((settings :: any)[key], value, key)
		end
	end,
	["every released version has a migration step"] = function()
		for version = 1, DataTemplate.VERSION - 1 do
			expect.truthy(Migrations.Steps[version], `step {version} -> {version + 1}`)
		end
		local data = { Version = 1 }
		expect.equal(Migrations.run(data, DataTemplate.VERSION), true)
		expect.equal(data.Version, DataTemplate.VERSION)
	end,
	["migrations stop at a missing step"] = function()
		local data: { [string]: any } = { Version = DataTemplate.VERSION + 50 - 1 }
		expect.equal(Migrations.run(data, DataTemplate.VERSION + 50), false)
	end,
	["signal: connect, fire, disconnect, once"] = function()
		local signal = Signal.new()
		local total = 0
		local connection = signal:Connect(function(amount: number)
			total += amount
		end)
		signal:Once(function(amount: number)
			total += amount * 10
		end)
		signal:Fire(1)
		signal:Fire(2)
		connection:Disconnect()
		signal:Fire(100)
		expect.equal(total, 1 + 10 + 2)
		expect.equal(connection.Connected, false)
	end,
}
