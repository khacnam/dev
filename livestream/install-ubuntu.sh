#!/bin/bash
# Installation script for Live Stream App on Ubuntu 22.04

set -e

echo "=========================================="
echo "Live Stream App - Ubuntu 22.04 Installer"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "⚠️  Cảnh báo: Không nên chạy script này với quyền root"
    echo "Vui lòng chạy với user thường và sẽ được yêu cầu sudo khi cần"
    exit 1
fi

# Update system
echo "📦 Cập nhật hệ thống..."
sudo apt update
sudo apt upgrade -y

# Install Node.js 18.x
echo "📦 Cài đặt Node.js..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
fi

echo "✅ Node.js version: $(node --version)"
echo "✅ NPM version: $(npm --version)"

# Install FFmpeg
echo "📦 Cài đặt FFmpeg..."
if ! command -v ffmpeg &> /dev/null; then
    sudo apt install -y ffmpeg
fi

echo "✅ FFmpeg version: $(ffmpeg -version | head -n1)"

# Install Git
echo "📦 Cài đặt Git..."
if ! command -v git &> /dev/null; then
    sudo apt install -y git
fi

# Install build tools
echo "📦 Cài đặt build tools..."
sudo apt install -y build-essential python3

# Install PM2 globally
echo "📦 Cài đặt PM2..."
if ! command -v pm2 &> /dev/null; then
    sudo npm install -g pm2
fi

# Create app directory
APP_DIR="/opt/livestream-app"
echo "📁 Tạo thư mục ứng dụng tại $APP_DIR..."
sudo mkdir -p $APP_DIR
sudo chown $USER:$USER $APP_DIR

# Copy files
echo "📁 Copy files..."
cp -r $(pwd)/* $APP_DIR/
cd $APP_DIR

# Install dependencies
echo "📦 Cài đặt dependencies..."
npm install --production

# Create .env file
if [ ! -f .env ]; then
    echo "⚙️  Tạo file .env..."

    # Get server IP
    SERVER_IP=$(curl -s ifconfig.me || echo "localhost")

    cat > .env << EOF
# Server Configuration
HTTP_PORT=3000
RTMP_PORT=1935

# Domain/IP của server
DOMAIN=$SERVER_IP

# JWT Secret Key
JWT_SECRET=$(openssl rand -base64 32)

# FFmpeg path
FFMPEG_PATH=/usr/bin/ffmpeg
EOF

    echo "✅ Đã tạo file .env với IP: $SERVER_IP"
fi

# Setup firewall
echo "🔥 Cấu hình firewall..."
sudo ufw allow 3000/tcp comment 'Live Stream HTTP'
sudo ufw allow 1935/tcp comment 'Live Stream RTMP'
sudo ufw allow 8000/tcp comment 'Live Stream HLS'
sudo ufw allow 22/tcp comment 'SSH'

# Ask to enable firewall
if ! sudo ufw status | grep -q "Status: active"; then
    read -p "Bật firewall? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "y" | sudo ufw enable
        echo "✅ Đã bật firewall"
    fi
fi

# Create systemd service (alternative to PM2)
echo "⚙️  Tạo systemd service..."
sudo tee /etc/systemd/system/livestream.service > /dev/null << EOF
[Unit]
Description=Live Stream Application
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$APP_DIR
Environment=NODE_ENV=production
ExecStart=/usr/bin/node $APP_DIR/server.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
sudo systemctl daemon-reload

echo ""
echo "=========================================="
echo "✅ Cài đặt hoàn tất!"
echo "=========================================="
echo ""
echo "📝 Các bước tiếp theo:"
echo ""
echo "1. Chỉnh sửa file .env nếu cần:"
echo "   nano $APP_DIR/.env"
echo ""
echo "2. Khởi động ứng dụng bằng PM2 (khuyên dùng):"
echo "   cd $APP_DIR"
echo "   pm2 start server.js --name livestream-app"
echo "   pm2 save"
echo "   pm2 startup"
echo ""
echo "   Hoặc dùng systemd:"
echo "   sudo systemctl start livestream"
echo "   sudo systemctl enable livestream"
echo ""
echo "3. Truy cập ứng dụng tại:"
echo "   http://$SERVER_IP:3000"
echo ""
echo "4. Ports đã mở:"
echo "   - 3000: HTTP Web Interface"
echo "   - 1935: RTMP Streaming"
echo "   - 8000: HLS Playback"
echo ""
echo "📚 Xem thêm hướng dẫn trong file README.md"
echo ""
