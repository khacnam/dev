# 🎥 Live Stream App

Ứng dụng phát trực tiếp (live streaming) đơn giản với xác thực người dùng, cho phép phát trực tiếp từ điện thoại và chia sẻ link xem stream.

## ✨ Tính năng

- ✅ Đăng ký/Đăng nhập người dùng
- ✅ Tạo Stream Key riêng cho mỗi người dùng
- ✅ Phát trực tiếp qua RTMP (từ điện thoại hoặc máy tính)
- ✅ Xem stream qua HLS (tương thích mọi thiết bị)
- ✅ Chia sẻ link để người khác xem
- ✅ Dashboard quản lý stream
- ✅ Theo dõi trạng thái stream (Live/Offline)

## 🛠️ Công nghệ sử dụng

- **Backend**: Node.js + Express
- **Streaming**: Node Media Server (RTMP + HLS)
- **Database**: SQLite
- **Authentication**: JWT + bcrypt
- **Video Player**: Video.js

## 📋 Yêu cầu hệ thống

- Ubuntu 22.04 (hoặc tương tự)
- Node.js 18.x trở lên
- FFmpeg
- Tối thiểu 2GB RAM
- Port 3000, 1935, 8000 cần được mở

## 🚀 Cài đặt

### Cài đặt tự động trên Ubuntu 22.04

```bash
# Clone repository
git clone <your-repo-url>
cd livestream

# Chạy script cài đặt
chmod +x install-ubuntu.sh
./install-ubuntu.sh
```

### Cài đặt thủ công

#### 1. Cài đặt Node.js và FFmpeg

```bash
# Cập nhật hệ thống
sudo apt update && sudo apt upgrade -y

# Cài đặt Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Cài đặt FFmpeg
sudo apt install -y ffmpeg

# Cài đặt build tools
sudo apt install -y build-essential python3
```

#### 2. Cài đặt ứng dụng

```bash
# Clone và di chuyển vào thư mục
cd /opt
sudo mkdir livestream-app
sudo chown $USER:$USER livestream-app
cd livestream-app

# Copy files vào đây
# Hoặc clone từ git repository

# Cài đặt dependencies
npm install
```

#### 3. Cấu hình

```bash
# Copy và chỉnh sửa file .env
cp .env.example .env
nano .env
```

Chỉnh sửa các giá trị trong file `.env`:

```env
HTTP_PORT=3000
RTMP_PORT=1935
DOMAIN=your-server-ip-or-domain.com
JWT_SECRET=your-random-secret-key
FFMPEG_PATH=/usr/bin/ffmpeg
```

#### 4. Cấu hình Firewall

```bash
# Mở các port cần thiết
sudo ufw allow 3000/tcp
sudo ufw allow 1935/tcp
sudo ufw allow 8000/tcp
sudo ufw allow 22/tcp

# Bật firewall (nếu chưa bật)
sudo ufw enable
```

## 🎬 Khởi động ứng dụng

### Sử dụng PM2 (Khuyên dùng cho production)

```bash
# Cài đặt PM2
sudo npm install -g pm2

# Khởi động ứng dụng
pm2 start server.js --name livestream-app

# Lưu cấu hình PM2
pm2 save

# Tự động khởi động khi server reboot
pm2 startup
# Chạy lệnh mà PM2 đưa ra

# Các lệnh PM2 hữu ích
pm2 status              # Xem trạng thái
pm2 logs livestream-app # Xem logs
pm2 restart livestream-app  # Restart
pm2 stop livestream-app     # Stop
```

### Sử dụng Node trực tiếp

```bash
# Development
npm start

# Production
NODE_ENV=production node server.js
```

### Sử dụng systemd

```bash
# Start service
sudo systemctl start livestream

# Enable auto-start
sudo systemctl enable livestream

# Check status
sudo systemctl status livestream

# View logs
sudo journalctl -u livestream -f
```

## 📱 Hướng dẫn sử dụng

### Cho người phát stream (Broadcaster)

1. **Đăng ký tài khoản**
   - Truy cập: `http://your-server-ip:3000`
   - Đăng ký tài khoản mới

2. **Lấy thông tin stream**
   - Đăng nhập và vào Dashboard
   - Copy **RTMP Server URL** và **Stream Key**

3. **Phát stream từ điện thoại**

   **Apps khuyên dùng:**
   - **Larix Broadcaster** (iOS/Android) - Miễn phí, dễ dùng
   - **Streamlabs Mobile** (iOS/Android)
   - **Prism Live Studio** (iOS/Android)

   **Cài đặt trong app:**
   - RTMP URL: `rtmp://your-server-ip:1935/live`
   - Stream Key: `[your-stream-key-from-dashboard]`

