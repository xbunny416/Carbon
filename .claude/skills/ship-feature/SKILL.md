---
name: ship-feature
description: Build one feature or fix list end to end in this Roblox repo and ship it as a PR that auto-merges on green CI — sync main, follow the conventions, add specs and strings, run every check, update the docs, push, open the PR, watch CI. Use for every build-order item, every playtest fix list, and any change the owner asks for.
---

# Ship a feature

One feature (or one fix list) = one PR. The owner never has to ask for the PR or the merge.

## 1. Start clean

```sh
git fetch origin main && git checkout -B <your claude/... branch> origin/main
```

Read the bible section and the DECISIONS.md entries for the system. If something is unclear and it's the owner's
call, ask (AskUserQuestion, recommended option first); otherwise choose and log it.

## 2. Build it the repo's way

- Tunables → `src/shared/Config/*` (and the bible). Text → keys in `src/localization/GameStrings.csv`.
- Remotes → `src/shared/Net/Definitions.luau` with Guard validators; server uses `Net.onServerEvent`.
- One service per system in `src/server/Services/`, one controller per client system in `src/client/Controllers/`.
- Pure rules in their own module + a spec in `tests/specs/` (every formula gets a spec).
- Player data only through DataService; new fields in `Shared/Data/Template.luau` (renames → migration + VERSION).
- Maps: edit `maps/layouts/*` then `lune run maps/build`. Assets: edit `assets/` / Config then `lune run assets/build`.
- UI: `Ui/Kit` builders, the owner's UI rules (slate + accent, AnchorPoint 0.5, scale sizes, UICorner, UIPadding,
  Quad/Back tweens), `MenuController.addScreen` for menu screens.
- `--!strict`, `task.*` only, Debris / defer cleanup, never trust the client.

## 3. Check everything (all must pass — a red CI blocks the merge)

```sh
stylua src tests maps tools assets
selene src
scripts/typecheck.sh
lune run tests/run
lune run maps/build --check && lune run assets/build --check
rojo build default.project.json -o build/Game.rbxlx
```

In a cloud session without the tools, run `scripts/cloud-setup.sh` first (LESSONS.md explains why).

## 4. Docs in the same PR

- `docs/PROGRESS.md`: one row (date, what changed, PR number after it exists — use the next number).
- `docs/DECISIONS.md`: every new choice, dated, owner's or yours.
- `docs/STUDIO_TESTING.md`: how to test it in Studio, debug switches.
- `CLAUDE.md` Status (short) and Standing owner decisions if the owner removed / locked something.
- `docs/LESSONS.md` if you hit a new Roblox or tooling trap.

## 5. Ship

Commit (clear message), push the branch, open a PR (not draft) with a short summary + test steps. CI squash-merges
it when green. Watch CI; if red, fix and push again until green. Then tell the owner in a few plain lines: what's new,
what to try in Studio, anything they must do (ids, publish, settings).
