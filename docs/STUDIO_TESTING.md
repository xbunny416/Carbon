# Studio testing notes

How to test each system in Studio, debug switches, playtest history and known limits. Add a section with every
feature; after each playtest, a dated line with the owner's notes and what was fixed.

## First run

1. `rojo serve`, open a new place (Baseplate), Rojo plugin → **Connect**. `Workspace.Desert`, `Workspace.Town` and
   `ReplicatedStorage.Assets` appear. The Baseplate's own `Baseplate` and `SpawnLocation` can go (Output reminds you):
   they're buried under the desert ground and turned off, so they do no harm. If an old `Workspace.Lobby` is still in
   the place (from before 2026-11-19), delete it too.
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

## Starter car (1.2)

- Play: your Rusty Pickup waits in a motel bay. Walk to its driver's door (your left as you face the motel from the
  car's front): the **Drive** prompt (E / B / tap). Other players don't see a prompt on your car.
- Drive with W A S D / arrows (gamepad: RT gas, LT brake, left stick; phone: thumbstick). Check: it goes forward on
  W, turns the right way, brakes then reverses on S, rolls to a stop when you let go, no bouncing, no rolling over in
  normal turns. Space does nothing while driving. Try a ramp in the desert.
- **E / B / Get out button**: you land beside the driver's door and the prompt comes back.
- Roll it over on a ramp: when it stops, the Flip hint (R / Y) or the Flip button shows; after 1 s it's back on its
  wheels. Also works standing next to it.
- Menu → **Car** → **Reset car**: a new car in a free bay with you in it; pressing again within 10 s shows a wait
  notice.
- Two players (Test → 2 players): each gets their own car in a different bay and can't drive the other's.
- Tuning (all in `Config.Cars`): if **W drives backwards**, flip the sign in `CarRules.wheelSpin`; if it **steers
  the wrong way**, flip the sign in `CarRules.steerAngle`. Too bouncy → raise `DampingRatio`; sits too low → lower
  `Sag`; rolls over in turns → lower `SteerAngleAtTopSpeed`; too slow off the line → raise `Acceleration`.

## Flicker fix (2026-11-19)

- The ground is 1 stud higher than before. Look at the ground, the dirt roads (tire tracks), the town streets and
  lots, the oil stains and the edge cliffs from near and far: nothing should flicker or shimmer, with or without the
  old Baseplate in the place. Cars still spawn in the motel bays and sit on the lot.
- If something still flickers, say where (or send a screenshot): `tests/specs/maps.spec.luau` checks every map top
  surface, so it's something it doesn't cover yet (a side face or a round part).

## Playtests

- *(none yet)*
