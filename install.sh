#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# opencode-termux: Standalone Native Installer for Termux (Android)
# Direct upstream support — No glibc, No proot, No author dependency.
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

say "Starting installation of OpenCode on Termux..."

# 1. Architecture Check
ARCH="$(uname -m)"
case "$ARCH" in
    aarch64|arm64) ARCH_NAME="arm64" ;;
    x86_64|amd64)  ARCH_NAME="x64" ;;
    *) err "Unsupported architecture: $ARCH (Requires 64-bit arm64 or x86_64)" ;;
esac

# 2. Prepare directories
mkdir -p "$VENDOR_DIR" "$BINDIR" "$LIBDIR/tmp"

# 3. Copy runtime libraries
say "Installing runtime libraries (musl loader & libstdc++)..."
for f in ld-musl.so libgcc_s.so.1 libstdc++.so.6 libstdc++.so.6.0.33 patchelf; do
    if [ -f "$SCRIPT_DIR/prebuilt/$f" ]; then
        cp -f "$SCRIPT_DIR/prebuilt/$f" "$VENDOR_DIR/$f"
        chmod +x "$VENDOR_DIR/$f"
    else
        err "Missing required prebuilt library: $f"
    fi
done

# Fix symlink for musl libc
rm -f "$VENDOR_DIR/libc.musl-${ARCH}.so.1" "$VENDOR_DIR/libc.musl-aarch64.so.1"
ln -sf "ld-musl.so" "$VENDOR_DIR/libc.musl-aarch64.so.1"

# 4. Install OpenCode binary
if [ -f "$SCRIPT_DIR/prebuilt/opencode" ]; then
    say "Using prebuilt OpenCode binary from local bundle..."
    cp -f "$SCRIPT_DIR/prebuilt/opencode" "$VENDOR_DIR/opencode"
else
    say "Fetching latest OpenCode binary from upstream (opencode.ai)..."
    LATEST_VER=$(curl -sL https://registry.npmjs.org/@opencode/cli/latest | grep -o '"version":"[^"]*"' | head -n1 | cut -d'"' -f4 || echo "2.0.26")
    say "Downloading OpenCode v${LATEST_VER}..."
    TMP_DL=$(mktemp -d -t oc-inst-XXXXXX)
    trap 'rm -rf "$TMP_DL"' EXIT
    curl -fsSL "https://opencode.ai/files/bin/${LATEST_VER}/opencode-linux-${ARCH_NAME}-musl.tar.gz" -o "$TMP_DL/oc.tgz"
    tar xzf "$TMP_DL/oc.tgz" -C "$TMP_DL"
    cp -f "$TMP_DL/opencode" "$VENDOR_DIR/opencode"
    rm -rf "$TMP_DL"
fi
chmod +x "$VENDOR_DIR/opencode"

# 5. Patch ELF interpreter to use native Termux musl loader
say "Patching ELF interpreter for native Termux execution..."
LOADER="$VENDOR_DIR/ld-musl.so"
PATCHER="$VENDOR_DIR/patchelf"
"$LOADER" --library-path "$VENDOR_DIR" "$PATCHER" --set-interpreter "$LOADER" "$VENDOR_DIR/opencode"

# 6. Ensure Termux DNS config (resolv.conf & hosts)
mkdir -p "$PREFIX/etc"
if [ ! -f "$PREFIX/etc/resolv.conf" ]; then
    printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > "$PREFIX/etc/resolv.conf"
fi
if [ ! -f "$PREFIX/etc/hosts" ]; then
    printf '127.0.0.1 localhost\n' > "$PREFIX/etc/hosts"
fi

# 7. Create CLI wrapper script
say "Creating launcher script ($BINDIR/opencode-termux)..."
cat << 'EOF' > "$BINDIR/opencode-termux"
#!/bin/sh
export LD_PRELOAD=
PREFIX="${TERMUX_PREFIX:-/data/data/com.termux/files/usr}"
LIBDIR="$PREFIX/lib/opencode-termux"
BIN="$LIBDIR/vendor/opencode"
export LD_LIBRARY_PATH="$LIBDIR/vendor${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export TMPDIR="${TMPDIR:-$LIBDIR/tmp}"
mkdir -p "$TMPDIR" 2>/dev/null || true

# Check if background service was already active before this run
WAS_RUNNING=0
INITIAL_STATUS=$("$BIN" service status 2>/dev/null)
if echo "$INITIAL_STATUS" | grep -q "http"; then
    WAS_RUNNING=1
fi

cleanup() {
    if [ "$WAS_RUNNING" -eq 0 ]; then
        "$BIN" service stop >/dev/null 2>&1 || true
        # Ensure any orphaned daemon is terminated
        pkill -u "$(id -u)" -f "$BIN serve" 2>/dev/null || true
    fi
}

trap cleanup EXIT INT TERM HUP

"$BIN" "$@"
EXIT_CODE=$?
exit $EXIT_CODE
EOF
chmod +x "$BINDIR/opencode-termux"
ln -sf "$BINDIR/opencode-termux" "$BINDIR/opencode"

# 8. Smoke test
say "Verifying installation..."
INSTALLED_VER=$("$BINDIR/opencode" --version 2>&1)
say "✅ Success! $INSTALLED_VER installed and verified."
say "You can now run: 'opencode' or 'opencode-termux'"
