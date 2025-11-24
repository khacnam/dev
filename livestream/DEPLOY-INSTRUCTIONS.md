# 🚀 Hướng dẫn Deploy lên Server

## Phương pháp 1: Script Tự động (KHUYÊN DÙNG)

### Yêu cầu:
- Server Ubuntu 22.04 hoặc 20.04
- Root access hoặc sudo
- Domain đã trỏ về server IP (optional, nhưng khuyên dùng)

### Các bước:

#### 1. SSH vào server

```bash
ssh root@your-server-ip
# hoặc
ssh ubuntu@your-server-ip
```

#### 2. Download và chạy script

```bash
# Download script
wget https://raw.githubusercontent.com/khacnam/dev/main/livestream/deploy-server.sh

# Make executable
chmod +x deploy-server.sh

# Run as root
sudo bash deploy-server.sh
```

#### 3. Nhập thông tin khi được hỏi

Script sẽ hỏi:
- **Server IP or Domain**: Nhập IP hoặc domain của bạn
- **Admin email**: Email để nhận thông báo SSL
- **Admin username**: Username cho admin account
- **Admin password**: Password cho admin account

#### 4. Đợi script chạy

Script sẽ tự động:
- ✅ Update system
- ✅ Install Node.js 18.x
- ✅ Install FFmpeg
- ✅ Install PM2
- ✅ Install Nginx
- ✅ Clone source code
- ✅ Install dependencies
- ✅ Configure .env
- ✅ Setup firewall
- ✅ Configure Nginx
- ✅ Request SSL certificate (nếu có domain)
- ✅ Start application
- ✅ Create admin user

#### 5. Hoàn tất!

Truy cập:
```
http://your-domain.com
hoặc
https://your-domain.com (nếu có SSL)
```

---

## Phương pháp 2: Manual Step-by-Step

### Bước 1: Chuẩn bị Server

```bash
# SSH vào server
ssh root@your-server-ip

# Update system
apt update && apt upgrade -y

# Install Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# Install FFmpeg
apt install -y ffmpeg

# Install tools
apt install -y build-essential python3 git

# Install PM2
npm install -g pm2
```

### Bước 2: Clone và Setup

```bash
# Create directory
mkdir -p /opt/livestream-app
cd /opt/livestream-app

# Clone repo
git clone https://github.com/khacnam/dev.git .
cd livestream

# Install dependencies
npm install --production

# Create .env
cp .env.example .env
nano .env
```

Chỉnh sửa `.env`:
```env
DOMAIN=your-domain.com
JWT_SECRET=$(openssl rand -base64 32)
```

### Bước 3: Firewall

```bash
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000/tcp
ufw allow 1935/tcp
ufw allow 8000/tcp
ufw enable
```

### Bước 4: Start App

```bash
pm2 start server-enhanced.js --name livestream-app
pm2 save
pm2 startup
```

### Bước 5: Nginx (Optional)

```bash
# Install Nginx
apt install -y nginx

# Create config
nano /etc/nginx/sites-available/livestream
```

Paste config từ file `nginx.conf`

```bash
# Enable site
ln -s /etc/nginx/sites-available/livestream /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default

# Test and restart
nginx -t
systemctl restart nginx
```

### Bước 6: SSL (Optional)

```bash
# Install Certbot
apt install -y certbot python3-certbot-nginx

# Get certificate
certbot --nginx -d your-domain.com

# Auto renewal is configured automatically
```

---

## Phương pháp 3: Docker Deploy

```bash
# SSH to server
ssh root@your-server-ip

# Install Docker
curl -fsSL https://get.docker.com | sh
apt install -y docker-compose

# Clone repo
git clone https://github.com/khacnam/dev.git
cd dev/livestream

# Create .env
cp .env.example .env
nano .env

# Start with Docker
docker-compose up -d

# Check logs
docker-compose logs -f
```

---

## 📋 Thông tin Cần thiết

### Server Requirements:
- **OS**: Ubuntu 22.04 LTS (khuyên dùng)
- **CPU**: 2 cores minimum
- **RAM**: 2GB minimum (4GB khuyên dùng)
- **Storage**: 20GB minimum
- **Network**: Public IP address

