# ⚡ OpenCode — Native Termux Setup

Standalone, self-contained setup of **OpenCode** for Termux / Android without relying on third-party authors, npm, glibc, or proot.

---

## 🚀 Features

- **No glibc & No proot:** Uses a custom native musl dynamic loader specifically patched to read DNS from Termux's `$PREFIX/etc/resolv.conf`.
- **No npm / Node.js required:** Pure standalone shell scripts and native binaries.
- **Direct Upstream:** Fetches official releases directly from `opencode.ai` and `anomalyco/opencode`.
- **Self-Contained & Portable:** The `prebuilt/` folder already contains all necessary runtime libraries and the latest binary. You can copy this folder to any new device and install offline!

---

## 📂 Project Structure

```
opencode-termux-v2/
├── install.sh      # 1-Click installer (sets up libraries, loader & wrapper)
├── update.sh       # 1-Click updater (directly pulls from opencode.ai)
├── test.sh         # Health check & diagnostics test
├── uninstall.sh    # Clean uninstaller
├── prebuilt/       # Prebuilt musl loader, patchelf, libstdc++, and OpenCode binary
└── README.md       # Documentation
```

---

## 🛠️ Usage

### 1. Install on this device / New device:
```bash
cd ~/opencode-termux-v2
bash install.sh
```

### 2. Update to the latest upstream OpenCode:
```bash
cd ~/opencode-termux-v2
bash update.sh
# or simply run from anywhere:
oct-up
```

### 3. Check health / Diagnostics:
```bash
cd ~/opencode-termux-v2
bash test.sh
```

### 4. Run OpenCode:
```bash
opencode
```

---

## 📱 How to move to a NEW device:

1. **Zip this folder on your current device:**
   ```bash
   cd ~
   tar czf opencode-termux.tar.gz opencode-termux-v2/
   ```
2. **Transfer `opencode-termux.tar.gz`** to your new phone (via Telegram, Drive, Bluetooth, SD Card, etc.).
3. **On the new phone (in Termux):**
   ```bash
   pkg update -y && pkg install -y tar
   tar xzf opencode-termux.tar.gz
   cd opencode-termux
   bash install.sh
   ```
That's it! Zero dependencies, zero manual setup.
