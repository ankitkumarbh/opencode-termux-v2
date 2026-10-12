#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# opencode-termux: Clean Uninstaller
# ==============================================================================
set -euo pipefail

PREFIX="${TERMUX_PREFIX:-/data/data/com.termux/files/usr}"
LIBDIR="$PREFIX/lib/opencode-termux"
BINDIR="$PREFIX/bin"

say() { printf '\033[1;32m[opencode]\033[0m %s\n' "$*"; }

say "Uninstalling OpenCode Termux setup..."

rm -rf "$LIBDIR"
rm -f "$BINDIR/opencode-termux"

# Only remove opencode link if it was pointing to opencode-termux
if [ -L "$BINDIR/opencode" ]; then
    rm -f "$BINDIR/opencode"
fi

say "✅ OpenCode Termux binaries and libraries removed successfully."
say "Note: User configuration in ~/.config/opencode was kept intact."
