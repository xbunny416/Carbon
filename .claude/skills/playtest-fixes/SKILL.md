---
name: playtest-fixes
description: Turn the owner's playtest notes, screenshots, Studio Output logs or a short "fix list" into numbered fixes and ship them. Use when the owner reports bugs, says something "feels wrong", pastes Output errors, or sends a list of changes after playing.
---

# Playtest fixes

1. **Restate** the notes as a numbered fix list in plain words (one line each). Group by system. If a note is
   ambiguous ("hit feels weird"), offer 2–4 concrete interpretations with AskUserQuestion, recommended first.
2. **Logs first:** errors in Output often explain "feel" bugs (e.g. a controller whose Init failed silently).
   Find the root cause before tuning numbers. Warnings about asset ids not in `src/` / `maps/` are usually avatar
   items — say so, don't chase them.
3. **Removed features:** when the owner removes something, delete its code and strings, and add it to "Removed —
   don't bring back unasked" in CLAUDE.md's Standing owner decisions.
4. Ship with the `ship-feature` skill (small lists = one PR; big ones = one PR per system).
5. In `docs/STUDIO_TESTING.md` add a dated playtest line: the owner's notes, what was fixed, what to re-check.
