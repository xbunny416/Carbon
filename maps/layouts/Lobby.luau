--!strict
--[[
	The starter lobby: a floor, walls, a title sign and spawn pads. Replace it with the game's real lobby.
	Directions: the Builder's North = +Z, East = +X. That is a mirror image of a compass (facing +Z, +X is on your
	*left*), so describe places to the owner as left / right as you face +Z, never east / west.
	Walls: BackWall (+Z, the title sign), FrontWall (−Z, behind the spawns), LeftWall (+X), RightWall (−X).
]]
local B = require("../lib/Builder")

local Layout = {}

Layout.Id = "Lobby"

local SIZE = { 60, 60 } -- X, Z
local HEIGHT = 20
local WALL = 2

function Layout.build(origin: { number }): any
	local halfX, halfZ = SIZE[1] / 2, SIZE[2] / 2
	return B.root("Lobby", function()
		B.within(origin, function()
			B.slab({
				Name = "Floor",
				Size = { SIZE[1] + WALL * 2, 2, SIZE[2] + WALL * 2 },
				Position = { 0, 0, 0 },
				Color = "Concrete",
				Material = "Concrete",
			})
			for _, wall in
				{
					{
						Name = "BackWall",
						Size = { SIZE[1] + WALL * 2, HEIGHT, WALL },
						Position = { 0, HEIGHT / 2, halfZ + WALL / 2 },
					},
					{
						Name = "FrontWall",
						Size = { SIZE[1] + WALL * 2, HEIGHT, WALL },
						Position = { 0, HEIGHT / 2, -halfZ - WALL / 2 },
					},
					{
						Name = "LeftWall",
						Size = { WALL, HEIGHT, SIZE[2] },
						Position = { halfX + WALL / 2, HEIGHT / 2, 0 },
					},
					{
						Name = "RightWall",
						Size = { WALL, HEIGHT, SIZE[2] },
						Position = { -halfX - WALL / 2, HEIGHT / 2, 0 },
					},
				}
			do
				B.part({
					Name = wall.Name,
					Size = wall.Size,
					Position = wall.Position,
					Color = "OffWhite",
					Material = "Plaster",
					CastShadow = true,
				})
			end
			B.sign({
				Name = "TitleSign",
				Size = { 24, 5, 0.5 },
				Position = { 0, 12, halfZ - 0.3 },
				Color = "Black",
				Material = "SmoothPlastic",
				Key = "Game.Title",
				TextColor = "NeonTeal",
				Glow = true,
			})
			for index, x in { -8, 0, 8 } do
				B.spawnLocation({
					Name = `LobbySpawn{index}`,
					Size = { 6, 1, 6 },
					Position = { x, 0.5, -halfZ + 10 },
					Rotation = B.yaw("North"),
					Color = "Teal",
					Material = "SmoothPlastic",
					Tags = { "LobbySpawn" },
				})
			end
		end)
	end, { MapId = Layout.Id })
end

return Layout
