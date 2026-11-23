# CarOff — project bible

The design spec. Written in the kickoff (2026-11-19) from the owner's answers and reshaped by the owner on
2026-11-23 (no town, no coins, oil is fuel only, car spawn button). Every number here is a value in
`src/shared/Config` (keep both in sync). Numbers marked *(tune)* are Claude's first guesses — change them after
playtests. Sections with *TBD* are still open — ask before building them.

## 1. Pitch

- **One line:** Spawn your car in the middle of a huge desert, hunt the rare floating oil barrels that keep your tank
  alive, and ram rival cars out of the way before you run dry.
- **Genre:** car survival / scavenging in an open desert. Oil is the only fuel; there is no money.
- **Players per server:** 12 (`Config.World.MaxPlayers`), all PvP, everyone in the same open map.
- **Session shape:** open roam, no rounds or timer; new players join and drive at once.
- **Platforms:** PC, phone, tablet, console (every control on keyboard/mouse, touch and gamepad).

## 2. Core loop

- **First 10 seconds:** spawn on a sand pad in the open center, press **Spawn car**, hop in, drive out.
- **Minute to minute:** drive the desert → spot a glowing barrel floating over the sand → drive through it for fuel
  → watch the fuel gauge, because driving burns it → beat other cars to the next barrel, or ram them.
- **The tension:** barrels are rare and appear at random places, so you have to keep moving and choose: chase a far
  barrel on a low tank, or stay near where they tend to be found. Running dry stalls your car; spawning it again
  gives only a little fuel and has a cooldown.
- **Long term:** *TBD* (owner, 2026-11-23: no coins; progression to be decided).

## 3. Look and feel

- **Art direction (owner, 2026-11-19): the blocky-parts style** — skill `.claude/skills/roblox-blocky-parts-style`.
  Real objects simplified into boxes, wedges and a few cylinders: readable silhouettes, wedge bevels, medium detail,
  muted earthy colors, built-in materials (Sand, Ground, Sandstone, WoodPlanks, LeafyGrass), Neon only on real
  lights. Soft hazy daylight (`ClockTime` 14.5, a light blue-grey Atmosphere). Subject: open Route 66 desert — sand,
  mesas, sage, blocky cacti, dirt roads with poles, edge cliffs. Maps and cars are built in code (`maps/layouts`,
  `assets/`). No reference pictures yet.
- **Map palette:** `maps/lib/Palette.luau` — the muted palette from the skill.
- **UI:** dark slate `#1E1E24` + the sunset orange accent `#FF7A1A` (`Ui/Kit.Colors`).
- **Audio:** free Creator Store only (`Config/Audio.luau`): desert-rock music, engine loop, boost, crash, wreck,
  oil pickup (`OilPickup` slot).

## 4. Controls

Driving uses Roblox's own vehicle controls (VehicleSeat), so it works on every device. Jumping is off while driving
(it would throw you out of the seat).

| Action | Keyboard / mouse | Gamepad | Touch |
| --- | --- | --- | --- |
| Drive / steer | W A S D or arrows | Left stick, RT gas, LT brake | Thumbstick |
| Spawn car (on foot) | C | D-pad Down | Spawn car button (bottom) |
| Enter / exit car | E | B | Prompt / Get out button |
| Flip car (when upside down) | R | Y | Flip button (shows only when flipped) |
| Boost (hold, from 1.5) | Left Shift | X | Big button by the jump button |
| Menu | M | D-pad Up | Menu button |

`Config.Controls`. On touch, Get out shows only while you drive and Flip only while your stopped car is upside down.

## 5. Systems

### 5.1 Map (`maps/layouts/Desert.luau`)

- One huge square, **2048 × 2048 studs**, ground top at Y = 1 (`Config.World.Map.Origin = {0, 1, 0}`, so a leftover
  Studio Baseplate hides under it). **No town** (owner, 2026-11-23): the middle is open sand.
