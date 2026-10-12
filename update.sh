#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# opencode-termux: Upstream Updater
# Directly fetches new OpenCode releases from opencode.ai
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
PREFIX="${TERMUX_PREFIX:-/data/data/com.termux/files/usr}"
LIBDIR="$PREFIX/lib/opencode-termux"
VENDOR_DIR="$LIBDIR/vendor"
BINDIR="$PREFIX/bin"

say() { printf '\033[1;32m[opencode]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[opencode]\033[0m ⚠️ %s\n' "$*"; }
err() { printf '\033[1;31m[opencode]\033[0m ❌ %s\n' "$*" >&2; exit 1; }

say "Checking for upstream OpenCode updates..."

ARCH="$(uname -m)"
case "$ARCH" in
    aarch64|arm64) ARCH_NAME="arm64" ;;
    x86_64|amd64)  ARCH_NAME="x64" ;;
    *) err "Unsupported architecture: $ARCH" ;;
esac

LATEST_VER=$(curl -sL https://registry.npmjs.org/@opencode/cli/latest | grep -o '"version":"[^"]*"' | head -n1 | cut -d'"' -f4 || echo "")
if [ -z "$LATEST_VER" ]; then
    err "Failed to connect or fetch latest version metadata."
fi

CURRENT_VER=$("$BINDIR/opencode" --version 2>/dev/null | awk '{print $2}' || echo "unknown")
say "Current installed version : $CURRENT_VER"
say "Latest upstream version   : v$LATEST_VER"

if [ "$CURRENT_VER" = "v$LATEST_VER" ]; then
    say "✅ OpenCode is already up to date ($CURRENT_VER)!"
    exit 0
fi

say "⬇️ Downloading OpenCode v$LATEST_VER from opencode.ai..."
TMP_DIR=$(mktemp -d -t oc-update-XXXXXX)
trap 'rm -rf "$TMP_DIR"' EXIT

URL="https://opencode.ai/files/bin/${LATEST_VER}/opencode-linux-${ARCH_NAME}-musl.tar.gz"
curl -fsSL "$URL" -o "$TMP_DIR/oc.tgz" || err "Failed to download $URL"

say "Extracting and patching binary..."
tar xzf "$TMP_DIR/oc.tgz" -C "$TMP_DIR"

LOADER="$VENDOR_DIR/ld-musl.so"
PATCHER="$VENDOR_DIR/patchelf"

"$LOADER" --library-path "$VENDOR_DIR" "$PATCHER" --set-interpreter "$LOADER" "$TMP_DIR/opencode"

# Replace binary in vendor directory
mv -f "$TMP_DIR/opencode" "$VENDOR_DIR/opencode"
chmod +x "$VENDOR_DIR/opencode"

# Also update the local prebuilt copy if prebuilt exists
if [ -d "$SCRIPT_DIR/prebuilt" ]; then
    cp -f "$VENDOR_DIR/opencode" "$SCRIPT_DIR/prebuilt/opencode"
fi

say "✅ Update complete! Now running: $("$BINDIR/opencode" --version)"
