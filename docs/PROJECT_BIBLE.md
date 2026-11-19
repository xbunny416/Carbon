# CarOff — project bible

The design spec. Written in the kickoff (2026-11-19) from the owner's answers; every number here is a value in
`src/shared/Config` (keep both in sync). Numbers marked *(tune)* are Claude's first guesses — change them after
playtests. Sections with *TBD* are still open — ask before building them.

## 1. Pitch

- **One line:** Drive out of a sunny desert town, scavenge oil barrels before the other cars do, ram rivals to make
  them spill their cargo, and get home to the gas station before your tank runs dry.
- **Genre:** car extraction game. Oil you carry is only yours once you sell it at the gas station; wreck and you drop
  it all for anyone to grab.
- **Players per server:** 12 (`Config.World.MaxPlayers`), all PvP, everyone in the same open map.
- **Session shape:** open roam, no rounds or timer. Leave town whenever you want, come back to sell whenever you want;
  new players join and drive at once.
- **Platforms:** PC, phone, tablet, console (every control on keyboard/mouse, touch and gamepad).

## 2. Core loop

- **First 10 seconds:** spawn in the motel parking lot next to your car, hop in, drive out of town toward the barrels.
- **One trip (~2–3 min):** drive into the desert → drive over barrels to load them (cargo fills up) → watch the fuel
  gauge, because driving burns oil → dodge or ram other cars → drive back into the gas station → cargo is sold for
  Coins and XP, the tank is refilled and the car repaired.
- **The tension:** the farther from town, the more barrels per spot and the less competition, but the longer the
  drive home on a limited tank. When the tank is empty the car burns one of your cargo barrels to keep going, so a
  greedy trip can eat its own loot.
- **First 10 minutes:** a few trips with the free Rusty Pickup, first Coins, first upgrade (bigger tank or cargo).
- **Long term:** buy better cars, upgrade each one, level up.

## 3. Look and feel

- **Art direction:** sunny Route 66 desert countryside. Warm sand, red-orange rock mesas, sage scrub, saguaro cacti,
  dirt roads with telephone poles and fence lines, tumbleweeds, windmills, old pickups. The town has a two-floor motel
  with a neon sign and a pool, and a red-and-white gas station with a canopy over the pumps. Late-afternoon sun, long
  shadows, a light dusty haze. Detailed, non-blocky Roblox 3D; maps built in code with many-part buildings and props.
  No reference pictures yet (`docs/reference/`).
- **Map palette:** `maps/lib/Palette.luau` (add desert sand, mesa red, sage, asphalt, motel teal/pink).
- **UI:** dark slate `#1E1E24` + the sunset orange accent `#FF7A1A` (`Ui/Kit.Colors`) — it fits the desert, kept.
- **Audio:** free Creator Store only (`Config/Audio.luau`): country / desert-rock music, engine loop, boost, crash,
  wreck explosion, barrel pickup, cash register on sale.

## 4. Controls

Driving uses Roblox's own vehicle controls (VehicleSeat), so it works on every device. Jumping is off while driving
(it would throw you out of the seat).

| Action | Keyboard / mouse | Gamepad | Touch |
| --- | --- | --- | --- |
| Drive / steer | W A S D or arrows | Left stick, RT gas, LT brake | Thumbstick |
| Boost (hold) | Left Shift | X | Big button by the jump button |
| Flip car (when upside down) | R | Y | Flip button (shows only when flipped) |
| Enter / exit car | E | B | Prompt / Exit button |
| Menu | M | D-pad Up | Menu button |

The template's `Action` becomes `Boost`; `Flip` is new (`Config.Controls`).

## 5. Systems

### 5.1 Map (`maps/layouts/Desert.luau`)

- One huge square, **2048 × 2048 studs**, ground top at Y = 0 (`Config.World.MapOrigin = {0, 0, 0}`), on the ground —
  not floating. Two parts: the **spawn town** in the middle and the **desert arena** all around it.
- **Zones** by distance from the center (square rings, `max(|x|, |z|)`):

