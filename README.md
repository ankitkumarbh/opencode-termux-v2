# ⚡ OpenCode — Native Termux Setup

Standalone, self-contained setup of **OpenCode** for Termux / Android without relying on third-party authors, npm, glibc, or proot.

---

## 🚀 Features

- **No glibc & No proot:** Uses a custom native musl dynamic loader specifically patched to read DNS from Termux's `$PREFIX/etc/resolv.conf`.
- **No npm / Node.js required:** Pure standalone shell scripts and native binaries.
- **Direct Upstream:** Fetches official releases directly from `opencode.ai` and `anomalyco/opencode`.
- **Lightweight Git Repo:** The repository only contains the essential musl loader and runtime libraries (~6.6MB). The 200MB binary is downloaded and patched automatically on the user's machine on demand.

---

## 📂 Project Structure

```
opencode-termux-v2/
├── install.sh      # 1-Click installer (sets up libraries, loader & wrapper)
├── update.sh       # 1-Click updater (directly pulls from opencode.ai)
├── test.sh         # Health check & diagnostics test
├── uninstall.sh    # Clean uninstaller
├── prebuilt/       # Prebuilt musl loader, patchelf, libstdc++
└── README.md       # Documentation
```

---

## 📥 Quick Install on any device:

```bash
git clone https://github.com/ankitkumarbh/opencode-termux-v2.git
cd opencode-termux-v2
bash install.sh
```

---

## 🛠️ Usage

### 1. Run OpenCode:
```bash
opencode
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

### 4. Uninstall:
```bash
cd ~/opencode-termux-v2
bash uninstall.sh
```
