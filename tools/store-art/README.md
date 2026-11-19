# Store art (icon + thumbnail)

`scene.html` is a three.js scene (Roblox-style blocky characters, studs, lighting, shadows, bloom) with the title drawn
on top; `render.mjs` opens it in headless Chromium and saves two screenshots.

```sh
cd tools/store-art
npm install
mkdir -p out && node render.mjs out        # out/thumbnail.png (1920x1080) and out/icon-1024.png
# the icon is icon-1024.png scaled down to 512x512 (Pillow: Image.resize((512, 512), Image.LANCZOS))
```

`render.mjs` expects Chromium at `/opt/pw-browsers/chromium-1194/chrome-linux/chrome`; change `executablePath` if yours
is elsewhere. Set the name and tagline (`TITLE_TOP`, `TITLE_BOTTOM`, `TAGLINE` in `scene.html`), change colors,
poses, props or camera there and re-render. The scene came from Brawl Arena (fighters on a scrap heap): restyle it for this game. Keep the
picked files in `docs/store/`.
