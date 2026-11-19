--!strict
-- Uploaded animations: clip name → Roblox animation asset id (0 = none yet). `lune run assets/build` makes one
-- Animation per id in ReplicatedStorage.Assets.Animations; load those onto Humanoid.Animator.
-- The roblox-animation skill (.claude/skills) makes animations in Studio through the Studio MCP.
return {
	AssetIds = {} :: { [string]: number },
}
