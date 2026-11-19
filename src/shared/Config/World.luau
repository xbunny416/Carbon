--!strict
-- Character movement, players per server and the loading screen.
return {
	WalkSpeed = 16,
	JumpHeight = 7.2,
	MaxPlayers = 12, -- set the same value in Game Settings > Places
	-- The loading screen (ReplicatedFirst): shown at least MinTime seconds and until the game and your data have
	-- loaded (at most MaxTime), then fades out over FadeTime; it shows one of TipCount tips ("Tip.<n>" strings).
	Loading = { MinTime = 1.5, MaxTime = 20, FadeTime = 0.6, TipCount = 3 },
	-- Where the lobby's floor centre is in the world (maps/layouts/Lobby.luau is built around it).
	LobbyOrigin = { 0, 100, 0 },
}
