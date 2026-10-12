#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# opencode-termux: Diagnostics & Health Check
# ==============================================================================
set -euo pipefail

PREFIX="${TERMUX_PREFIX:-/data/data/com.termux/files/usr}"
LIBDIR="$PREFIX/lib/opencode-termux"
VENDOR_DIR="$LIBDIR/vendor"
BINDIR="$PREFIX/bin"

pass() { printf '  \033[1;32m✅ %s\033[0m\n' "$*"; }
fail() { printf '  \033[1;31m❌ %s\033[0m\n' "$*"; }

echo "🔍 Running OpenCode Diagnostics..."
ERRORS=0

# 1. Architecture
ARCH="$(uname -m)"
if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    pass "CPU Architecture: $ARCH (supported)"
else
    fail "CPU Architecture: $ARCH (requires 64-bit arm64)"
    ERRORS=$((ERRORS + 1))
fi

# 2. Binary existence
if [ -x "$VENDOR_DIR/opencode" ]; then
    pass "Vendor binary exists and executable"
else
    fail "Vendor binary missing at $VENDOR_DIR/opencode"
    ERRORS=$((ERRORS + 1))
fi

# 3. Dynamic loader
if [ -x "$VENDOR_DIR/ld-musl.so" ]; then
    pass "Custom musl loader exists"
else
    fail "Custom musl loader missing"
    ERRORS=$((ERRORS + 1))
fi

# 4. Libraries
for lib in libgcc_s.so.1 libstdc++.so.6 libc.musl-aarch64.so.1; do
    if [ -e "$VENDOR_DIR/$lib" ]; then
        pass "Library: $lib found"
    else
        fail "Library: $lib missing"
        ERRORS=$((ERRORS + 1))
    fi
done

# 5. DNS config
if [ -f "$PREFIX/etc/resolv.conf" ]; then
    pass "DNS resolv.conf configured ($PREFIX/etc/resolv.conf)"
else
    fail "DNS resolv.conf missing"
    ERRORS=$((ERRORS + 1))
fi

# 6. Wrapper in PATH
if command -v opencode >/dev/null 2>&1; then
    VER=$(opencode --version 2>&1 || echo "failed")
    pass "Command 'opencode' works: $VER"
else
    fail "'opencode' command not found in PATH"
    ERRORS=$((ERRORS + 1))
fi

echo "----------------------------------------"
if [ "$ERRORS" -eq 0 ]; then
    echo "🎉 All checks passed! OpenCode is 100% healthy."
else
    echo "⚠️ Found $ERRORS issues. Please re-run: bash install.sh"
fi
