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