- **Center** (`CenterHalfSize` 60): plain sand where two dirt roads cross; 4 spawn pads between the roads; nothing
  else stands there.
- **Zones** by distance from the center (square rings, `max(|x|, |z|)`), each its own sand color with zone signposts
  on the roads: Scrublands 60–500, Mesa Flats 500–800, Badlands 800–1024 (cliffs take the last ~125 studs).
- **Desert:** the two crossing dirt roads out to the cliffs with telephone poles, a ring road at 500, mesas,
  boulders, saguaros, bushes, dead trees and wooden jump ramps by the roads.
- **Edge:** a ring of tall cliffs plus an invisible wall so no car leaves the map.
- Streaming: min radius 256, target 1024 *(tune in the performance pass)*; the ground is Persistent, mesas and
  cliffs show as low-detail meshes when far away.

### 5.2 Cars

- Built in code (`assets/cars/` → `ReplicatedStorage.Assets.Models.Cars`): a heavy chassis with the massless body
  welded on, a VehicleSeat, 4 wheels on sliding struts with springs, motor hinges on all 4 wheels (4-wheel drive) and
  servo steering on the front two. The driver's client owns the car's physics and runs the motors; the server owns
  fuel and health, and owns a parked car (its motors hold it like a parking brake).
- Driving (`Config.Cars.Models.RustyPickup`): top speed 60, reverse 22, acceleration 28, braking 60, coasting 6
  (studs/s²); front wheels turn 40° standing still, 18° at top speed; springs sag 0.5 studs, damping ratio 0.55.
  Spring and motor strengths come from the car's mass (`Shared/CarRules`; motor torque ×2.2). In a turn each wheel
  spins at its own speed, inner ones slower (`CarRules.wheelFactor`, like a differential).
- **Arcade helpers** (2026-11-23, run by the driver's client through the car's `Assist` force and `TurnAssist`
  torque): on the ground, **grip** cancels sideways sliding (rate 6/s, at most 1.2 g), **downforce** presses the car
  down (0.6 studs/s² per stud/s), **turn assist** brings the car to the turn rate its steering asks for (bicycle
  model, response 5/s, at most 6 rad/s²); in the air it **levels itself** gently (6/s²). All per car in
  `Config.Cars.Models`.
- **Look (Rusty Pickup):** muted sage two-tone pickup — chrome grille with bars, headlight bezels and turn signals,
  bumper guard, fender flares, rocker stripe, door handles, mirrors on arms, a raised beveled roof panel, rims and
  hubcaps, mud flaps, tailgate panel and handle, tow hitch, a spare tire and a toolbox in the bed.
- **Spawn car** (owner, 2026-11-23): there is no automatic car. On foot, the Spawn car button (C / D-pad Down) puts
  your car on clear flat ground beside you (right, left, front or back), facing your way, replacing your old one.
  Once every 15 s. The first car has a full tank; a car spawned again keeps the old car's fuel but at least 25 — a
  way out when stranded, not a free refill. Leaving the game removes your car.
- **Enter:** the Drive prompt on the driver's door (E / B / tap), shown only to the owner; only the owner drives.
  **Exit:** Interact (E / B / Get out button) puts you beside the driver's door.
- **Flip:** when the car is upside down and slower than 5 studs/s, Flip (from the seat or within 30 studs) rights
  it after 1 s, lifted 4 studs.
- **Boost** (1.5, hold): +35% top speed and torque, burns fuel 3× as fast. No cooldown — fuel is the limit.

### 5.3 Fuel

- Tank 100 (starter, `Config.Cars.Models[...].Tank`). Driving burns **1 fuel per 25 studs** (range ~2,500 studs),
  boosting 3× (from 1.5). *(tune)* The server measures the distance the car really moved while its owner drives
  (capped at 120 studs/s) — `Config.Fuel`, `Services/FuelService`.
