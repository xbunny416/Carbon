# Studio testing notes

How to test each system in Studio, debug switches, playtest history and known limits. Add a section with every
feature; after each playtest, a dated line with the owner's notes and what was fixed.

## First run

1. `rojo serve`, open a new place (Baseplate), Rojo plugin → **Connect**. `Workspace.Desert` and
   `ReplicatedStorage.Assets` appear. The Baseplate's own `Baseplate` and `SpawnLocation` can go (Output reminds you):
   they're buried under the desert ground and turned off, so they do no harm. Delete any old `Workspace.Town` or
   `Workspace.Lobby` left in the place (Rojo doesn't remove them).
2. **Save the place** once (keeps the TextChatService and lighting switches).
3. File → Publish to Roblox, then Game Settings → Security → **Allow Studio Access to API Services** (saving).
4. Play: no loading screen (not even Roblox's): you spawn on a sand pad in the open center. Output
   should have no red errors. If data can't load (place not published, or API access off) you are kicked with "Your
   progress could not be loaded": publish + enable API access, or set `Config.Data.UseMockInStudio = true`.

## Base systems

- **Input:** press M / D-pad Up (Menu). With `Config.Dev.LogInput = true`, Output prints each action and device.
- **Saving:** change a setting (once a Settings screen exists), leave, rejoin: it stays (not with
  `UseMockInStudio`, which forgets everything when the test ends).
- **Notices:** the server's `Notify` remote shows a short message at the top (e.g. `Data.LoadFailed`).
- **Two players:** Test → Clients and Servers → 2 players.

## Desert map

- Restart `rojo serve` after map files are added or removed. If the sky looks plain, check `Lighting` has
  `Atmosphere`, `ColorCorrection` and `SunRays` and `ClockTime` 14.5; set them by hand if Rojo didn't.
- The center is open sand: two dirt roads cross in the middle, 4 spawn pads between them, no buildings or walls.
- Fly the Studio camera out: roads with poles, ring road, mesas, blocky cacti, cliffs on every edge — no signs and
  no ramps; you can't leave the map. Nothing should flicker
  (`maps.spec` checks every top surface).

## Car

- On foot, the **Spawn car** button (bottom; C / D-pad Down) puts your Rusty Pickup on open ground beside you. Next
  to a mesa or another car it tries another side; with no room at all you get "No room for your car here". Pressing
  again within 15 s shows a wait notice; a new spawn replaces your old car.
- Walk to the driver's door (the car's left): the **Drive** prompt (E / B / tap). Other players don't see it.
- Drive with W A S D / arrows (gamepad: RT gas, LT brake, left stick; phone: thumbstick): forward on W, turns the
  right way, tight turns at low speed work, brakes then reverses on S, rolls to a stop when you let go. Space does
  nothing while driving. **E / B / Get out** puts you beside the driver's door.
- Roll it over on a mesa slope: when it stops, the Flip hint (R / Y) or Flip button shows; after 1 s it's on its wheels.
- Two players: each spawns their own car and can't drive the other's.
- Feel (2026-11-23): the car should hold its line (no sideways sliding), turn crisply at any speed, stay planted
  at top speed, and land level after a jump.
- Tuning (all in `Config.Cars.Models.RustyPickup`): slides → raise `Grip` or `RearTireFriction`; turns too sharp /
  spins out → lower `TurnBoost`, `TurnResponse` or `SteerAngle`; turns too slowly → raise `TurnBoost` /
  `TurnLimit` or lower `RearTireFriction`; flips in turns → raise
  `Downforce` or lower `SteerAngleAtTopSpeed`; floaty in jumps → raise `AirLevel` (0 turns it off); too bouncy →
  raise `DampingRatio`; slow off the line → raise `Acceleration`.

## Fuel and oil

- Drive: the FUEL bar shows at the bottom and drains as you drive (~2,500 studs on a full tank). Below a fifth it
  turns red and a "Low fuel" notice shows once.
- Oil barrels float, bob and turn above the sand with a warm glow — rare (up to 18 on the whole map, a new one every
  8 s), at random places, never in the center or by the cliffs, never in rocks. Drive through one: "+30 fuel" and the
  bar jumps. With a full tank you pass through and it stays. An untouched barrel moves elsewhere after 4 minutes.
- Run dry: "Out of fuel" notice, the car rolls to a stop and won't drive. Getting oil into it starts it again; or
  Spawn car (new car with your old fuel, at least 25).
- Quick tests: `Config.Fuel.BurnPerStud` = 1 (empty in 100 studs); `Config.Oil.SpawnEvery` = 1 and
  `MaxBarrels` = 60 to find barrels fast. Put them back after.

## Playtests

- **2026-11-19 (owner):** 1. front of the car glitches (flickers), 2. hard to turn and sometimes stuck, 3. cab a
  bit small. Fixed: 1. the windshield glass overlapped the pillars' slopes and the headlights overlapped the grille —
  now side by side (a cars spec checks wedges); 2. all four wheels were forced to the same speed and fought every
  turn — now each wheel gets its own speed for the turn, steering 40° (18° at top speed), more motor push;
  3. cab wider, longer and 4 studs of headroom (roof 8.2). **Re-check:** tight turns at low speed, U-turn on a dirt
  road, climbing curbs, no flicker at the windshield and lights, your avatar's head clears the roof.
- **2026-11-23 (owner):** delete the town (motel, gas station etc.), spawn the car with a UI button, no coin system,
  oil rare, random and floating instead of on the fixed oil-spot circles. Done in one PR (see DECISIONS). **Check:**
  spawn pads in the center, Spawn car beside you, barrels floating and refuelling.
- **2026-11-23 (owner):** "fix, improve, polish car" → driving feel + looks. Added grip, downforce, turn assist and
  air levelling; detail pass on the pickup. **Check:** no sliding in turns, crisp steering, stable at top speed,
  level landings; the new details look right and nothing flickers (grille, lights, wheels, roof).
- **2026-11-23 (owner):** the black CAROFF loading screen still showed after it was deleted — the old script stayed
  in the place because Rojo no longer managed `ReplicatedFirst`. Now Rojo manages it again (unknown children
  removed) and its only script hides Roblox's default loading screen. **Check:** reconnect Rojo, `ReplicatedFirst`
  holds just `LoadingScreen` (the small one), Play shows no loading screen. Republish if testing the live game.
- **2026-11-23 (owner):** 1. car too hard to turn, 2. remodel it a bit longer with the front end lifted (it looked
  flat), 3. delete all signs and ramps. Done: 1. rear tires grip less than the front (turn in), front wheels 45° /
  26° and faster, turn assist much stronger (response 10, limit 18) aiming 1.35× tighter; 2. wheelbase 11.4 (~2
  studs longer), raised hood with a beveled nose, tall grille, high headlights, higher cab belt line; 3. zone
  signposts and jump ramps removed. **Check:** tight U-turns at low speed and sharp turns at speed without spinning
  out; the new long, tall-nosed pickup looks right; spawning it still finds room.
