--!strict
--[[
	Config — every tunable number in the game (prices, rewards, cooldowns, odds, formula constants, keys, timings).
	Balance the game here only; docs/PROJECT_BIBLE.md documents the same values.
	The whole tree is frozen: reading is free, writing errors.
	Secrets that must not replicate to clients (e.g. redeem codes) belong in ServerScriptService.Server.ServerConfig.
]]
local Freeze = require(script.Parent.Util.Freeze)

local Config = {
	Net = require(script.Net),
	Data = require(script.Data),
	Progression = require(script.Progression),
	Monetization = require(script.Monetization),
	Controls = require(script.Controls),
	World = require(script.World),
	Cars = require(script.Cars),
	Fuel = require(script.Fuel),
	Oil = require(script.Oil),
	Audio = require(script.Audio),
	Animations = require(script.Animations),
	Dev = require(script.Dev),
}

return Freeze.deep(Config)
