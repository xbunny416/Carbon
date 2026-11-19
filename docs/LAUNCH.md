# Launch checklist

Everything left before release, in order. Run `lune run tools/launch-check` at any time to list the ids and
placeholders still unset in the code.

## 1. Publish and game settings (Studio)

- [ ] **File → Publish to Roblox** (creates the experience). DataStores only work once the place is published.
- [ ] Game Settings → Security: **Allow Studio Access to API Services** on.
- [ ] Game Settings → Places: **Max players** = `Config.World.MaxPlayers`.
- [ ] Game Settings → Avatar: R15 (or what the bible says).
- [ ] Devices: Computer, Phone, Tablet and Console all on (every control works on touch, keyboard and gamepad).

## 2. Robux items (Creator Dashboard → your experience → Monetization)

- [ ] Create every pass / product in `Config.Monetization`, paste the ids there (or send them to Claude).
- [ ] Passes need a 512×512 image (`tools/store-art` can render one).

## 3. Music and sounds (Studio → Toolbox → Audio, free Creator Store audio only)

- [ ] Paste ids into `src/shared/Config/Audio.luau`, then `lune run assets/build` (CI fails until rebuilt).

## 4. Store page

- [ ] Title, genre, description (draft it with Claude).
- [ ] **Icon** 512×512 and **thumbnails** 1920×1080 (`tools/store-art`, or Studio screenshots of real gameplay).
- [ ] Upload `src/localization/GameStrings.csv` to the localization table; turn on automatic translation.

## 5. Questionnaires and policy

- [ ] **Maturity & compliance questionnaire** — declare paid random items if the game has any.
- [ ] Paid random items: exact odds shown before paying, hidden where `PlayerPolicyService` says so.

## 6. Final checks

- [ ] Owner's UserId in `Config.Dev.AllowedUserIds` only if the dev panel should work in live servers.
- [ ] A playtest on a real phone (low-end if possible) and with a gamepad.
- [ ] `lune run tools/launch-check` shows 0 items left.
