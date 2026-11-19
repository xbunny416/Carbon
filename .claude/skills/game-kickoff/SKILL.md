---
name: game-kickoff
description: Start a new Roblox game in this repo — interview the owner, write docs/PROJECT_BIBLE.md, propose a phased build order and wait for approval before building anything. Use at the start of a new project, when CLAUDE.md's Status says "nothing built yet", or when the owner says "start", "new game", "make a game about X", sends a big spec / master directive, or asks for a plan.
---

# Game kickoff

The owner wants the game to match the idea in their head and wants to go fast. Both come from asking the right
questions once, writing the answers down, and getting one "approve" on the plan. Never start building systems before
the build order is approved.

## 1. Read what exists

- `CLAUDE.md` (owner profile, rules), `docs/PROJECT_BIBLE.md` (empty sections are *TBD*), `docs/reference/` (pictures).
- If the owner pasted a long spec, it is the source: copy every number into the bible, ask only about gaps.

## 2. Interview (AskUserQuestion, 2–4 options each, recommended first)

Ask in rounds of up to 4 questions; don't ask what the spec already answers. Cover:

1. **Genre and core loop** — what the player does in the first 10 seconds and the first 10 minutes.
2. **Session shape** — rounds / lobby + arenas, open world, tycoon / simulator, obby, story.
3. **Players per server** and PvP / co-op / solo.
4. **Look** — offer distinct art directions (the owner's default: detailed, non-blocky Roblox 3D, code-built maps);
   ask for reference pictures and save them in `docs/reference/` with what to take from each.
5. **Progression and economy** — what Coins buy, levels, daily rewards, quests.
6. **Monetization** — passes / products; any paid random items (then: exact odds + PolicyService + maturity form).
7. **Name** (working title is fine) and target devices.

Keep each option one line with its trade-off. Use multiSelect for "which features".

## 3. Write the bible

Fill every section of `docs/PROJECT_BIBLE.md` with concrete numbers (they become Config values). Record each answer
and each call you made yourself in `docs/DECISIONS.md` with the date. Update the title placeholders (`CLAUDE.md`,
`README.md`, `Game.Title` in GameStrings.csv, `name` in `default.project.json`).

## 4. Propose the build order

Phases of small PRs, each testable in Studio and ending in something playable:

- **Phase 1 — playable core:** the one loop that makes the game fun, rough blockout maps, a dev panel (Studio-only).
- **Phase 2 — progression:** rewards, saving what matters, shop / inventory, UI polish, onboarding.
- **Phase 3 — launch:** monetization, retention, performance on low-end phones, store art, launch check.

Write it as a numbered list (1.1, 1.2 …) in the bible §8, show it to the owner in plain words, and **wait for
approval** (AskUserQuestion: approve / change something). Then add the first row to `docs/PROGRESS.md` and start 1.1
with the `ship-feature` skill.
