# 🔗 Quick Download Links - Live Stream App

## 📥 Download Source Code

### Option 1: GitHub Web Interface (Đơn giản nhất)

1. **Truy cập repository:**
   ```
   https://github.com/khacnam/dev
   ```

2. **Click nút "Code" (màu xanh)**

3. **Chọn "Download ZIP"**

4. **Giải nén và vào thư mục `livestream`**

---

### Option 2: Git Clone (Khuyên dùng)

```bash
# Clone toàn bộ repository
git clone https://github.com/khacnam/dev.git

# Vào thư mục livestream
cd dev/livestream

# Cài đặt
npm install
```

---

### Option 3: Download ZIP trực tiếp

**Main branch:**
```bash
wget https://github.com/khacnam/dev/archive/refs/heads/main.zip
unzip main.zip
cd dev-main/livestream
```

**Branch với Browser Streaming (mới nhất):**
```bash
wget https://github.com/khacnam/dev/archive/refs/heads/claude/livestream-app-setup-011CUprwybY2DmvGDpMZ1ihG.zip
unzip claude-livestream-app-setup-011CUprwybY2DmvGDpMZ1ihG.zip
cd dev-claude-livestream-app-setup-011CUprwybY2DmvGDpMZ1ihG/livestream
```

---

### Option 4: Curl Download

```bash
curl -L https://github.com/khacnam/dev/archive/refs/heads/main.zip -o livestream.zip
unzip livestream.zip
cd dev-main/livestream
```

---

## 🚀 One-Command Install

### Ubuntu 22.04:

```bash
# Clone và cài đặt trong một lệnh
git clone https://github.com/khacnam/dev.git && \
cd dev/livestream && \
npm install && \
cp .env.example .env && \
echo "✅ Cài đặt xong! Chỉnh sửa .env rồi chạy: npm start"
```

### Với auto-install script:

```bash
# Download và chạy script tự động
curl -fsSL https://raw.githubusercontent.com/khacnam/dev/main/livestream/install-ubuntu.sh | bash
```

---

## 📦 Direct File Downloads

### Core Files:

```bash
# Tạo thư mục
mkdir -p livestream-app && cd livestream-app

# Download server
curl -O https://raw.githubusercontent.com/khacnam/dev/main/livestream/server-enhanced.js

# Download package.json
curl -O https://raw.githubusercontent.com/khacnam/dev/main/livestream/package.json

# Download .env example
curl -O https://raw.githubusercontent.com/khacnam/dev/main/livestream/.env.example

# Download public files
mkdir -p public && cd public
curl -O https://raw.githubusercontent.com/khacnam/dev/main/livestream/public/index.html
curl -O https://raw.githubusercontent.com/khacnam/dev/main/livestream/public/dashboard.html
curl -O https://raw.githubusercontent.com/khacnam/dev/main/livestream/public/go-live.html
curl -O https://raw.githubusercontent.com/khacnam/dev/main/livestream/public/watch-enhanced.html
curl -O https://raw.githubusercontent.com/khacnam/dev/main/livestream/public/browse.html
curl -O https://raw.githubusercontent.com/khacnam/dev/main/livestream/public/admin.html

cd ..
npm install
```

---

## 📚 Documentation Downloads

```bash
# Main README
curl -O https://raw.githubusercontent.com/khacnam/dev/main/livestream/LIVESTREAM-README.md

# Quick Start
curl -O https://raw.githubusercontent.com/khacnam/dev/main/livestream/QUICKSTART.md

# Deployment Guide
curl -O https://raw.githubusercontent.com/khacnam/dev/main/livestream/DEPLOYMENT-GUIDE.md

# Browser Streaming
curl -O https://raw.githubusercontent.com/khacnam/dev/main/livestream/BROWSER-STREAMING.md

# SSL Setup
curl -O https://raw.githubusercontent.com/khacnam/dev/main/livestream/SSL-SETUP.md

# Download Guide
curl -O https://raw.githubusercontent.com/khacnam/dev/main/livestream/DOWNLOAD.md
```

---

## 🐳 Docker

```bash
# Clone repo
git clone https://github.com/khacnam/dev.git
cd dev/livestream

# Build và run
docker-compose up -d
```

---

## 📋 Checksums

### Verify download integrity:

Sau khi download, verify với Git:
```bash
cd dev/livestream
git log --oneline -1
# Should show: 091b913 Add browser-based streaming (Go Live from Browser)
```

---

## 🎯 Quick Start After Download

```bash
# 1. Cài dependencies
npm install

# 2. Tạo .env
cp .env.example .env
nano .env

# 3. Chỉnh trong .env:
# - DOMAIN=your-ip-or-domain
# - JWT_SECRET=random-secret-key

# 4. Run
npm start

# 5. Open browser
# http://localhost:3000
```

---

## 🔗 Important Links

| Link | URL |
|------|-----|
| **GitHub Repo** | https://github.com/khacnam/dev |
| **Main Branch ZIP** | https://github.com/khacnam/dev/archive/refs/heads/main.zip |
| **Latest Branch** | https://github.com/khacnam/dev/tree/claude/livestream-app-setup-011CUprwybY2DmvGDpMZ1ihG |
| **Raw Files** | https://raw.githubusercontent.com/khacnam/dev/main/livestream/ |
| **Issues** | https://github.com/khacnam/dev/issues |

---

## 💡 Tips

### Fastest Download:

```bash
# Git clone (nếu có git)
git clone --depth 1 https://github.com/khacnam/dev.git

# Wget (nếu không có git)
wget https://github.com/khacnam/dev/archive/refs/heads/main.zip && unzip main.zip
```

### Minimal Download:

Nếu chỉ cần chạy, download minimal files:
```bash
mkdir livestream && cd livestream
curl -O https://raw.githubusercontent.com/khacnam/dev/main/livestream/package.json
curl -O https://raw.githubusercontent.com/khacnam/dev/main/livestream/server-enhanced.js
curl -O https://raw.githubusercontent.com/khacnam/dev/main/livestream/.env.example
mkdir public && cd public
# Download 6 HTML files như trên
```

---

## 🆘 Troubleshooting

### Can't access GitHub?

Alternative download sources (if you host elsewhere):
```bash
# Mirror 1
curl -L https://your-mirror.com/livestream.zip

# Mirror 2
wget https://another-mirror.com/livestream.tar.gz
```

### Slow download?

Use GitHub release (if created):
```
https://github.com/khacnam/dev/releases
```

---

## ✅ Verification Steps

After download:

```bash
# Check files exist
ls -la

# Should see:
# - server-enhanced.js
# - package.json
# - public/
# - LIVESTREAM-README.md
# etc.

# Check package.json
cat package.json | grep '"name"'
# Should show: "livestream-app"

# Check version
cat package.json | grep '"version"'
# Should show: "1.0.0"
```

---

## 📞 Need Help?

1. **Read docs first:**
   - QUICKSTART.md
   - LIVESTREAM-README.md

2. **Check issues:**
   https://github.com/khacnam/dev/issues

3. **Create new issue:**
   https://github.com/khacnam/dev/issues/new

---

**Happy streaming! 🎉**

*Last updated: 2025-11-06*
