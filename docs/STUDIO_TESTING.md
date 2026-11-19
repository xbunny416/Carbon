# Studio testing notes

How to test each system in Studio, debug switches, playtest history and known limits. Add a section with every
feature; after each playtest, a dated line with the owner's notes and what was fixed.

## First run

1. `rojo serve`, open a new place (Baseplate), Rojo plugin → **Connect**. `Workspace.Desert`, `Workspace.Town` and
   `ReplicatedStorage.Assets` appear. **Delete the Baseplate's own `Baseplate` and `SpawnLocation`** (the Baseplate
   flickers with the desert ground at the same height, and its spawn sits in the roundabout). If an old
   `Workspace.Lobby` is still in the place (from before 2026-11-19), delete it too.
2. **Save the place** once (keeps the TextChatService and lighting switches).
3. File → Publish to Roblox, then Game Settings → Security → **Allow Studio Access to API Services** (saving).
4. Play: the loading screen shows the title and a tip, then fades; you spawn on a pink mat in front of the motel. Output should have no
   red errors. If data can't load (place not published, or API access off) you are kicked with "Your progress could not
   be loaded": publish + enable API access, or set `Config.Data.UseMockInStudio = true` to play without saving.

## Base systems

- **Input:** press M / D-pad Up (Menu). With `Config.Dev.LogInput = true`, Output prints each action and device.
  Touch: Test → Device emulator (phone): the Action button sits left of the jump button.
- **Saving:** change a setting (once a Settings screen exists), leave, rejoin: it stays (not with
  `UseMockInStudio`, which forgets everything when the test ends).
- **Notices:** the server's `Notify` remote shows a short message at the top (e.g. `Data.LoadFailed`).
- **Two players:** Test → Clients and Servers → 2 players.

## Desert map (1.1)

- Restart `rojo serve` once (two new map files). If the sky looks plain, check `Lighting` has `Atmosphere`,
  `ColorCorrection` and `SunRays` and `ClockTime` 16.6; set them by hand if Rojo didn't.
- Edit mode: teal pads are the markers — 12 `CarSpawn` in the motel lot, 6 `PumpBay` under the gas canopy,
  94 `OilSpot` on dark stains in the desert. Press Play: they disappear (MapService).
- Walk around town: motel (office door and shop door are walk-through glass), pool, neon MOTEL sign, gas station,
  garage, trailers, windmill; climb the water tower ladder. Gate signs: SAFE ZONE from outside, LEAVING SAFE ZONE
  from inside.
- Fly the Studio camera out: roads with poles and zone signposts (SCRUBLANDS / MESA FLATS / BADLANDS), ring road,
  mesas, ramps, cliffs on every edge; you can't leave the map. Look for floating or sunk props.

## Playtests

- *(none yet)*
