# CarOff

A Roblox game built code-first with Rojo. Started from the owner's game template (made from Brawl Arena).

- Design spec: [docs/PROJECT_BIBLE.md](docs/PROJECT_BIBLE.md)
- How the repo works, conventions and the owner's rules: [CLAUDE.md](CLAUDE.md)
- Progress log and build order: [docs/PROGRESS.md](docs/PROGRESS.md)

## Quick start

```sh
rokit install                      # Rojo, Selene, StyLua, Lune, luau-lsp (versions in rokit.toml)
rojo serve                         # then Connect from the Rojo plugin in Roblox Studio
```

Cloud / Linux without Rokit: `scripts/cloud-setup.sh`. No Rojo at all: download the `Game-place` artifact from the
latest CI run and open the `.rbxlx` in Studio.

## Checks (CI runs all of them; green PRs from `claude/*` branches auto-merge)

```sh
stylua --check src tests maps tools assets
selene src
scripts/typecheck.sh
lune run tests/run
lune run maps/build --check && lune run assets/build --check
rojo build default.project.json -o build/Game.rbxlx
```

## Starting another game from this one

Copy the repo without its history (or use GitHub's "Use this template" if it's marked as a template), then in the
first Claude session say "start a new game" — the `game-kickoff` skill interviews you, writes the bible and proposes a
build order.