| Zone | Distance | Oil spots | Barrels per spot | Respawn |
| --- | --- | --- | --- | --- |
| Town (safe) | 0–200 | none | — | — |
| Scrublands | 200–500 | 40 | 1 | 60 s |
| Mesa Flats | 500–800 | 30 | 2 | 90 s |
| Badlands | 800–1024 | 24 | 3 | 120 s |

- **Town (400 × 400):** the motel (two floors, ~10 rooms, balcony, stairs, neon sign, pool) with a parking lot of 12
  car spawn bays; the gas station (canopy, 6 pump bays, shop, price sign, oil tanks); a water tower and small props.
  Paved roads, low adobe walls with 4 gates.
- **Arena:** 4 dirt roads from the town gates to the map edges, a ring road at 500 (the Scrublands / Mesa Flats
  border), mesas and rock arches, a ranch, ruins, oil derricks, cactus fields, dry riverbeds and ramps.
- **Edge:** a ring of tall mesa cliffs plus an invisible wall so no car leaves the map.
- **Markers** (tagged parts): `CarSpawn` (12), `PumpBay` (6), `OilSpot` (with a `Zone` attribute), `SafeZone`.
- Streaming: raised to fit driving speeds — min radius 256, target 1024 *(tune in the performance pass)*.

### 5.2 Cars

- Built in code as detailed many-part models (`assets/` → `ReplicatedStorage.Assets.Models.Cars`), driven by a
  VehicleSeat with motor hinges and spring suspension. The driver's client owns the car's physics (smooth driving);
  the server owns fuel, cargo, health and money.
- One car per player, spawned at a free `CarSpawn` bay when they join or respawn. Leaving the game removes it.
- **Boost** (hold): +35% top speed and torque, burns fuel 3× as fast. No cooldown — fuel is the limit.
- **Flip:** when the car is upside down and slower than 5 studs/s, Flip rights it after 1 s.
- **Reset car** (menu): respawns the car in town; any cargo is lost (a way out when stuck).

### 5.3 Fuel

- Tank 100 (starter). Driving burns **1 fuel per 25 studs** (range ~2,500 studs), boosting 3×. *(tune)*
- Tank empty → one cargo barrel is burned automatically for **+25 fuel**, with a notice.
- Tank empty and no cargo → the car **stalls**; a "Tow home" button respawns it in town (nothing to lose).
- Refill is free at a gas station pump bay (25 fuel/s).

### 5.4 Oil barrels

- Barrels sit on `OilSpot` markers (amounts and respawn per zone above). Driving through a spot loads its barrels
  until the cargo is full (starter cargo: 6). The rest stay for someone else.
- Shown on the car's bed as barrels, so rivals can see who is loaded.

### 5.5 Selling (extraction)

- Pull into a gas station **pump bay** and stop: all cargo is sold — **25 Coins and 15 XP per barrel** — the tank
  refills and the car is repaired. Notice with the total; cash register sound.
- Leaderboard (player list): Coins and Oil sold.

### 5.6 Ramming and wrecks

- Car health 100 (starter). When two cars hit with a closing speed over 20 studs/s, the car that is hit takes
  **(speed − 20) × 1.5** damage and the rammer takes 30% of that. Hitting the world over 40 studs/s does
  **(speed − 40) × 0.5**. *(tune)* The server works this out from replicated velocities, with sanity caps.
- **Wreck** at 0 health: explosion VFX, all cargo spills as loose barrels around the wreck (they stay 60 s, anyone
  can load them), the driver respawns in town after 5 s with a repaired, refueled car.
- The last car to hit the wreck within 5 s gets **+25 XP**.
- **Town is a safe zone:** no damage and no loading spilled barrels inside it. Cars inside are slowly repaired.

### 5.7 Garage and upgrades (Phase 2)

