#!/usr/bin/env bash
# Installs the toolchain (versions from rokit.toml) in a claude.ai/code cloud session or any Linux x86_64 box where
# Rokit can't run. Cloud sessions block api.github.com (Rokit needs it) but allow release downloads, so this fetches
# the release zips directly; takes ~30 s. Also seeds Selene's Roblox std (Selene can't download Roblox's API list
# through the cloud proxy). Re-run it in a session older than 6 hours if `selene src` starts complaining.
# Usage: scripts/cloud-setup.sh   (installs into ~/.local/bin; make sure it's on PATH)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${HOME}/.local/bin"
mkdir -p "$BIN"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

version() { # version <tool> -> the version pinned in rokit.toml
	grep -E "^$1 = " "$ROOT/rokit.toml" | sed -E 's/.*@([^"]+)".*/\1/'
}

fetch() { # fetch <name> <url>
	local name="$1" url="$2"
	if command -v "$name" >/dev/null 2>&1 && [ "${FORCE:-0}" != "1" ]; then
		echo "have $name ($(command -v "$name"))"
		return
	fi
	echo "installing $name from $url"
	curl -fsSL "$url" -o "$TMP/$name.zip"
	unzip -o -q "$TMP/$name.zip" -d "$TMP/$name"
	install -m 755 "$(find "$TMP/$name" -type f -name "$name" | head -n 1)" "$BIN/$name"
}

ROJO="$(version rojo)"
SELENE="$(version selene)"
STYLUA="$(version stylua)"
LUNE="$(version lune)"
LSP="$(version luau-lsp)"

fetch rojo "https://github.com/rojo-rbx/rojo/releases/download/v${ROJO}/rojo-${ROJO}-linux-x86_64.zip"
fetch selene "https://github.com/Kampfkarren/selene/releases/download/${SELENE}/selene-${SELENE}-linux.zip"
fetch stylua "https://github.com/JohnnyMorganz/StyLua/releases/download/v${STYLUA}/stylua-linux-x86_64.zip"
fetch lune "https://github.com/lune-org/lune/releases/download/v${LUNE}/lune-${LUNE}-linux-x86_64.zip"
fetch luau-lsp "https://github.com/JohnnyMorganz/luau-lsp/releases/download/${LSP}/luau-lsp-linux-x86_64.zip"

# Selene's floating Roblox std, stamped as fresh (Selene refreshes it after 6 hours, which fails offline).
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/selene"
mkdir -p "$CACHE"
gunzip -c "$ROOT/tools/selene/roblox.yml.gz" |
	sed -E "s/^last_updated: .*/last_updated: $(date +%s)/; s/^last_selene_version: .*/last_selene_version: ${SELENE}/" \
		>"$CACHE/roblox.yml"
echo "seeded $CACHE/roblox.yml"

case ":$PATH:" in
*":$BIN:"*) ;;
*) echo "add $BIN to PATH: export PATH=\"$BIN:\$PATH\"" ;;
esac
