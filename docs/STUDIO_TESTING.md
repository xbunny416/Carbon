# Studio testing notes

How to test each system in Studio, debug switches, playtest history and known limits. Add a section with every
feature; after each playtest, a dated line with the owner's notes and what was fixed.

## First run

1. `rojo serve`, open a new place (Baseplate), Rojo plugin → **Connect**. `ReplicatedStorage.Assets` appears. There is
   no map yet, so keep the Baseplate's own `Baseplate` and `SpawnLocation` to stand on. If an old `Workspace.Lobby`
   is still in the place (from before 2026-11-19), delete it by hand — Rojo doesn't remove it.
2. **Save the place** once (keeps the TextChatService and lighting switches).
3. File → Publish to Roblox, then Game Settings → Security → **Allow Studio Access to API Services** (saving).
4. Play: the loading screen shows the title and a tip, then fades; you spawn on the Baseplate. Output should have no
   red errors. If data can't load (place not published, or API access off) you are kicked with "Your progress could not
   be loaded": publish + enable API access, or set `Config.Data.UseMockInStudio = true` to play without saving.

## Base systems

- **Input:** press M / D-pad Up (Menu). With `Config.Dev.LogInput = true`, Output prints each action and device.
  Touch: Test → Device emulator (phone): the Action button sits left of the jump button.
- **Saving:** change a setting (once a Settings screen exists), leave, rejoin: it stays (not with
  `UseMockInStudio`, which forgets everything when the test ends).
- **Notices:** the server's `Notify` remote shows a short message at the top (e.g. `Data.LoadFailed`).
- **Two players:** Test → Clients and Servers → 2 players.

## Playtests

- *(none yet)*
