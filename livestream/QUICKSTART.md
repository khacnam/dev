# 🚀 Quick Start Guide

Hướng dẫn nhanh để chạy ứng dụng Live Stream trong 5 phút!

## 📦 Cài đặt nhanh trên Ubuntu 22.04

```bash
# 1. Chạy script tự động
chmod +x install-ubuntu.sh
./install-ubuntu.sh

# 2. Khởi động ứng dụng
cd /opt/livestream-app
pm2 start server.js --name livestream-app
pm2 save

# 3. Truy cập
# http://YOUR_SERVER_IP:3000
```

## 🎯 Demo nhanh trên môi trường dev

```bash
# 1. Cài đặt dependencies
npm install

# 2. Tạo file .env
cp .env.example .env
# Chỉnh sửa DOMAIN thành IP của bạn

# 3. Start server
npm start

# 4. Mở browser
# http://localhost:3000
```

## 📱 Test ngay

### Bước 1: Đăng ký tài khoản
- Vào `http://your-ip:3000`
- Click "Đăng ký"
- Username: `test`
- Password: `test123`

### Bước 2: Lấy Stream Key
- Đăng nhập
- Vào Dashboard
- Copy **Stream Key** và **RTMP URL**

### Bước 3: Phát stream

#### Từ điện thoại:
1. Tải app **Larix Broadcaster** (miễn phí)
2. Settings → Connections → New Connection
3. Nhập:
   - Name: `My Stream`
   - URL: `rtmp://your-ip:1935/live`
   - Stream name: `[your-stream-key]`
4. Bấm nút phát stream

#### Từ OBS Studio:
1. Settings → Stream
2. Service: `Custom`
3. Server: `rtmp://your-ip:1935/live`
4. Stream Key: `[your-stream-key]`
5. Click "Start Streaming"

### Bước 4: Xem stream
- Copy link từ Dashboard (phần "Link để người xem truy cập")
- Mở link trong browser khác hoặc gửi cho bạn bè
- Stream sẽ tự động phát

## ⚡ One-liner Installation

```bash
curl -fsSL https://raw.githubusercontent.com/your-repo/main/install-ubuntu.sh | bash
```

## 🔍 Kiểm tra

```bash
# Kiểm tra server đang chạy
pm2 status

# Xem logs
pm2 logs livestream-app

# Test RTMP port
telnet your-ip 1935

# Test HTTP port
curl http://your-ip:3000
```

## ❓ Troubleshooting nhanh

### Không kết nối được?
```bash
# Kiểm tra firewall
sudo ufw status

# Mở ports
sudo ufw allow 3000/tcp
sudo ufw allow 1935/tcp
sudo ufw allow 8000/tcp
```

### Port bị chiếm?
```bash
# Tìm process đang dùng port
sudo lsof -i :3000
sudo lsof -i :1935

# Kill process
sudo kill -9 [PID]
```

### FFmpeg không tìm thấy?
```bash
# Cài FFmpeg
sudo apt install ffmpeg -y

# Kiểm tra
ffmpeg -version
```

## 📖 Đọc thêm

- Chi tiết: [LIVESTREAM-README.md](LIVESTREAM-README.md)
- API Docs: Xem trong README
- Issues: Tạo issue trên GitHub

---

**Chúc bạn thành công! 🎉**
