# 🛠️ Prebuilt musl Loader Rebuild Guide

This guide explains how `ld-musl.so` was compiled and how you can rebuild it from scratch if needed.

---

## 🎯 Why is a Custom musl Loader Needed?

Standard Linux musl libc looks for DNS and networking files in:
* `/etc/resolv.conf`
* `/etc/hosts`

In non-rooted Android / Termux:
1. `/etc` is read-only or managed by Android seccomp/Bionic.
2. Standard users cannot create or edit `/etc/resolv.conf`.
3. Termux stores its user-accessible configs in:
   * `/data/data/com.termux/files/usr/etc/resolv.conf`
   * `/data/data/com.termux/files/usr/etc/hosts`

The custom `ld-musl.so` is compiled with these patched paths so **DNS resolution works natively in Termux without root and without proot**.

---

## 🏗️ How to Rebuild `ld-musl.so`

### Method 1: Using Docker (Cleanest & Recommended)

You can run this on any PC / Linux system (x86_64 or arm64):

```dockerfile
# Dockerfile
FROM alpine:3.21 AS builder
RUN apk add --no-cache build-base linux-headers git

WORKDIR /build
RUN git clone https://git.musl-libc.org/git/musl . && git checkout v1.2.5

# Patch DNS & hosts paths to Termux prefix
RUN find src/ -type f -name "*.c" -exec sed -i \
    -e 's|/etc/resolv.conf|/data/data/com.termux/files/usr/etc/resolv.conf|g' \
    -e 's|/etc/hosts|/data/data/com.termux/files/usr/etc/hosts|g' {} +

# Configure and compile
RUN ./configure --prefix=/out --target=aarch64-linux-musl --syslibdir=/out/lib
RUN make -j$(nproc) && make install

FROM scratch
COPY --from=builder /out/lib/ld-musl-aarch64.so.1 /ld-musl.so
```

Build and extract the binary:
```bash
docker build -t musl-termux-builder .
docker create --name extract-box musl-termux-builder
docker cp extract-box:/ld-musl.so ./prebuilt/ld-musl.so
docker rm extract-box
```

---

### Method 2: Native Build on Linux / Alpine ARM64

If you are running directly on an ARM64 Linux machine:

```bash
# 1. Install prerequisites
sudo apt-get update && sudo apt-get install -y build-essential git
# or on Alpine: apk add build-base git

# 2. Clone musl
git clone https://git.musl-libc.org/git/musl
cd musl
git checkout v1.2.5

# 3. Apply Termux DNS path patch
find src/ -type f -name "*.c" -exec sed -i \
    -e 's|/etc/resolv.conf|/data/data/com.termux/files/usr/etc/resolv.conf|g' \
    -e 's|/etc/hosts|/data/data/com.termux/files/usr/etc/hosts|g' {} +

# 4. Configure & Compile
./configure --prefix=/tmp/musl-out --syslibdir=/tmp/musl-out/lib
make -j$(nproc)
make install

# 5. Copy the loader
cp /tmp/musl-out/lib/ld-musl-aarch64.so.1 path/to/opencode-termux-v2/prebuilt/ld-musl.so
chmod +x path/to/opencode-termux-v2/prebuilt/ld-musl.so
```

---

## 🔍 How to Verify the Built Loader

Check file architecture:
```bash
file prebuilt/ld-musl.so
# Expected output:
# ELF 64-bit LSB shared object, ARM aarch64, version 1 (SYSV), dynamically linked
```

Check if patched Termux paths are present inside the binary:
```bash
strings prebuilt/ld-musl.so | grep -E 'resolv.conf|hosts'
# Expected output:
# /data/data/com.termux/files/usr/etc/resolv.conf
# /data/data/com.termux/files/usr/etc/hosts
```

---

## 📦 Updating Supporting Libraries (`libstdc++`, `libgcc`, `patchelf`)

If Alpine Linux releases a newer major version (e.g., Alpine 3.22/3.23), you can download the updated musl packages directly from Alpine CDN:

```bash
# Example for Alpine main aarch64 repo:
ALPINE_URL="https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/aarch64"

# Download packages
curl -LO "${ALPINE_URL}/libgcc-*.apk"
curl -LO "${ALPINE_URL}/libstdc++-*.apk"
curl -LO "${ALPINE_URL}/patchelf-*.apk"

# Extract using tar
tar -xzf libgcc-*.apk usr/lib/libgcc_s.so.1
tar -xzf libstdc++-*.apk usr/lib/libstdc++.so.6*
tar -xzf patchelf-*.apk usr/bin/patchelf

# Move into prebuilt/
mv usr/lib/libgcc_s.so.1 prebuilt/
mv usr/lib/libstdc++.so.* prebuilt/
mv usr/bin/patchelf prebuilt/
rm -rf usr/
```
