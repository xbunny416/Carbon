--!strict
--[[
	The saved shape of a player's data. New fields added here are filled in for existing players automatically
	(ProfileStore Reconcile). Renames, removals or value changes need a migration: bump VERSION and add a step in
	Server/Data/Migrations.
]]
local Config = require(script.Parent.Parent.Config)

export type Settings = {
	MusicVolume: number,
	SfxVolume: number,
	CameraShake: boolean,
	LowGraphics: boolean,
	ButtonLayout: string,
}

-- Lifetime stats: add one field per stat the game counts (DataService.incrementStat checks the name).
export type Stats = {
	SessionsPlayed: number,
}

export type PlayerData = {
	Version: number,
	Level: number,
	XP: number, -- XP into the current level
	Stats: Stats,
	Settings: Settings,
	PurchaseIds: { string }, -- recent developer-product purchases already granted
}

local VERSION = 2 -- 2: Coins removed (2026-11-23, no coin system)

local Template: PlayerData = {
	Version = VERSION,
	Level = 1,
	XP = 0,
	Stats = { SessionsPlayed = 0 },
	Settings = table.clone(Config.Data.DefaultSettings),
	PurchaseIds = {},
}

return {
	VERSION = VERSION,
	Template = Template,
}