4. **Phát stream từ máy tính**

   **Sử dụng OBS Studio:**
   - Download: https://obsproject.com/
   - Settings → Stream
   - Service: Custom
   - Server: `rtmp://your-server-ip:1935/live`
   - Stream Key: `[your-stream-key]`

5. **Chia sẻ link**
   - Copy "Link để người xem truy cập" từ Dashboard
   - Gửi link cho người xem

### Cho người xem (Viewer)

1. Nhận link từ người phát stream
2. Mở link trong trình duyệt
3. Xem stream (không cần đăng nhập)

## 🏗️ Cấu trúc thư mục

```
livestream-app/
├── server.js              # Main server file
├── package.json           # Dependencies
├── .env                   # Configuration
├── .env.example          # Example configuration
├── install-ubuntu.sh     # Auto installation script
├── LIVESTREAM-README.md  # Documentation
├── public/               # Frontend files
│   ├── index.html       # Login/Register page
│   ├── dashboard.html   # User dashboard
│   └── watch.html       # Stream viewer page
├── media/               # HLS segments (auto-created)
└── livestream.db        # SQLite database (auto-created)
```

## 🔧 API Endpoints

### Authentication

- `POST /api/register` - Đăng ký user mới
- `POST /api/login` - Đăng nhập
- `POST /api/logout` - Đăng xuất
- `GET /api/user` - Lấy thông tin user (yêu cầu token)

### Streaming

- `GET /api/stream-info` - Lấy thông tin stream của user (yêu cầu token)
- `GET /api/stream/:streamKey/status` - Kiểm tra trạng thái stream
- `GET /api/streams/live` - Lấy danh sách streams đang live

### Streaming URLs

- RTMP Publish: `rtmp://domain:1935/live/{streamKey}`
- HLS Playback: `http://domain:8000/live/{streamKey}.m3u8`
- Web Viewer: `http://domain:3000/watch/{streamKey}`

## 🔐 Bảo mật

- Mật khẩu được hash bằng bcrypt
- Authentication sử dụng JWT
- Stream key unique cho mỗi user
- RTMP publish yêu cầu stream key hợp lệ

## 🐛 Troubleshooting

### Stream không phát được

1. Kiểm tra firewall đã mở ports chưa:
   ```bash
   sudo ufw status
   ```

2. Kiểm tra FFmpeg đã cài đặt:
   ```bash
   ffmpeg -version
   ```

3. Xem logs:
   ```bash
   pm2 logs livestream-app
   # hoặc
   sudo journalctl -u livestream -f
   ```

### Không xem được stream

1. Kiểm tra stream đã live chưa trên Dashboard
2. Thử refresh trang xem stream
3. Kiểm tra browser console để xem lỗi
4. Thử trình duyệt khác (Chrome/Firefox khuyên dùng)

### Port đã được sử dụng

```bash
# Kiểm tra port đang sử dụng
sudo netstat -tlnp | grep -E ':(3000|1935|8000)'

# Kill process đang dùng port
sudo kill -9 [PID]
```

## 📊 Giám sát

### Xem logs

```bash
# PM2
pm2 logs livestream-app

# Systemd
sudo journalctl -u livestream -f

# Node.js direct
# Logs sẽ in ra console
```

### Monitor resources

```bash
# PM2
pm2 monit

# System resources
htop
```

## 🔄 Cập nhật ứng dụng

```bash
cd /opt/livestream-app

# Pull latest code
git pull

# Install dependencies
npm install

# Restart application
pm2 restart livestream-app
# hoặc
sudo systemctl restart livestream
```

## 🌐 Production Tips

1. **Sử dụng domain thay vì IP**
   - Trỏ domain về server IP
   - Cập nhật `DOMAIN` trong `.env`

2. **Sử dụng HTTPS**
   - Cài đặt Nginx reverse proxy
   - Cài đặt SSL certificate (Let's Encrypt)

3. **Tối ưu hóa**
   - Tăng RAM nếu có nhiều viewers
   - Sử dụng CDN cho HLS segments
   - Cân nhắc dùng external storage

4. **Backup**
   - Backup file `livestream.db` định kỳ
   - Backup file `.env`

## 📝 License

MIT License

## 🤝 Đóng góp

Mọi đóng góp đều được chào đón! Vui lòng tạo Pull Request hoặc Issue.

## 📞 Hỗ trợ

Nếu gặp vấn đề, vui lòng:
1. Kiểm tra phần Troubleshooting
2. Xem logs để tìm lỗi
3. Tạo Issue trên GitHub

---

**Chúc bạn streaming vui vẻ! 🎉**
