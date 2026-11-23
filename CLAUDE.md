# CarOff — working notes for Claude

Read this first in every session. This repo started from the owner's **roblox-game-template** (made from Brawl Arena,
2026-11). Design spec: [docs/PROJECT_BIBLE.md](docs/PROJECT_BIBLE.md). History in `docs/`:
[PROGRESS.md](docs/PROGRESS.md) (build order, one row per PR), [DECISIONS.md](docs/DECISIONS.md) (the owner's choices
and every call made where the bible is silent — read the matching entry before changing how a system behaves),
[STUDIO_TESTING.md](docs/STUDIO_TESTING.md) (how to test each system in Studio, playtest notes),
[LESSONS.md](docs/LESSONS.md) (Roblox and tooling traps already hit once — read before touching that area) and
[reference/](docs/reference/README.md) (the owner's reference pictures and their answers).

## Status

- **CarOff** (the repo is still named Carbon): a car survival / scavenging game in an open desert — spawn your car,
  hunt rare floating oil barrels (the only fuel), ram rivals. Kickoff 2026-11-19; reshaped by the owner 2026-11-23
  (no town, no coins, oil = fuel only, car spawn button). Build order: bible §8. Renaming: here, `README.md`,
  `Game.Title` in GameStrings.csv, `default.project.json`.
- **Built (from the template):** toolchain, CI + auto-merge, Lune specs, strict type-check, Loader, Config, Net,
  player data (ProfileStore), localization, analytics, settings, policy checks, UI Kit, menu, input (keyboard /
  gamepad / touch), notices, map + asset generators, launch check, store-art renderer.
- **Built (CarOff):** desert map with an open sand center and spawn pads; Rusty Pickup (Spawn car button, drive /
  get out / flip); fuel (gauge, stall); floating oil barrels (random, rare, +fuel).
- **Next:** 1.5 ramming + boost (bible §5.5).

## Who the owner is and how they like to work

- Writes short messages in non-native English ("cus", "rn", "i want ..."). Read for intent, don't ask about spelling;
  answer in **plain, short language**: what changed, what to do in Studio, what is left. No jargon walls.
- Works from **two places**: a local Claude Code CLI with the **Roblox Studio MCP** (building, playtests, screenshots)
  and cloud sessions on claude.ai/code (code + CI only, no Studio). Say which side a step needs.
- Wants things **automated**: every change goes through a PR that **auto-merges when CI is green**. Don't ask "should
  I open a PR / merge?" — just do it on the `claude/...` branch.
- Decisions: ask with **AskUserQuestion**, 2–4 options, the recommended one first and marked "(Recommended)", each
  with a one-line trade-off. Ask only what is truly theirs to decide; pick sensible defaults for the rest and log them
  in DECISIONS.md.
- Sends **reference pictures** from other games: take the look, never copy models or assets. Save them under
  `docs/reference/` with a table of what to take from each; write their answers there too.
- Likes **many options to choose from** for visual things (e.g. 10 different thumbnail styles), then picks one.
- Taste (changed 2026-11-19): the **blocky-parts style** — use the `roblox-blocky-parts-style` skill for every model,
  prop, building and car: chunky primitives, wedge bevels, muted earthy colors, medium detail, soft hazy light. Maps
  and cars are still built **in code** (layouts / `assets/cars`), sized to the avatar.
- Changes their mind as the game grows (renames, removing features): record each change with its date in
  DECISIONS.md and keep the "Standing owner decisions" list below current so nobody brings a removed thing back.
- Playtests in Studio and reports in short lists; turn each list into a numbered fix list, fix it in one PR when
  small, and write what to re-check in STUDIO_TESTING.md.

## Standing owner decisions

Easy to break by accident; reasons and dates in DECISIONS.md. (Carried over from the last game — keep unless the owner
says otherwise.)

- **Paid random items** (rolls, wheels, crates): every outcome and its exact odds are in view before paying; paid
  ones only where `PlayerPolicyService.allows(player, "PaidRandomItems")`; declare them on the maturity form.
- **No rewards for liking the game** (against Roblox rules); group-join rewards are fine.
- **Private servers earn nothing** progression-wise unless the owner decides otherwise for this game.
- Developer tools are **Studio-only** (`Config.Dev.AllowedUserIds` empty) until the owner adds their UserId.
- **Look = blocky-parts style** (2026-11-19, replaced the bright detailed Route 66 look): muted palette in
  `maps/lib/Palette.luau`, Neon only on real lights. Don't bring back saturated / neon styling.
- **No town** (2026-11-23): the motel, gas station, garage and the rest were deleted; the center is plain sand
  with spawn pads, no walls. Don't bring buildings back to the center.
- **No coin system** (2026-11-23): no currency, no selling, no shop / garage purchases. **Oil is fuel only** and
  barrels are rare, random and floating (no fixed oil spots). **Refuel only from oil** (no pumps).
- **Cars spawn from the Spawn car button** next to the player (2026-11-23), never automatically.
- **No loading screen at all** (2026-11-23): `src/first/LoadingScreen.client.luau` only hides Roblox's default one;
  don't add a custom loading screen back.
- **No floating starter lobby:** the template's lobby (60×60 room up at Y=100) was removed on 2026-11-19; the game's
  real maps come from the kickoff. Don't bring it back.
- Only **free Creator Store assets / Studio AI generation**; ask before anything paid. Never delete or replace large
  parts of the place without asking.

## Workflow for a new feature

1. If the bible doesn't cover it, ask (AskUserQuestion) or choose and log it in DECISIONS.md.
2. Sync: `git fetch origin main && git checkout -B <claude branch> origin/main`.
3. Build it the way the conventions below say (Config tunables, GameStrings keys, Net definitions, specs).
4. Run every check (commands below) until clean — a red CI blocks the auto-merge.
5. Docs in the same PR: a row in PROGRESS.md, choices in DECISIONS.md, how to test it in STUDIO_TESTING.md, Status
   above kept short.
6. Push, open the PR (one feature per PR), let CI merge it. Tell the owner in a few lines what to try in Studio.

The `ship-feature` skill is this checklist step by step.

## How this repo works

The game is **code-first**: all Luau lives in `src/` and is synced into Roblox Studio with
[Rojo](https://rojo.space). Cloud sessions have **no Studio MCP connection**, so they write code and rely on CI;
visual building, screenshots and playtests happen in Studio (owner, or a local Claude Code session with the Roblox
Studio MCP server).

**Local setup (owner):** install [Rokit](https://github.com/rojo-rbx/rokit), `rokit install` (Rojo, Selene, StyLua,
Lune at the versions in `rokit.toml`), `rojo plugin install`; `rojo serve`, open a place in Studio, click **Connect**
in the Rojo plugin (restart `rojo serve` after a new file is added to `default.project.json`). In game settings
enable **Studio Access to API Services** (DataStores only work once the place is published: File → Publish to
Roblox); turn on automatic translation in the Creator Dashboard. Without Rojo: open the `.rbxlx` from the latest CI
run's `Game-place` artifact. **Cloud sessions:** `scripts/cloud-setup.sh` installs the same tools (see LESSONS.md).

| Path | Becomes in Studio | Contents |
| --- | --- | --- |
| `src/shared/` | `ReplicatedStorage.Shared` | Config, formulas, settings rules, types, networking, utilities |
| `src/server/` | `ServerScriptService.Server` | `Main.server.luau` + `Services/` (one module per system) + pure rule folders |
| `src/client/` | `StarterPlayer.StarterPlayerScripts.Client` | `Main.client.luau` + `Controllers/` (input, HUD, camera, VFX) |
| `src/client/Lib/` | `...Client.Lib` | Pure client logic tested by specs (action map, touch layout) |
| `src/client/Ui/` | `...Client.Ui` | `Kit`: shared look (colors, fonts) and builders for panels, labels, buttons; `KeyHint` |
| `src/localization/GameStrings.csv` | `LocalizationService.GameStrings` | Every player-facing string (Key, Source, Context, Example) |
| `src/first/` | `ReplicatedFirst` | `LoadingScreen.client.luau`: only hides Roblox's default loading screen |
| `src/server/Vendor/` | `ServerScriptService.Server.Vendor` | Third-party modules kept as published (see `licenses/`) |
| `maps/layouts/` | — | Map layouts as code — the source of truth for every map |
| `maps/generated/` | `Workspace.Desert` | `.rbxmx` models generated from the layouts (committed) |
| `assets/` | — | Templates game code clones (VFX, sounds, animations, models), built from Config by `assets/build.luau` |
| `assets/generated/` | `ReplicatedStorage.Assets` | `Assets.rbxmx` generated from `assets/` (committed) |
| `tools/` | — | Lune helpers (csv, launch check) and `store-art/` (icon + thumbnail renderer) |
| `tests/` | — (not synced) | Lune runner `tests/run.luau`, specs in `tests/specs/*.spec.luau` |
| `docs/` | — | Bible, progress log, decisions, Studio testing notes, lessons, launch checklist, references |

`Shared/Util/Loader` boots every ModuleScript in `Services/` (server) or `Controllers/` (client): all `Init()` run
first in `Priority` order, then each `Start()` runs in its own thread.

```sh
stylua src tests maps tools assets   # format (CI runs stylua --check)
selene src                           # lint
scripts/typecheck.sh                 # strict type-check with luau-lsp + Roblox API types
lune run tests/run                   # syntax-compile every src/*.luau + run specs
lune run maps/build                  # regenerate maps/generated/*.rbxmx after editing maps/ (CI: --check)
lune run assets/build                # regenerate ReplicatedStorage.Assets after editing assets/ or its Config (CI: --check)
lune run tools/launch-check          # list the ids / placeholders still unset before release (report only)
rojo build default.project.json -o build/Game.rbxlx
```

Files are LF on every OS (`.gitattributes`); StyLua's check and the generator checks fail on CRLF copies.

## Conventions (required)

- Every script starts with `--!strict`. Tabs, 120 columns, double quotes (StyLua enforces).
- **Server-authoritative:** clients send *intents* only ("I pressed Action"). The server checks cooldowns, distance,
  state and currency, decides outcomes, and replicates results. Never trust client positions or values beyond a
  sanity-checked tolerance.
- **All tunables in Config** (`src/shared/Config`, deep-frozen). No magic numbers for prices, damage, cooldowns,
  rewards, odds or formulas anywhere else. Keep `docs/PROJECT_BIBLE.md` in sync when Config changes.
- **No hard-coded UI text:** every visible string is a key in `src/localization/GameStrings.csv`, shown with
  `Localization.format(key, args)` (a spec fails on a key missing from the CSV or a literal `Text = "..."`). After
  adding keys, upload the CSV to the game's localization table in the Creator Dashboard.
- **Networking:** every remote is declared in `src/shared/Net/Definitions.luau`. Client → server remotes list `Args`
  validators from `Net/Guard` (NaN/inf-safe, length-capped) and get a per-player rate limit (`Config.Net`, overridable
  per remote). Server code uses `Net.onServerEvent` / `Net.onServerInvoke`, never RemoteEvents directly. Never use
  server → client invokes.
- **Player data:** only change it through `Services/DataService` (`addCoins`, `spendCoins`, `addXP`,
  `incrementStat`, `update`, `processReceipt`) so the owning client is synced and analytics are logged. New template
  fields are filled in automatically; renames/removals need a migration (`src/server/Data/Migrations.luau`, bump
  `VERSION` in `src/shared/Data/Template.luau`). Clients read their copy via `Controllers/DataController`.
- **Maps:** generated from `maps/layouts/*.luau` by `lune run maps/build`; never hand-edit `maps/generated/`. Add a
  new map to `maps/build.luau` and `default.project.json`. Gameplay markers are tagged parts (e.g. `CarSpawn`, hidden at runtime by `MapService`);
  sign text comes from GameStrings keys (`Key` on `B.sign`). Colors are names from `maps/lib/Palette.luau`.
  **Directions:** the Builder's North = +Z, East = +X are a mirror image of a compass (facing +Z, +X is on your
  *left*): tell the owner left / right as you face +Z, never "east / west".
- **Input:** gameplay code never reads raw keys. It listens to `Controllers/InputController` (`ActionBegan` /
  `ActionEnded` with an action from `Config.Controls.Actions`; `getDevice()` / `DeviceChanged` for key hints). A new
  action needs a keyboard and a gamepad binding, a `Controls.<Action>` string, and a touch button in
  `Config.Controls.Touch.Layouts` if mobile players use it (a spec checks sizes and overlaps on many screens).
- **Menu screens** register with `Controllers/MenuController.addScreen(text, order, gui, onOpen)`: a left-edge button
  (none when `text` is nil), one screen open at a time, closed while the Player attribute `MenuBlocked` is true; the
  Menu action (M / D-pad Up) closes the open screen or opens the first; `openNamed(name, arg)` passes `arg` to
  `onOpen` (e.g. a tab). Tabs use `Kit.tabRow`.
- **Settings** are read and changed through `Controllers/SettingsController`; the server validates each change with
  `Shared/Settings` (`Services/SettingsService`). New numeric settings need a range in `Config.Data.SettingRanges`.
- **Robux:** one service owns `MarketplaceService.ProcessReceipt` and grants products with
  `DataService.processReceipt` (once per PurchaseId). Clients only prompt; the server grants what Roblox confirms. Ids
  and prices live in `Config.Monetization`. Ask `Services/PlayerPolicyService.allows(player, feature)`
  (`Shared/PolicyRules`) before adding paid random items, paid trading or external links.
- **Analytics:** log through `Services/Analytics` helpers (`coinsEarned`, `coinsSpent`, `onboardingStep`,
  `robuxPurchase`, `custom`); add a helper per new funnel.
- **Notices:** short pop-up messages go through the `Notify` remote (`NoticeController` shows them) with a
  GameStrings key.
- **Vendored code** (`src/server/Vendor/`) is never edited and is excluded from StyLua/Selene/luau-lsp.
- Pure logic (formulas, reward math, validation) goes in modules with no Roblox-instance dependencies so Lune specs can
  test it; add specs for every formula. Specs load game modules through `tests/roblox.luau`, a fake DataModel built
  from `default.project.json`, so modules keep normal `require(script.Parent.X)` requires.
- Filter all player-written text with TextService before others see it.

## Roblox Studio Project Rules

The owner's rules (2026-10-30), verbatim in spirit. Follow them in every new file.

### Architecture & Code Standards
- Use pure native Luau. No Wally, no external packages. (Exception kept from the last game: `Vendor/ProfileStore`.)
- Never use legacy globals: use `task.wait()`, `task.delay()`, `task.defer()`, never `wait()`, `spawn()`, or
  `delay()`.
- Use `Debris:AddItem()` or `task.defer()` for object cleanup to prevent memory leaks.
- Always separate Server (ServerScriptService) and Client (StarterPlayerScripts). Never trust client input.

### UI Design Rules
- When writing UI via script, never use pure gray/default styling.
- Always use `AnchorPoint = Vector2.new(0.5, 0.5)`.
- Use `UDim2.fromScale()` for positioning and size. Never hardcode large Offset pixel values.
- Always add `UICorner` (Radius 8-12px) and `UIPadding` (12-16px) to frames.
- Color palette standard: Dark mode slate backgrounds (`#1E1E24`), vibrant accent colors for buttons/bars
  (`Ui/Kit.Colors`: `#2D2E3B` buttons, a `#FF7A1A` accent with dark `OnAccent` text — change the accent per game).
- Animate UI using `TweenService` with `Enum.EasingStyle.Quad` or `Back` for responsive feel.

### Assets, VFX & Animations
- Never generate raw ParticleEmitters, Sounds, or Rigs with empty IDs (nor emitters with default white textures).
- VFX: Clone templates from `ReplicatedStorage.Assets.VFX`, call `:Emit(count)`, and tween scale/transparency.
- Audio: Clone from `ReplicatedStorage.Assets.Sounds`, randomize `PlaybackSpeed` (0.9–1.1), and play.
- Animations: Load `Animation` objects from `ReplicatedStorage.Assets.Animations` onto `Humanoid.Animator`.
- Models: Clone props/weapons from `ReplicatedStorage.Assets.Models` and position/weld via script.
- `ReplicatedStorage.Assets` is generated from `assets/` (`lune run assets/build`; a spec checks it). `Sounds` gets one
  per `Config.Audio` slot with an id (0 = silent, skipped); `Animations` one per `Config.Animations.AssetIds` entry.
  The `roblox-animation` skill makes animations in Studio.

## GitHub workflow (automated)

- Develop on the session's `claude/...` branch. One feature per PR.
- **CI** (`.github/workflows/ci.yml`) on every PR: StyLua check → Selene → luau-lsp strict type-check → Lune (syntax +
  specs) → generated models up to date → Rojo build (uploads `Game.rbxlx` as the `Game-place` artifact).
- **Auto-merge:** when CI is green, PRs from `claude/*` branches are squash-merged and the branch is deleted. To stop
  one, open it as a **draft** or add the **`no-automerge`** label. (Repo setting needed once: Settings → Actions →
  General → Workflow permissions → "Read and write" + "Allow GitHub Actions to create and approve pull requests".)
- After a merge, start the next feature from fresh `main` on the same branch name
  (`git fetch origin main && git checkout -B <branch> origin/main`).

## Known limits

- Clients simulate their own character, so exploiters can move freely; server-side movement checks are a hardening
  task for any game that needs them.
- Camera sensitivity can't be changed by scripts.
- DataStores need a published place (File → Publish to Roblox) and Studio Access to API Services.