| Car | Price | Level | Top speed | Tank | Cargo | Health |
| --- | --- | --- | --- | --- | --- | --- |
| Rusty Pickup | free | 1 | 60 | 100 | 6 | 100 |
| Dune Buggy | 1,500 | 3 | 80 | 80 | 4 | 70 |
| Ranch Hauler | 4,000 | 5 | 50 | 140 | 12 | 160 |
| Desert Muscle | 9,000 | 8 | 85 | 110 | 6 | 130 |
| Armored Rig | 18,000 | 12 | 55 | 160 | 16 | 260 |

- Owned cars are saved; pick the active one in the garage (menu screen, or at the motel).
- Upgrades per car, 5 levels each: **Engine** +8% top speed, **Tank** +15%, **Cargo** +1 barrel (Hauler and Rig +2),
  **Armor** +15% health. Cost of level n = `floor(UpgradeBase × 1.6^(n−1))`, UpgradeBase: Pickup 100, Buggy 300,
  Hauler 600, Muscle 1,200, Rig 2,000. *(tune)*

### 5.8 Dev panel (Studio-only)

Give Coins / XP, fill or empty the tank, fill cargo, damage or wreck your car, teleport to a zone, respawn all oil.

## 6. Economy and progression

- **Soft currency:** Coins (`Config.Economy`), earned by selling oil (25 per barrel), spent on cars and upgrades.
- **Levels:** XP to next level = `floor(100 × L^1.4)`, cap 100 (`Config.Progression`). XP: 15 per barrel sold, 25 per
  wreck. Levels gate the cars (table above).
- **Daily / retention (Phase 3):** 7-day login streak (100, 150, 200, 300, 400, 500, 1,000 Coins); one-time 500 Coins
  for joining the group. No rewards for likes. Private servers earn nothing.

## 7. Monetization

*TBD* — the owner decides before Phase 3 (2026-11-19). Ideas on the table: a VIP pass, Coin packs, Robux-only cars.
Rules: no pay-to-win unless the owner says so; paid random items show every outcome and its exact odds and respect
`PlayerPolicyService`; no rewards for likes.

## 8. Build order

Each item is one PR, testable in Studio. Approved by the owner, then tracked in `docs/PROGRESS.md`.

**Phase 1 — playable core**

1. **1.1 Desert map:** the 2048 square on the ground, the town in the middle with a detailed motel and gas station,
   roads, zone rings, mesas / rocks / cacti blockout, edge cliffs, all markers. Players spawn in the motel lot.
2. **1.2 Starter car:** the Rusty Pickup built in code; spawns at your bay; enter / exit; drive on keyboard, gamepad
   and touch; Flip; Reset car.
3. **1.3 Fuel:** tank, burn by distance, fuel gauge HUD, stall + Tow home, free refill at the pumps.
4. **1.4 Oil barrels:** barrels on oil spots by zone, respawn timers, drive-through loading, cargo HUD and barrels on
   the car bed, auto-burn a barrel when the tank is empty.
5. **1.5 Selling:** pump bays sell cargo for Coins + XP, refuel and repair; leaderboard; notices and sound.
6. **1.6 Ramming + Boost:** car health, crash damage, safe zone, wrecks spill cargo, respawn; Boost action.
7. **1.7 Dev panel** (Studio-only) for testing all of the above.

**Phase 2 — progression**

1. **2.1 Garage:** 5 cars to buy (Coins + level), saved, choose your active car.
2. **2.2 Upgrades:** Engine, Tank, Cargo, Armor, 5 levels per car.
3. **2.3 HUD polish:** speedometer, compass arrow to town, zone name banner, sale pop-up.
4. **2.4 First-trip guide:** arrows to the nearest barrel, then back to the pumps.
5. **2.5 Map detail pass:** ranch, ruins, derricks, more props, sky and lighting, music and sounds.

**Phase 3 — launch**

1. **3.1 Monetization** (owner decides what first).
2. **3.2 Daily streak + group bonus.**
3. **3.3 Performance pass** on low-end phones (streaming, part counts, car physics).
4. **3.4 Store art:** icon and thumbnails (many styles to pick from).
5. **3.5 Launch check** (`docs/LAUNCH.md`).

## 9. Launch checklist

See `docs/LAUNCH.md` and `lune run tools/launch-check`.
