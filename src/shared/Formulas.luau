--!strict
--[[
	Formulas — pure game math shared by server and client. No instances, no side effects: every function takes plain
	values and reads constants from Config, so tests/specs check it. Add the game's formulas here (with specs).
]]
local Config = require(script.Parent.Config)

local Progression = Config.Progression

local Formulas = {}

-- XP needed to go from `level` to `level + 1` (0 at the level cap).
function Formulas.xpToNextLevel(level: number): number
	if level >= Progression.LevelCap then
		return 0
	end
	return math.floor(Progression.XPCurve.Base * level ^ Progression.XPCurve.Exponent)
end

-- Adds XP and levels up as needed. Returns the new level, the XP into that level and how many levels were gained.
function Formulas.addXP(level: number, xp: number, gained: number): (number, number, number)
	local newLevel = level
	local newXP = xp + math.max(gained, 0)
	while newLevel < Progression.LevelCap do
		local needed = Formulas.xpToNextLevel(newLevel)
		if newXP < needed then
			break
		end
		newXP -= needed
		newLevel += 1
	end
	if newLevel >= Progression.LevelCap then
		newXP = 0
	end
	return newLevel, newXP, newLevel - level
end

-- Day number for daily resets: increments at `resetHourUTC` every day. `unixTime` is os.time().
function Formulas.dayNumber(unixTime: number, resetHourUTC: number?): number
	return math.floor((unixTime - (resetHourUTC or 0) * 3600) / 86400)
end

return Formulas