### Domain Setup (Optional nhưng khuyên dùng):

1. Mua domain (Namecheap, Cloudflare, etc.)
2. Tạo A Record trỏ về server IP:
   ```
   Type: A
   Name: @ (hoặc subdomain)
   Value: your-server-ip
   TTL: 300
   ```
3. Đợi DNS propagate (5-30 phút)
4. Test: `ping your-domain.com`

### Ports cần mở:

| Port | Service | Required |
|------|---------|----------|
| 22 | SSH | Yes |
| 80 | HTTP | Yes |
| 443 | HTTPS | Recommended |
| 3000 | App HTTP | Yes (if no Nginx) |
| 1935 | RTMP | Yes |
| 8000 | HLS | Yes |

---

## ✅ Verification

### Check services:

```bash
# PM2 status
pm2 status

# Nginx status
systemctl status nginx

# App logs
pm2 logs livestream-app

# Check ports
netstat -tlnp | grep -E ':(3000|1935|8000|80|443)'
```

### Test app:

```bash
# Test HTTP
curl http://localhost:3000

# Test from browser
http://your-domain.com
```

---

## 🔧 Post-Deployment

### Create Admin User:

**Option 1: Via Web**
1. Đăng ký user bình thường
2. SSH vào server
3. Chạy:
```bash
sqlite3 /opt/livestream-app/livestream/livestream.db
UPDATE users SET is_admin = 1 WHERE username = 'your-username';
.exit
```

**Option 2: Via Script**
```bash
cd /opt/livestream-app/livestream
node -e "
const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

const db = new sqlite3.Database('./livestream.db');
const hashedPassword = bcrypt.hashSync('admin123', 10);

db.run(
  'INSERT INTO users (username, password, email, stream_key, is_admin) VALUES (?, ?, ?, ?, 1)',
  ['admin', hashedPassword, 'admin@example.com', uuidv4()],
  (err) => {
    if (err) console.error(err);
    else console.log('Admin user created');
    db.close();
  }
);
"
```

### Setup Backups:

```bash
# Create backup script
cat > /usr/local/bin/backup-livestream.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/backups/livestream"
mkdir -p $BACKUP_DIR
DATE=$(date +%Y%m%d-%H%M%S)

# Backup database
cp /opt/livestream-app/livestream/livestream.db $BACKUP_DIR/db-$DATE.db

# Keep last 7 days
find $BACKUP_DIR -name "*.db" -mtime +7 -delete
EOF

chmod +x /usr/local/bin/backup-livestream.sh

# Add to crontab
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/backup-livestream.sh") | crontab -
```

---

## 🆘 Troubleshooting

### App không chạy:

```bash
# Check logs
pm2 logs livestream-app --lines 100

# Restart
pm2 restart livestream-app

# Check .env
cat /opt/livestream-app/livestream/.env
```

### Port bị chiếm:

```bash
# Find process
sudo lsof -i :3000
sudo lsof -i :1935

# Kill process
sudo kill -9 [PID]

# Restart app
pm2 restart livestream-app
```

### Nginx errors:

```bash
# Check config
nginx -t

# Check logs
tail -f /var/log/nginx/error.log

# Restart
systemctl restart nginx
```

### SSL không hoạt động:

```bash
# Check DNS
ping your-domain.com

# Try manual
certbot --nginx -d your-domain.com

# Check renewal
certbot renew --dry-run
```

---

## 📊 Monitoring

### PM2 Monitor:

```bash
# Real-time monitoring
pm2 monit

# Web dashboard
pm2 install pm2-server-monit
# Access at http://your-ip:9615
```

### System Resources:

```bash
# CPU/Memory
htop

# Disk
df -h

# Network
iftop
```

---

## 🔄 Updates

### Update Application:

```bash
cd /opt/livestream-app/livestream
git pull
npm install
pm2 restart livestream-app
```

### Update System:

```bash
apt update && apt upgrade -y
pm2 update
```

---

## 📞 Support

Nếu gặp vấn đề:

1. Check logs: `pm2 logs livestream-app`
2. Check docs: `DEPLOYMENT-GUIDE.md`
3. GitHub issues: https://github.com/khacnam/dev/issues

---

**Chúc bạn deploy thành công! 🚀**
