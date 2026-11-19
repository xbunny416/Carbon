# Carbon — project bible

The design spec. Written in the kickoff (the `game-kickoff` skill) from the owner's answers; every number here is a
value in `src/shared/Config` (keep both in sync). Sections with *TBD* are still open — ask before building them.

## 1. Pitch

- **One line:** *TBD* (genre, what the player does, why it's fun in 10 seconds)
- **Players per server:** *TBD* (`Config.World.MaxPlayers`)
- **Session shape:** *TBD* (rounds? open world? tycoon loop?)
- **Platforms:** PC, phone, tablet, console (every control on keyboard/mouse, touch and gamepad)

## 2. Core loop

*TBD* — what the player does minute to minute, what they earn, what they spend it on.

## 3. Look and feel

- **Art direction:** *TBD* (reference pictures in `docs/reference/`). Owner's default taste: detailed, non-blocky
  Roblox 3D; maps built in code with many-part furniture and props that fit each place.
- **Map palette:** `maps/lib/Palette.luau`. **UI:** dark slate `#1E1E24` + a vibrant accent (`Ui/Kit.Colors`).
- **Audio:** *TBD* (free Creator Store audio only; ids in `Config/Audio.luau`).

## 4. Controls

| Action | Keyboard / mouse | Gamepad | Touch |
| --- | --- | --- | --- |
| Action | Left click | X | Big button by the jump button |
| Interact | E | B | Prompt |
| Menu | M | D-pad Up | Menu button |

Add a row per new action (`Config.Controls`).

## 5. Systems

One subsection per system: what it does, its rules, its Config numbers. *TBD*.

## 6. Economy and progression

- **Soft currency:** Coins (`Config.Economy`), earned by *TBD*, spent on *TBD*.
- **Levels:** XP to next level = `floor(100 × L^1.4)`, cap 100 (`Config.Progression`).
- **Daily / retention:** *TBD*.

## 7. Monetization

Game passes and developer products (`Config.Monetization`): *TBD*. Rules: no pay-to-win unless the owner says so;
paid random items show every outcome and its exact odds and respect `PlayerPolicyService`; no rewards for likes.

## 8. Build order

Phases of small PRs, each one testable in Studio. Filled in at the kickoff, approved by the owner, then tracked in
`docs/PROGRESS.md`.

## 9. Launch checklist

See `docs/LAUNCH.md` and `lune run tools/launch-check`.
