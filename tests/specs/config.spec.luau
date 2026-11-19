--!strict
-- Structural checks on Config so a balance edit cannot silently break the game.
local Roblox = require("../roblox")
local expect = require("../expect")

local Config = Roblox.require(Roblox.game.ReplicatedStorage.Shared.Config)

return {
	["config is frozen all the way down"] = function()
		expect.equal(table.isfrozen(Config), true)
		expect.equal(table.isfrozen(Config.Data.DefaultSettings), true)
		expect.equal(
			pcall(function()
				(Config :: any).Economy.StartingCoins = 1
			end),
			false
		)
	end,
	["every pass and product has a price, and ids are whole numbers"] = function()
		for name, pass in Config.Monetization.GamePasses do
			expect.truthy(pass.Id >= 0 and pass.Id == math.floor(pass.Id) and pass.PriceRobux > 0, name)
		end
		for name, product in Config.Monetization.Products do
			expect.truthy(product.Id >= 0 and product.Id == math.floor(product.Id) and product.PriceRobux > 0, name)
		end
	end,
	["audio slots have whole ids and a volume between 0 and 1"] = function()
		for _, group in { Config.Audio.Music, Config.Audio.Sfx } do
			for name, slot in group do
				expect.truthy(slot.Id >= 0 and slot.Id == math.floor(slot.Id), `{name} id`)
				expect.truthy(slot.Volume >= 0 and slot.Volume <= 1, `{name} volume`)
			end
		end
		expect.truthy(Config.Audio.Pitch.Min <= Config.Audio.Pitch.Max, "pitch range")
	end,
	["developer tools are Studio-only unless UserIds are listed"] = function()
		for _, userId in Config.Dev.AllowedUserIds do
			expect.truthy(userId > 0 and userId == math.floor(userId), `UserId {userId}`)
		end
	end,
}
