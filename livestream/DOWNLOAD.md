# 📥 Download Live Stream App

Hướng dẫn download và cài đặt ứng dụng Live Stream.

## 🚀 Phương pháp 1: Download từ GitHub (Khuyên dùng)

### Option A: Clone với Git

```bash
# Clone repository
git clone https://github.com/khacnam/dev.git

# Vào thư mục livestream
cd dev/livestream

# Cài đặt dependencies
npm install

# Tạo file .env
cp .env.example .env
nano .env

# Chạy ứng dụng
npm start
```

### Option B: Download ZIP từ GitHub

1. Truy cập: https://github.com/khacnam/dev
2. Click nút **"Code"** (màu xanh)
3. Click **"Download ZIP"**
4. Giải nén file ZIP
5. Vào thư mục `livestream`
6. Làm theo hướng dẫn cài đặt

### Option C: Download branch cụ thể

```bash
# Download branch mới nhất
git clone -b claude/livestream-app-setup-011CUprwybY2DmvGDpMZ1ihG https://github.com/khacnam/dev.git

cd dev/livestream
npm install
```

---

## 🔗 Phương pháp 2: Download Archive

### Download toàn bộ repository

```bash
# Download master branch
wget https://github.com/khacnam/dev/archive/refs/heads/main.zip
unzip main.zip
cd dev-main/livestream

# Hoặc dùng curl
curl -L https://github.com/khacnam/dev/archive/refs/heads/main.zip -o livestream.zip
unzip livestream.zip
cd dev-main/livestream
```

### Download branch cụ thể

```bash
# Download branch với browser streaming
wget https://github.com/khacnam/dev/archive/refs/heads/claude/livestream-app-setup-011CUprwybY2DmvGDpMZ1ihG.zip

unzip claude-livestream-app-setup-011CUprwybY2DmvGDpMZ1ihG.zip
cd dev-claude-livestream-app-setup-011CUprwybY2DmvGDpMZ1ihG/livestream
```

---

## 📦 Phương pháp 3: One-liner Install

### Cài đặt tự động trên Ubuntu

```bash
# Download và chạy script cài đặt
curl -fsSL https://raw.githubusercontent.com/khacnam/dev/main/livestream/install-ubuntu.sh | bash

# Hoặc
wget -qO- https://raw.githubusercontent.com/khacnam/dev/main/livestream/install-ubuntu.sh | bash
```

### Manual install với wget

```bash
# Tạo thư mục
mkdir -p /opt/livestream-app
cd /opt/livestream-app

# Download files chính
wget https://raw.githubusercontent.com/khacnam/dev/main/livestream/package.json
wget https://raw.githubusercontent.com/khacnam/dev/main/livestream/server-enhanced.js
wget https://raw.githubusercontent.com/khacnam/dev/main/livestream/.env.example

# Download public files
mkdir -p public
cd public
wget https://raw.githubusercontent.com/khacnam/dev/main/livestream/public/index.html
wget https://raw.githubusercontent.com/khacnam/dev/main/livestream/public/dashboard.html
wget https://raw.githubusercontent.com/khacnam/dev/main/livestream/public/go-live.html
wget https://raw.githubusercontent.com/khacnam/dev/main/livestream/public/watch-enhanced.html
wget https://raw.githubusercontent.com/khacnam/dev/main/livestream/public/browse.html
wget https://raw.githubusercontent.com/khacnam/dev/main/livestream/public/admin.html

cd ..
npm install
```

---

## 🐳 Phương pháp 4: Docker

### Docker Hub (nếu có publish)

```bash
# Pull image
docker pull khacnam/livestream-app:latest

# Run container
docker run -d -p 3000:3000 -p 1935:1935 -p 8000:8000 khacnam/livestream-app
```

### Build từ source

```bash
# Clone repo
git clone https://github.com/khacnam/dev.git
cd dev/livestream

# Build image
docker build -t livestream-app .

# Run container
docker run -d -p 3000:3000 -p 1935:1935 -p 8000:8000 livestream-app
```

### Docker Compose

```bash
# Clone repo
git clone https://github.com/khacnam/dev.git
cd dev/livestream

# Start với docker-compose
docker-compose up -d
```

---

## 📋 Sau khi download

### 1. Cài đặt Dependencies

```bash
cd livestream
npm install
```

### 2. Cấu hình

```bash
# Copy .env example
cp .env.example .env

# Chỉnh sửa
nano .env
```

Cấu hình `.env`:
```env
HTTP_PORT=3000
RTMP_PORT=1935
DOMAIN=your-domain-or-ip
JWT_SECRET=your-random-secret-key
FFMPEG_PATH=/usr/bin/ffmpeg
```

### 3. Chạy ứng dụng

```bash
# Development
npm start

# Production với PM2
pm2 start server-enhanced.js --name livestream-app

# Production với Docker
docker-compose up -d
```

