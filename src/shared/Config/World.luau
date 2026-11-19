--!strict
-- Character movement, players per server and the loading screen.
return {
	WalkSpeed = 16,
	JumpHeight = 7.2,
	MaxPlayers = 12, -- set the same value in Game Settings > Places
	-- The loading screen (ReplicatedFirst): shown at least MinTime seconds and until the game and your data have
	-- loaded (at most MaxTime), then fades out over FadeTime; it shows one of TipCount tips ("Tip.<n>" strings).
	Loading = { MinTime = 1.5, MaxTime = 20, FadeTime = 0.6, TipCount = 3 },
	-- The desert map (maps/layouts/Desert.luau and Town.luau are built from these, bible §5.1): a square Size studs
	-- wide with its ground top at Origin — 1 stud up, so a Baseplate left in the place from Studio's template (top at
	-- Y = 0) is buried inside the ground instead of flickering with it. The town (the safe zone) is the square within TownHalfSize of the center;
	-- each zone is the ring from the previous edge out to MaxDistance (distance = max(|x|, |z|) from the center),
	-- with OilSpots oil spots at least OilSpotSpacing studs apart.
	Map = {
		Origin = { 0, 1, 0 },
		Size = 2048,
		TownHalfSize = 200,
		Zones = {
			{ Id = "Scrublands", MaxDistance = 500, OilSpots = 40 },
			{ Id = "MesaFlats", MaxDistance = 800, OilSpots = 30 },
			{ Id = "Badlands", MaxDistance = 1024, OilSpots = 24 },
		},
		OilSpotSpacing = 60,
		CarSpawns = 12, -- one per player (MaxPlayers)
		PumpBays = 6,
	},
}
