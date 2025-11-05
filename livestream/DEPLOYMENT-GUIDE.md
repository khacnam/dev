# 🚀 Deployment Guide - Live Stream App

Hướng dẫn triển khai toàn diện từ A-Z cho production environment.

## 📋 Mục lục

1. [Yêu cầu hệ thống](#yêu-cầu-hệ-thống)
2. [Phương pháp triển khai](#phương-pháp-triển-khai)
3. [Deployment với PM2](#deployment-với-pm2)
4. [Deployment với Docker](#deployment-với-docker)
5. [Deployment với Systemd](#deployment-với-systemd)
6. [Cấu hình Nginx Reverse Proxy](#cấu-hình-nginx)
7. [SSL/HTTPS Setup](#ssl-setup)
8. [Database Backup](#database-backup)
9. [Monitoring & Logging](#monitoring--logging)
10. [Security Hardening](#security-hardening)
11. [Performance Optimization](#performance-optimization)
12. [Troubleshooting](#troubleshooting)

---

## Yêu cầu hệ thống

### Minimum Requirements

- **OS**: Ubuntu 22.04 LTS (khuyên dùng)
- **CPU**: 2 cores
- **RAM**: 2GB
- **Storage**: 20GB SSD
- **Network**: 100Mbps

### Recommended for Production

- **OS**: Ubuntu 22.04 LTS
- **CPU**: 4+ cores
- **RAM**: 4GB+
- **Storage**: 50GB+ SSD
- **Network**: 1Gbps

### Software Requirements

- Node.js 18.x+
- FFmpeg 4.x+
- Nginx (optional, cho reverse proxy)
- PM2 hoặc Docker
- SQLite (đã bao gồm)

---

## Phương pháp triển khai

Có 3 phương pháp chính:

1. **PM2** (Khuyên dùng cho VPS đơn lẻ)
2. **Docker** (Khuyên dùng cho containerization)
3. **Systemd** (Alternative cho PM2)

---

## Deployment với PM2

### Bước 1: Chuẩn bị server

```bash
# SSH vào server
ssh user@your-server-ip

# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install FFmpeg
sudo apt install -y ffmpeg

# Install PM2
sudo npm install -g pm2

# Install build tools
sudo apt install -y build-essential python3
```

### Bước 2: Clone và setup application

```bash
# Clone repository
cd /opt
sudo mkdir livestream-app
sudo chown $USER:$USER livestream-app
cd livestream-app

# Clone từ git
git clone <your-repo-url> .

# Hoặc upload files qua SCP
# scp -r ./livestream/* user@server:/opt/livestream-app/

# Install dependencies
npm install --production
```

### Bước 3: Cấu hình environment

```bash
# Copy và edit .env
cp .env.example .env
nano .env
```

Cấu hình `.env`:

```env
# Server Configuration
HTTP_PORT=3000
RTMP_PORT=1935

# Domain (thay bằng IP hoặc domain thực)
DOMAIN=your-server-ip-or-domain.com

# JWT Secret (tạo random string phức tạp)
JWT_SECRET=your-very-secret-random-key-here

# FFmpeg path
FFMPEG_PATH=/usr/bin/ffmpeg
```

### Bước 4: Cấu hình firewall

```bash
# Mở ports
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 3000/tcp  # App HTTP
sudo ufw allow 1935/tcp  # RTMP
sudo ufw allow 8000/tcp  # HLS

# Enable firewall
sudo ufw enable
sudo ufw status
```

### Bước 5: Start với PM2

```bash
# Start application (sử dụng server-enhanced.js cho đầy đủ tính năng)
pm2 start server-enhanced.js --name livestream-app

# Hoặc dùng server.js cơ bản
# pm2 start server.js --name livestream-app

# Save PM2 process list
pm2 save

# Setup auto-start on boot
pm2 startup
# Chạy lệnh mà PM2 đưa ra (thường là sudo ...)

# Check status
pm2 status
pm2 logs livestream-app
```

### Bước 6: Tạo admin user đầu tiên

```bash
# Truy cập http://your-server-ip:3000
# Đăng ký tài khoản đầu tiên

# Sau đó promote thành admin trong database
sqlite3 livestream.db
UPDATE users SET is_admin = 1 WHERE username = 'your-username';
.exit
```

### PM2 Useful Commands

```bash
# Status
pm2 status

# Logs
pm2 logs livestream-app
pm2 logs livestream-app --lines 100

# Restart
pm2 restart livestream-app

# Stop
pm2 stop livestream-app

# Delete
pm2 delete livestream-app

# Monitor
pm2 monit

# Reload (zero-downtime)
pm2 reload livestream-app
```

---

## Deployment với Docker

### Bước 1: Install Docker

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt install docker-compose -y

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### Bước 2: Clone và setup

```bash
cd /opt
git clone <your-repo-url> livestream-app
cd livestream-app
```

### Bước 3: Cấu hình environment

```bash
# Tạo .env file
cp .env.example .env
nano .env
```

```env
DOMAIN=your-domain.com
JWT_SECRET=your-secret-key
HTTP_PORT=3000
RTMP_PORT=1935
```

### Bước 4: Build và start

```bash
# Build image
docker-compose build

# Start services
docker-compose up -d

# Check logs
docker-compose logs -f

# Check status
docker-compose ps
```

### Bước 5: SSL với Docker (optional)

```bash
# Xin certificate
sudo certbot certonly --standalone \
  -d your-domain.com \
  -d www.your-domain.com \
  --email your-email@example.com \
  --agree-tos

# Copy certificates
sudo mkdir -p ssl
sudo cp -r /etc/letsencrypt/live/your-domain.com ssl/

# Restart với SSL
docker-compose down
docker-compose up -d
```

### Docker Useful Commands

```bash
# Logs
docker-compose logs -f livestream-app

# Restart
docker-compose restart

# Stop
docker-compose down

# Rebuild
docker-compose build --no-cache
docker-compose up -d

# Enter container
docker exec -it livestream-app sh

# View stats
docker stats
```

---

## Deployment với Systemd

### Bước 1-3: Giống như PM2

### Bước 4: Tạo systemd service

```bash
sudo nano /etc/systemd/system/livestream.service
```

```ini
[Unit]
Description=Live Stream Application
After=network.target

[Service]
Type=simple
User=your-username
WorkingDirectory=/opt/livestream-app
Environment=NODE_ENV=production
ExecStart=/usr/bin/node /opt/livestream-app/server-enhanced.js
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=livestream-app

[Install]
WantedBy=multi-user.target
```

### Bước 5: Enable và start

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable auto-start
sudo systemctl enable livestream

# Start service
sudo systemctl start livestream

# Check status
sudo systemctl status livestream

# View logs
sudo journalctl -u livestream -f
```

---

## Cấu hình Nginx

### Install Nginx

```bash
sudo apt install nginx -y
```

### Cấu hình basic (HTTP only)

```bash
sudo nano /etc/nginx/sites-available/livestream
```

```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket support
    location /socket.io/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # HLS Streams
    location /live/ {
        proxy_pass http://localhost:8000/live/;
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header Cache-Control 'no-cache';
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/livestream /etc/nginx/sites-enabled/

# Test config
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
```

### Full config với HTTPS

Xem file `nginx.conf` trong repository hoặc [SSL-SETUP.md](SSL-SETUP.md)

---

## SSL Setup

Chi tiết trong [SSL-SETUP.md](SSL-SETUP.md)

### Quick setup với Certbot

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Xin certificate và auto-configure
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Test auto-renewal
sudo certbot renew --dry-run
```

---

## Database Backup

### Manual backup

```bash
# Backup database
cd /opt/livestream-app
cp livestream.db livestream.db.backup-$(date +%Y%m%d-%H%M%S)

# Backup với compression
tar -czf livestream-backup-$(date +%Y%m%d).tar.gz \
  livestream.db .env recordings/
```

### Automated backup script

Tạo `/usr/local/bin/backup-livestream.sh`:

```bash
#!/bin/bash
BACKUP_DIR="/backups/livestream"
APP_DIR="/opt/livestream-app"
DATE=$(date +%Y%m%d-%H%M%S)

mkdir -p $BACKUP_DIR

# Backup database
cp $APP_DIR/livestream.db $BACKUP_DIR/livestream-$DATE.db

# Backup with compression
tar -czf $BACKUP_DIR/full-backup-$DATE.tar.gz \
  -C $APP_DIR livestream.db .env

# Keep only last 7 days
find $BACKUP_DIR -name "*.db" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
```

```bash
chmod +x /usr/local/bin/backup-livestream.sh

# Add to crontab (daily at 2 AM)
sudo crontab -e
0 2 * * * /usr/local/bin/backup-livestream.sh >> /var/log/livestream-backup.log 2>&1
```

### Backup to remote server

```bash
# Via rsync
rsync -avz /opt/livestream-app/livestream.db \
  user@backup-server:/backups/livestream/

# Via S3 (AWS CLI required)
aws s3 cp livestream.db s3://your-bucket/backups/livestream-$(date +%Y%m%d).db
```

---

## Monitoring & Logging

### PM2 Monitoring

```bash
# Real-time monitoring
pm2 monit

# Web dashboard
pm2 install pm2-server-monit
# Access at http://your-server-ip:9615

# Logs
pm2 logs livestream-app --lines 100
```

### System monitoring

```bash
# Install htop
sudo apt install htop -y
htop

# Check disk usage
df -h

# Check memory
free -h

# Check network
sudo iftop
```

### Application logs

```bash
# PM2
pm2 logs livestream-app

# Systemd
sudo journalctl -u livestream -f

# Docker
docker-compose logs -f
```

### Setup log rotation

```bash
sudo nano /etc/logrotate.d/livestream
```

```
/var/log/livestream/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data www-data
    sharedscripts
}
```

---

## Security Hardening

### 1. Firewall

```bash
# Only allow necessary ports
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 1935/tcp
sudo ufw enable
```

### 2. Fail2Ban

```bash
# Install
sudo apt install fail2ban -y

# Configure
sudo nano /etc/fail2ban/jail.local
```

```ini
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
```

```bash
sudo systemctl restart fail2ban
```

### 3. Secure SSH

```bash
sudo nano /etc/ssh/sshd_config
```

```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
Port 2222  # Change default port
```

```bash
sudo systemctl restart sshd
```

### 4. Environment variables

```bash
# Never commit .env to git
# Use strong JWT_SECRET
# Rotate secrets regularly
```

### 5. Rate limiting

Thêm vào Nginx config:

```nginx
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;

location /api/ {
    limit_req zone=api burst=20 nodelay;
    proxy_pass http://localhost:3000;
}
```

---

## Performance Optimization

### 1. Node.js optimization

```bash
# Increase max memory (PM2)
pm2 start server-enhanced.js --name livestream-app --max-memory-restart 1G

# Use cluster mode
pm2 start server-enhanced.js --name livestream-app -i max
```

### 2. Nginx caching

```nginx
# Cache static files
location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}

# Cache HLS segments briefly
location /live/ {
    proxy_pass http://localhost:8000/live/;
    proxy_cache my_cache;
    proxy_cache_valid 200 1s;
}
```

### 3. Database optimization

```bash
# Vacuum database periodically
sqlite3 livestream.db "VACUUM;"

# Analyze for query optimization
sqlite3 livestream.db "ANALYZE;"
```

### 4. CDN for HLS

Sử dụng CDN (CloudFlare, AWS CloudFront) cho HLS streams để giảm tải server.

---

## Troubleshooting

### Port already in use

```bash
# Find process using port
sudo lsof -i :3000
sudo lsof -i :1935

# Kill process
sudo kill -9 [PID]
```

### FFmpeg not found

```bash
# Install FFmpeg
sudo apt install ffmpeg -y

# Check path
which ffmpeg
# Update FFMPEG_PATH in .env
```

### Database locked

```bash
# Stop all instances
pm2 stop all

# Check for zombie processes
ps aux | grep node

# Restart
pm2 start livestream-app
```

### High CPU usage

```bash
# Check processes
htop

# Check PM2 logs
pm2 logs livestream-app

# Restart app
pm2 restart livestream-app
```

### Streams not playing

1. Check FFmpeg installation
2. Check firewall (port 1935, 8000)
3. Check RTMP connection
4. Check HLS generation in `media/` folder
5. Check browser console for errors

### WebSocket connection failed

1. Check Nginx WebSocket config
2. Check firewall
3. Check Socket.IO in browser console

---

## Maintenance Tasks

### Daily

- [ ] Check logs for errors
- [ ] Monitor disk space
- [ ] Check application status

### Weekly

- [ ] Review analytics
- [ ] Clean old HLS segments
- [ ] Check backup status

### Monthly

- [ ] Update dependencies
- [ ] Review security logs
- [ ] Database vacuum and optimization
- [ ] SSL certificate check

### Quarterly

- [ ] System updates
- [ ] Security audit
- [ ] Performance review
- [ ] Backup restore test

---

## Scaling

### Horizontal scaling

1. Setup load balancer (Nginx/HAProxy)
2. Multiple app instances
3. Shared database (PostgreSQL/MySQL)
4. Redis for session storage
5. Separate streaming servers

### Vertical scaling

1. Upgrade CPU/RAM
2. Use SSD storage
3. Optimize database queries
4. Enable caching

---

## Support & Resources

- **Documentation**: README.md, QUICKSTART.md
- **Issues**: GitHub Issues
- **Security**: security@your-domain.com

---

**Chúc bạn deployment thành công! 🚀**