---

## 🎯 Quick Start

### Ubuntu/Debian:

```bash
# Install Node.js và FFmpeg
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs ffmpeg

# Clone project
git clone https://github.com/khacnam/dev.git
cd dev/livestream

# Setup
npm install
cp .env.example .env
nano .env  # Chỉnh DOMAIN và JWT_SECRET

# Run
npm start

# Truy cập http://localhost:3000
```

### Windows:

```bash
# Install Node.js từ https://nodejs.org
# Install FFmpeg từ https://ffmpeg.org

# Clone project
git clone https://github.com/khacnam/dev.git
cd dev\livestream

# Setup
npm install
copy .env.example .env
notepad .env

# Run
npm start
```

### macOS:

```bash
# Install Homebrew nếu chưa có
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Node.js và FFmpeg
brew install node ffmpeg

# Clone project
git clone https://github.com/khacnam/dev.git
cd dev/livestream

# Setup
npm install
cp .env.example .env
nano .env

# Run
npm start
```

---

## 📦 Download Individual Files

### Core Files:

```bash
# Server
wget https://raw.githubusercontent.com/khacnam/dev/main/livestream/server-enhanced.js

# Package.json
wget https://raw.githubusercontent.com/khacnam/dev/main/livestream/package.json

# Environment
wget https://raw.githubusercontent.com/khacnam/dev/main/livestream/.env.example
```

### Frontend:

```bash
# Login page
wget https://raw.githubusercontent.com/khacnam/dev/main/livestream/public/index.html

# Dashboard
wget https://raw.githubusercontent.com/khacnam/dev/main/livestream/public/dashboard.html

# Go Live (Browser streaming)
wget https://raw.githubusercontent.com/khacnam/dev/main/livestream/public/go-live.html

# Watch page with chat
wget https://raw.githubusercontent.com/khacnam/dev/main/livestream/public/watch-enhanced.html

# Browse streams
wget https://raw.githubusercontent.com/khacnam/dev/main/livestream/public/browse.html

# Admin panel
wget https://raw.githubusercontent.com/khacnam/dev/main/livestream/public/admin.html
```

### Documentation:

```bash
wget https://raw.githubusercontent.com/khacnam/dev/main/livestream/LIVESTREAM-README.md
wget https://raw.githubusercontent.com/khacnam/dev/main/livestream/QUICKSTART.md
wget https://raw.githubusercontent.com/khacnam/dev/main/livestream/DEPLOYMENT-GUIDE.md
wget https://raw.githubusercontent.com/khacnam/dev/main/livestream/BROWSER-STREAMING.md
wget https://raw.githubusercontent.com/khacnam/dev/main/livestream/SSL-SETUP.md
```

---

## 🔐 Security Notes

### Sau khi download:

1. **Change JWT_SECRET** trong `.env`
2. **Update DOMAIN** thành IP/domain thực của bạn
3. **Setup firewall** cho ports 3000, 1935, 8000
4. **Enable HTTPS** với Let's Encrypt (production)

---

## 📚 Documentation

Sau khi download, đọc các file sau:

1. **QUICKSTART.md** - Bắt đầu nhanh trong 5 phút
2. **LIVESTREAM-README.md** - Hướng dẫn đầy đủ
3. **DEPLOYMENT-GUIDE.md** - Deploy production
4. **BROWSER-STREAMING.md** - Tính năng Go Live
5. **SSL-SETUP.md** - Cài đặt HTTPS

---

## 🆘 Troubleshooting

### Git clone không được:

```bash
# Thử với HTTPS
git clone https://github.com/khacnam/dev.git

# Nếu vẫn không được, download ZIP
wget https://github.com/khacnam/dev/archive/refs/heads/main.zip
```

### npm install lỗi:

```bash
# Clear cache
npm cache clean --force

# Update npm
npm install -g npm@latest

# Try again
npm install
```

### Permission denied:

```bash
# Change ownership
sudo chown -R $USER:$USER /opt/livestream-app

# Or run with sudo
sudo npm install
```

---

## 📞 Support

- **GitHub**: https://github.com/khacnam/dev
- **Issues**: https://github.com/khacnam/dev/issues
- **Docs**: Xem các file .md trong thư mục

---

## ✅ Checklist

Sau khi download:

- [ ] Clone/download source code
- [ ] Cài đặt Node.js 18+
- [ ] Cài đặt FFmpeg
- [ ] Chạy `npm install`
- [ ] Tạo file `.env`
- [ ] Chỉnh sửa DOMAIN và JWT_SECRET
- [ ] Setup firewall
- [ ] Chạy application
- [ ] Test trên http://localhost:3000
- [ ] Đăng ký user đầu tiên
- [ ] Test streaming

---

**Chúc bạn download thành công! 🚀**
