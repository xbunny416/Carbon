--!strict
-- Developer tools. A developer panel / command service (add one per game) must re-check every command on the
-- server: allowed in Studio playtests when AllowInStudio, in live servers only for AllowedUserIds.
return {
	-- Roblox UserIds allowed to use developer tools in live servers.
	AllowedUserIds = {} :: { number },
	-- Anyone may use them inside Roblox Studio playtests (never in live servers).
	AllowInStudio = true,
	-- Print every input action and device change to Output in Studio.
	LogInput = false,
}
