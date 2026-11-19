--!strict
-- Every formula in Shared/Formulas, checked against the numbers in docs/PROJECT_BIBLE.md.
local Roblox = require("../roblox")
local expect = require("../expect")

local F = Roblox.require(Roblox.game.ReplicatedStorage.Shared.Formulas)

return {
	["xp curve = floor(100 * L^1.4)"] = function()
		expect.equal(F.xpToNextLevel(1), 100)
		expect.equal(F.xpToNextLevel(2), 263)
		expect.equal(F.xpToNextLevel(10), 2511)
		expect.equal(F.xpToNextLevel(100), 0)
	end,
	["addXP levels up across several levels and stops at the cap"] = function()
		local level, xp, gained = F.addXP(1, 50, 400)
		expect.equal(level, 3, "level")
		expect.equal(xp, 87, "xp")
		expect.equal(gained, 2, "gained")
		local capLevel, capXP = F.addXP(99, 0, 10 ^ 9)
		expect.equal(capLevel, 100)
		expect.equal(capXP, 0)
	end,
	["day number rolls over at the reset hour (UTC)"] = function()
		expect.equal(F.dayNumber(0), 0)
		expect.equal(F.dayNumber(86399), 0)
		expect.equal(F.dayNumber(86400), 1)
		expect.equal(F.dayNumber(86400 + 3600, 2), 0)
	end,
}
