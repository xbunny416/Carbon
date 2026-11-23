--!strict
--[[
	No loading screen at all (owner, 2026-11-23). This only hides Roblox's own default loading screen the moment the
	game starts; nothing else is shown — the game appears as it loads in. It runs from ReplicatedFirst, before
	anything else. (Same name as the old custom loading screen on purpose: Rojo overwrites that script in the place
	instead of leaving it behind.)
]]
local ReplicatedFirst = game:GetService("ReplicatedFirst")

ReplicatedFirst:RemoveDefaultLoadingScreen()
