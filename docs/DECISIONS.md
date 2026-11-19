# Decisions and interpretations

In the order they were made; a later entry overrides an earlier one. Add new decisions at the end, with the date and
whether the owner chose it or Claude chose it where the bible is silent. Read the matching entry before changing how
a system behaves.

## Carried over from the template (2026-11-19)

These came with the base systems; each is a default the owner can change.

- **Coins** is the soft currency name on screen and in data (`data.Coins`, `DataService.addCoins/spendCoins`).
- **Saving:** ProfileStore (vendored; session-locked, autosaved, reconciled with the template). Store name and key
  prefix in `Config.Data`. Robux receipts are granted once per PurchaseId (last 100 kept per player).
- **Remotes:** every client → server remote validates its arguments (`Net/Guard`) and is rate-limited per player
  (`Config.Net`); a player over the limit is ignored, not kicked.
- **Settings:** music volume, sound volume, camera shake, low graphics, button layout; each change is checked on the
  server (`Shared/Settings`) before it is saved.
- **Input:** three actions to start (Action, Interact, Menu) with keyboard, gamepad and touch bindings; the touch
  buttons sit in an arc around Roblox's jump button and are at least 64 px on every tested screen.
- **Camera:** zoom 8–30 studs; Shift Lock allowed on Left/Right Shift (`Config.Controls.Camera`). The server sets
  `StarterPlayer.EnableMouseLockOption` (a LocalScript can't set `DevEnableMouseLock`).
- **Lighting:** `LightingStyle = Realistic` + `GlobalShadows` in `default.project.json` (Roblox replaced
  `Lighting.Technology`). Streaming on (min radius 128, target 256).
- **Chat:** TextChatService (`ChatVersion` set in the project; save the place once after Rojo syncs it).
- **Loading screen:** `src/first/LoadingScreen.client.luau` replaces Roblox's default, shows the title and a random
  tip (`Tip.1..TipCount`), and fades out once the game is loaded (min / max time in `Config.World.Loading`).
- **Paid random items, likes, private servers, Studio-only dev tools:** see "Standing owner decisions" in CLAUDE.md.

## Starter lobby removed (2026-11-19, owner)

- The owner asked to remove the template's floating lobby (a 60×60 walled room with spawn pads at `Y = 100`). Gone:
  `maps/layouts/Lobby.luau`, `maps/generated/Lobby.rbxmx`, the `Workspace.Lobby` entry in `default.project.json`,
  `Config.World.LobbyOrigin` and the lobby spec. Kept: `maps/build.luau`, `maps/lib/` (Builder, Palette) for the
  game's real maps, and the `Music.Lobby` audio slot (silent, id 0) as the default music slot.
- Until a map exists, players spawn on the Studio Baseplate (Claude's call).

## Kickoff (2026-11-19)

Owner's answers:

- **Name:** CarOff (repo stays `Carbon`). **Genre:** car extraction — cars roam and compete to scavenge items, only
  oil for now.
- **Map:** one huge square in two parts — the spawn town (motel + gas station) **in the middle**, the desert arena all
  around it. Desert countryside, **sunny Route 66** look.
- **Session:** open roam, no rounds. **PvP:** ram to wreck; a wreck spills its oil. **Oil:** fuel *and* money.
- **Players:** 12 per server. **Cars:** buy cars + upgrade each. **Robux:** decide later (ask before Phase 3).
- Approved the build order in bible §8.

Claude's calls (all *(tune)* in the bible, change freely):

- Map 2048 × 2048 studs (the largest single Part) on the ground at Y = 0; town 400 × 400; zone rings at 200 / 500 / 800
  with 1 / 2 / 3 barrels per spot, so going farther fills cargo faster but costs fuel and time.
- Fuel tank separate from cargo: 1 fuel per 25 studs, Boost 3×; an empty tank auto-burns a cargo barrel (+25);
  empty with no cargo = stall + Tow home. Refill, repair and selling all happen at the gas station pump bays (one
  place to remember), free.
- 25 Coins + 15 XP per barrel; 25 XP for the last hit on a wreck. Crash damage (speed − 20) × 1.5, rammer takes 30%.
- Driving on Roblox's VehicleSeat controls (works on every device); jump off while driving; `Action` → `Boost`
  (Shift / X), new `Flip` (R / Y). Driver's client owns car physics, the server owns fuel, cargo, health and money.
- Five cars (Rusty Pickup, Dune Buggy, Ranch Hauler, Desert Muscle, Armored Rig) with level gates 1 / 3 / 5 / 8 / 12;
  upgrades Engine / Tank / Cargo / Armor, 5 levels, cost `floor(UpgradeBase × 1.6^(n−1))`.
- UI accent stays sunset orange `#FF7A1A` (fits the desert). Streaming radius raised for driving speeds in 1.1.

## 1.1 Desert map (2026-11-19, Claude's calls)

- Two generated files: `Workspace.Desert` (ground, roads, props, cliffs, oil spots) and `Workspace.Town`, so a town
  change doesn't rewrite the big desert file. Both come from `Config.World.Map` (size, town size, zones, spot counts).
- Town corners (Builder +X / +Z = "north-east"): motel + 12 car bays and the pool; gas station + 6 pump bays; garage
  (ready for the Phase 2 garage shop); a trailer yard. The water tower in the roundabout is a landmark you can see from
  the desert and climb (a truss ladder).
- Cars spawn in bays facing the street (out of the lot); players spawn on the motel's welcome mats until cars exist.
- The safe zone is the town square (`TownHalfSize`), not a marker part — the server can check it with plain math.
- Edge cliffs take ~125 studs, so the drivable Badlands band is 800–900; oil spots stay 15 studs inside each zone
  ring and 24 studs off road centers, at least 60 apart.
- The ground is one Persistent model (never streams out under a fast car); mesas and cliffs use
  `LevelOfDetail = StreamingMesh` so the horizon isn't empty.
- Lighting: late afternoon (`ClockTime` 16.6), haze `Atmosphere`, warm `ColorCorrection`, light `SunRays`
  (`default.project.json`). Streaming min 256 / target 1024.
- Map randomness comes from a seeded generator (`maps/lib/Rng.luau`, seeds in the layouts): change the seed for a
  different scatter.

## 1.2 Starter car (2026-11-19, Claude's calls)

- Physics car, not a scripted one: VehicleSeat for the inputs (Roblox's own vehicle controls work on keyboard,
  gamepad and touch with no extra code) and constraints for the wheels — sliding struts with springs, a motor hinge
  on every wheel (4-wheel drive is the most stable on sand and ramps), servo steering on the front ones. The body is
  massless and welded to a dense chassis, so the weight sits low and the pickup doesn't roll over easily.
- The driver's client runs the motors (it owns the car while driving, so there's no input lag); the server sets
  spring and motor strengths from the car's mass and owns a parked car. Server-side speed checks come with the
  hardening work (Known limits).
- Only the owner can drive their car; nobody else sees its prompt. No passengers yet.
- Getting out puts you on the driver's (left) side. Jumping is off while driving.
- The template's `Action` (left click / X) is gone: nothing in CarOff used it. Flip is R / Y; Boost comes in 1.6.
- Flip works from the seat or standing within 30 studs, only when the car is upside down and stopped, after 1 s.
- Reset car lives on a Car menu screen (the first menu button), every 10 s at most, and puts you straight into the
  new car. Cars stay where they are when you die; leaving the game removes your car.

## Flickering ground fix (2026-11-19, owner asked "fix glitch platform")

- Cause: the desert ground's top was at Y = 0, the same height as the Baseplate Studio puts in a new place, so the
  two fought (z-fighting) everywhere; tire tracks sat 0.05 studs on the roads and oil stains 0.05 on the sand, which
  flickers from a distance; a few cliff tops and town trims happened to be level with a neighbour.
- Fix (Claude's calls): the whole map is 1 stud up (`Config.World.Map.Origin`), so a leftover Baseplate is buried;
  any SpawnLocation outside `Workspace.Town` is turned off at runtime (MapService). Road tracks are strips laid
  beside the road strips (flat for cars), every overlay is at least 0.1–0.2 studs above what it covers, neighbouring
  cliffs get height offsets 0.25+ apart. A map spec fails if two differently colored top surfaces overlap within
  0.06 studs.

## Look: blocky-parts style (2026-11-19, owner)

- The owner added the `roblox-blocky-parts-style` skill and chose it as CarOff's look (replacing the "detailed,
  non-blocky" bright Route 66 look), asking to redo the town and the car.
- Done (Claude's calls on how): the palette keeps its color names with the skill's muted values (so the desert
  follows too); the town buildings were rebuilt with the same footprints (bays, pumps and spawns unchanged): brick
  bases, framed windows with ledges, gable roofs on the office, garage and trailers, a beveled motel fascia, a solid
  half-wall balcony railing, a wedge awning; neon tubes, hoses, door knobs and similar tiny bits removed. Props
  (saguaros, barrel cacti, bushes, poles, street lights, old cars, signposts) became blocks. Sign text uses the plain
  Oswald font. The Rusty Pickup follows the skill's vehicle recipe (≈50 body parts). Lighting: soft hazy daylight,
  `ClockTime` 14.5, light blue-grey Atmosphere, slightly desaturated.
- Kept on purpose: cylinders for wheels, tanks, the water tower and drums (the skill allows cylinders); the lit
  MOTEL / VACANCY text and real lamps (deliberate lights). `LightingStyle = Realistic` stays (Roblox replaced the
  skill's `Lighting.Technology`). Mesas and cliffs were already blocky and only changed color.

## 1.3 Fuel (2026-11-19, Claude's calls)

- The server measures the burn from the chassis position every 0.1 s while the owner sits in the driver seat
  (sideways distance only, capped at 120 studs/s), so clients can't fake a full tank. The tank is the car's `Fuel`
  attribute.
- Refill needs the car (almost) stopped within 7 studs of a `PumpBay` marker; it's free and works with or without
  the driver in the seat. Selling (1.5) will use the same bays.
- Stalling hands the car's physics to the server (its motors switch to coasting), so a client can't keep driving
  on an empty tank. Tow home has no cooldown (unlike Reset car) and only works for a stalled car.
- The low-fuel line is 20 % of the tank; the empty-tank barrel rule reads a `Cargo` attribute that 1.4 will fill.
