--!strict
--[[
	Every sound is a slot holding a Roblox audio asset id (0 = silent until one is picked from the Creator Store:
	Studio → Toolbox → Audio → right-click → Copy Asset ID). After changing ids run `lune run assets/build`, which
	makes ReplicatedStorage.Assets.Sounds (one Sound per slot with an id). Clone them, never create empty Sounds.
]]
export type Slot = { Id: number, Volume: number }

type AudioConfig = {
	Music: { [string]: Slot },
	Sfx: { [string]: Slot },
	-- Sound effects play at a random PlaybackSpeed in this range so repeats don't sound identical.
	Pitch: { Min: number, Max: number },
}

local Audio: AudioConfig = {
	Music = {
		Lobby = { Id = 0, Volume = 0.4 },
	},
	Sfx = {
		Click = { Id = 0, Volume = 0.5 },
		OilPickup = { Id = 0, Volume = 0.6 },
		LevelUp = { Id = 0, Volume = 0.7 },
	},
	Pitch = { Min = 0.9, Max = 1.1 },
}

return Audio
