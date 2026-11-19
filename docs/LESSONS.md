# Lessons learned

Traps already hit once (most in Brawl Arena, 2026-10/11). Read the matching section before touching that area; add a
line whenever a new one costs time.

## Roblox

- **Shift Lock:** a LocalScript can't set `Player.DevEnableMouseLock` (the controller's Init errors and everything after
  it in that Init never runs). The server sets `StarterPlayer.EnableMouseLockOption` (SettingsService).
- **A failed `Init` hides other bugs:** one error in a controller's Init silently disabled camera shake for days.
  When something "doesn't feel right", read Output for red errors first.
- **Lighting:** `Lighting.Technology` is replaced by `LightingStyle` (Realistic = the old Future look). Set it in
  `default.project.json`; if Rojo doesn't change it in an open place, set it by hand once.
- **Chat:** use TextChatService (`ChatVersion` in the project). Legacy chat's ChatScript errors in Studio. Save the
  place once after Rojo syncs it.
- **DataStores** only work in a published place with Studio Access to API Services on. Otherwise players are kicked
  with Data.LoadFailed; `Config.Data.UseMockInStudio = true` plays without saving.
- **Scripted animations** (poses in code): drive `Motor6D.C0` (or an `AnimationConstraint`'s `Attachment0`), never
  `Transform` (Roblox's Animate script overwrites it every frame). Detect R6 / R15 / AnimationConstraint rigs.
  Angles tuned without seeing them usually need flipping — ask for a playtest early.
- **Builder directions:** North = +Z, East = +X is a mirror of a compass. Tell the owner left / right as they face +Z.
- **Streaming:** big maps stream in by distance; anything gameplay needs everywhere (platforms, movers) must be a
  Model with `ModelStreamingMode = Persistent`. Listen for instances leaving (`GetInstanceRemovedSignal`).
- **Paid random items** need exact odds before paying, `PolicyService` checks (some countries forbid them) and the
  maturity questionnaire. **Never reward likes** (Roblox rules); group-join rewards are allowed.
- **Asset warnings** for ids that aren't in `src/`, `maps/` or the place are usually from an avatar item — not ours.
- **Mover hazards:** parts moved only on clients stay still on the server; server hit checks must read the mover's
  rules (time-based position), not the server part.
- **Rojo:** restart `rojo serve` after adding a file to `default.project.json`, or the new model never syncs.

## Tooling

- **Cloud sessions:** Rokit can't run (api.github.com is blocked) but GitHub release downloads work —
  `scripts/cloud-setup.sh` installs everything in seconds. Don't `cargo install` the tools (15+ minutes).
- **Selene's Roblox std** is downloaded by Selene itself, which fails behind the cloud proxy; the script seeds
  `~/.cache/selene/roblox.yml` from `tools/selene/roblox.yml.gz` (refresh that file now and then from a machine
  with normal internet: `selene generate-roblox-std`, gzip the result). CI downloads a fresh one.
- **StyLua** must have Luau support (the release binaries do; a plain `cargo install stylua` doesn't, and then
  `stylua --check` disagrees with CI on Luau syntax like `(require :: any)`). Install with `--features luau`.
- **luau-lsp strict mode:** `pcall` on a function returning nothing → use `xpcall` with a handler; attribute values
  are `any`/unknown → read them through small typed helpers; literal types widen → annotate tables; a generic
  vendored type (ProfileStore) → narrow it to a local type with the fields you use.
- **Lune fake DataModel** (`tests/roblox.luau`) is built from `default.project.json`: a new `$path` that's a file
  (like the CSV) needs a class mapping there.
- **The localization spec** scans code for literal `Text = "..."` and `Localization.format("key")`: doc comments that
  look like those get flagged — reword them.
- **CI waits:** check PR status with the GitHub MCP `pull_request_read`, not a script polling a short SHA.
- **LF endings:** CRLF files fail StyLua's check and the generator `--check`s (`.gitattributes` forces LF).
- **Lune parts:** `part.Position` can't be read in Lune (it isn't a saved property) — use `part.CFrame.Position` in
  specs. Roblox caps a part at 2048 studs per side: split anything bigger (the desert ground is ring strips).

## Store art

- Headless Chromium needs software GL (`--use-gl=angle --use-angle=swiftshader`) for three.js.
- Bloom + fog + a strong sun wash everything out; keep bloom low, light the faces, avoid a hard horizon band, keep
  every character fully in frame and facing the camera (turn the head group, not just the body).
