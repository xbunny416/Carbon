---
name: store-art
description: Make the Roblox experience icon (512×512) and thumbnails (1920×1080) with tools/store-art (a three.js scene rendered in headless Chromium). Use when the owner asks for a logo, icon, thumbnail, game pass image, store page art, or "make it look more 3D".
---

# Store art

The owner wants a **3D Roblox look** (blocky characters with studs, real lighting and shadows, bold chunky title) —
flat vector art was rejected. They like to **choose from many variants** (e.g. 10 completely different styles), then
pick one; the pick becomes the icon too.

## Render

```sh
cd tools/store-art && npm install && mkdir -p out && node render.mjs out
```

- `scene.html`: the scene (characters, ground, props, lights, bloom) and the title (`title(...)` calls near the end —
  put the game's name there). `render.mjs`: opens it in Chromium (`/opt/pw-browsers/...` in cloud sessions; change
  `executablePath` locally) and saves `thumbnail.png` (1920×1080) and `icon-1024.png` (scale to 512×512).
- Use software GL flags (`--use-gl=angle --use-angle=swiftshader`) in headless containers.

## Variants

Make a table of styles (time of day / palette / sky / ground / props / camera layout: wide, close-up, low angle),
render each to `out/<n>-<name>.png`, send them all with SendUserFile, and ask which one (AskUserQuestion can't hold
10 options: list them numbered and let the owner answer by number). Look at every render yourself before sending:
check for washed-out bloom, cropped characters, characters facing away, hard horizon bands.

## Keep

Save the picked thumbnail and the matching 512 icon in `docs/store/` and note the choice in DECISIONS.md.
Only free assets / your own renders; never another game's art.
