--!strict
--[[
	Every remote in the game. The server creates them at startup; clients wait for them.
	ToServer remotes must list Args (validated on the server before any handler runs) and may override the default
	rate limit from Config.Net. Add new remotes here together with the feature that uses them.
]]
local Config = require(script.Parent.Parent.Config)
local Guard = require(script.Parent.Guard)

export type Kind = "Event" | "UnreliableEvent" | "Function"
export type Direction = "ToServer" | "ToClient"

export type Definition = {
	Kind: Kind,
	Direction: Direction,
	Args: { Guard.Check }?,
	RateLimit: { Rate: number, Burst: number }?,
}

local Definitions: { [string]: Definition } = {
	-- Server -> client: show a localized notice (NoticeController). (key: string, args: { any }? — an arg that is a
	-- table { Key = string } is a GameStrings key the client localizes, e.g. an item name)
	Notify = { Kind = "Event", Direction = "ToClient" },
	-- Server -> client: the player's full saved data once it loads. (data: PlayerData)
	DataSync = { Kind = "Event", Direction = "ToClient" },
	-- Server -> client: one top-level field of the player's data changed. (key: string, value: any)
	DataChanged = { Kind = "Event", Direction = "ToClient" },

	-- Client -> server: change one Settings-menu value. (key: string, value: boolean | number | string)
	-- Shared/Settings checks the value for that key before it is saved.
	ChangeSetting = {
		Kind = "Event",
		Direction = "ToServer",
		Args = {
			Guard.keyOf(Config.Data.DefaultSettings),
			Guard.anyOf(Guard.boolean, Guard.number, Guard.string(32)),
		},
	},

	-- Client -> server: get out of the car you're driving. ()
	ExitCar = { Kind = "Event", Direction = "ToServer", Args = {}, RateLimit = { Rate = 2, Burst = 3 } },
	-- Client -> server: turn your upside-down car back over (it must have stopped; you drive it or stand by it). ()
	FlipCar = { Kind = "Event", Direction = "ToServer", Args = {}, RateLimit = { Rate = 1, Burst = 2 } },
	-- Client -> server: send your car back to town, in a free bay, with you in it (Config.Cars.ResetCooldown). ()
	ResetCar = { Kind = "Event", Direction = "ToServer", Args = {}, RateLimit = { Rate = 0.5, Burst = 2 } },
	-- Client -> server: your car is out of fuel; send it (with you) back to a free bay in town, tank full. ()
	TowCar = { Kind = "Event", Direction = "ToServer", Args = {}, RateLimit = { Rate = 0.5, Burst = 2 } },
}

return Definitions
