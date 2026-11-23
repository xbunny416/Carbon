--!strict
-- Character movement, players per server and the desert map.
return {
	WalkSpeed = 16,
	JumpHeight = 7.2,
	MaxPlayers = 12, -- set the same value in Game Settings > Places
	-- The desert map (maps/layouts/Desert.luau is built from these, bible §5.1): a square Size studs wide with its
	-- ground top at Origin — 1 stud up, so a Baseplate left in the place from Studio's template (top at Y = 0) is
	-- buried inside the ground instead of flickering with it. The open sand center (within CenterHalfSize of the
	-- middle) holds the player spawn pads and nothing else; each zone is the ring from the previous edge out to
	-- MaxDistance (distance = max(|x|, |z|) from the center).
	Map = {
		Origin = { 0, 1, 0 },
		Size = 2048,
		CenterHalfSize = 60,
		Zones = {
			{ Id = "Scrublands", MaxDistance = 500 },
			{ Id = "MesaFlats", MaxDistance = 800 },
			{ Id = "Badlands", MaxDistance = 1024 },
		},
	},
}