- **Refuel only from oil barrels** (owner, 2026-11-23) — no pumps.
- Tank empty → the car **stalls** (the server takes its physics, it rolls to a stop) with a notice; it starts again
  as soon as oil gets in. Otherwise: Spawn car (≥ 25 fuel, 15 s cooldown).
- **Gauge:** a FUEL bar at the bottom while you drive; turns red below 20 %, with a "Low fuel" notice.

### 5.4 Oil barrels (`Config.Oil`, `Services/OilService`)

- **Rare and random** (owner, 2026-11-23): at most 18 on the map; a new one every 8 s while there are fewer, each at a
  random spot of open desert ground (not in the center, not by the cliffs, never inside rocks or under a mesa) —
  there are no fixed oil spots. An untouched barrel disappears after 4 minutes, so they keep moving around.
- **Floating:** each hovers 3.5 studs above the sand, bobbing and turning (client-side), with a warm glow — a dark
  steel drum with orange bands (`assets/props/OilBarrel.luau`).
- **Pickup:** drive within 8 studs of one: **+30 fuel** (up to a full tank) and a "+30 fuel" notice. A car with a
  full tank leaves it for someone else. Oil is fuel only — nothing to carry, sell or bank.

### 5.5 Ramming and wrecks (build order 1.5)

- Car health 100 (starter). When two cars hit with a closing speed over 20 studs/s, the car that is hit takes
  **(speed − 20) × 1.5** damage and the rammer takes 30% of that. Hitting the world over 40 studs/s does
  **(speed − 40) × 0.5**. *(tune)* The server works this out from replicated velocities, with sanity caps.
- **Wreck** at 0 health: explosion VFX, the car is gone; spawn a new one (Spawn car rules above).
- **Spawn center is safe:** no damage within `CenterHalfSize`.

### 5.6 Dev panel (Studio-only)

Fill or empty the tank, damage or wreck your car, teleport to a zone, drop an oil barrel next to you, clear all oil.

## 6. Economy and progression

- **No currency** (owner, 2026-11-23: no coin system). Coins were removed from the data (migration 1 → 2).
- **Levels / XP:** the template's level system is still there but nothing gives XP. *TBD*.
- **Retention:** *TBD*. No rewards for likes; group-join rewards are fine. Private servers earn nothing.

## 7. Monetization

*TBD* — the owner decides before Phase 3. Rules: no pay-to-win unless the owner says so; paid random items show every
outcome and its exact odds and respect `PlayerPolicyService`; no rewards for likes.

## 8. Build order

Each item is one PR, testable in Studio, tracked in `docs/PROGRESS.md`. Reshaped 2026-11-23 (no town, selling,
coins or garage).

**Phase 1 — playable core**

1. **1.1 Desert map** — done (town removed 2026-11-23).
2. **1.2 Starter car** — done (now spawned with the Spawn car button).
3. **1.3 Fuel** — done (pumps removed 2026-11-23).
4. **1.4 Floating oil + car spawn button + open center** — done 2026-11-23.
5. **1.5 Ramming + Boost:** car health, crash damage, safe center, wrecks; Boost action.
6. **1.6 Dev panel** (Studio-only) for testing all of the above.

**Phase 2 — polish**

1. **2.1 HUD polish:** speedometer, compass arrow to the nearest barrel / the center, zone name banner.
2. **2.2 First-drive guide:** spawn your car, find your first barrel.
3. **2.3 Map detail pass:** ranch, ruins, derricks, more props, music and sounds.
4. **2.4 Progression** — *TBD* (owner decides).

**Phase 3 — launch**

1. **3.1 Monetization** (owner decides what first).
2. **3.2 Performance pass** on low-end phones (streaming, part counts, car physics).
3. **3.3 Store art:** icon and thumbnails (many styles to pick from).
4. **3.4 Launch check** (`docs/LAUNCH.md`).

## 9. Launch checklist

See `docs/LAUNCH.md` and `lune run tools/launch-check`.
