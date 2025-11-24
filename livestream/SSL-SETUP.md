# 🔒 SSL/HTTPS Setup Guide

Hướng dẫn cài đặt SSL certificate miễn phí với Let's Encrypt cho ứng dụng Live Stream.

## Yêu cầu

- Domain name đã trỏ về server IP
- Ubuntu 22.04 server
- Nginx đã cài đặt
- Ports 80 và 443 đã mở

## Phương pháp 1: Sử dụng Certbot (Khuyên dùng)

### Bước 1: Cài đặt Certbot

```bash
# Cài đặt Certbot và Nginx plugin
sudo apt update
sudo apt install certbot python3-certbot-nginx -y
```

### Bước 2: Cấu hình Nginx

```bash
# Tạo file cấu hình Nginx cơ bản
sudo nano /etc/nginx/sites-available/livestream
```

Thêm nội dung:

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name your-domain.com www.your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/livestream /etc/nginx/sites-enabled/

# Test cấu hình
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
```

### Bước 3: Xin SSL Certificate

```bash
# Chạy Certbot
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Certbot sẽ tự động:
# 1. Xác minh domain
# 2. Tạo SSL certificate
# 3. Cấu hình Nginx để sử dụng HTTPS
# 4. Thiết lập auto-renewal
```

### Bước 4: Cấu hình HTTPS đầy đủ

Sau khi Certbot chạy xong, cập nhật file `/etc/nginx/sites-available/livestream`:

```nginx
# HTTP redirect
server {
    listen 80;
    listen [::]:80;
    server_name your-domain.com www.your-domain.com;
    return 301 https://$server_name$request_uri;
}

# HTTPS
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name your-domain.com www.your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/your-domain.com/chain.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Main application
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket (Socket.IO)
    location /socket.io/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
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
# Test và restart
sudo nginx -t
sudo systemctl restart nginx
```

### Bước 5: Cập nhật .env

```bash
cd /opt/livestream-app
nano .env
```

Cập nhật:
```env
DOMAIN=your-domain.com
```

```bash
# Restart app
pm2 restart livestream-app
```

### Bước 6: Kiểm tra Auto-renewal

```bash
# Test renewal
sudo certbot renew --dry-run

# Check timer
sudo systemctl status certbot.timer
```

Certificate sẽ tự động gia hạn trước 30 ngày hết hạn.

## Phương pháp 2: Manual với Certbot

Nếu không dùng Nginx plugin:

```bash
# Xin certificate
sudo certbot certonly --standalone -d your-domain.com -d www.your-domain.com

# Certificate sẽ được lưu tại:
# /etc/letsencrypt/live/your-domain.com/fullchain.pem
# /etc/letsencrypt/live/your-domain.com/privkey.pem
```

Sau đó tự cấu hình Nginx như Bước 4 ở trên.

## Phương pháp 3: Sử dụng Docker với Let's Encrypt

### docker-compose.yml

```yaml
version: '3.8'

services:
  livestream-app:
    build: .
    ports:
      - "3000:3000"
      - "1935:1935"
      - "8000:8000"
    # ... other configs

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - ./ssl:/etc/letsencrypt:ro
      - ./certbot-webroot:/var/www/certbot
    depends_on:
      - livestream-app

  certbot:
    image: certbot/certbot
    volumes:
      - ./ssl:/etc/letsencrypt
      - ./certbot-webroot:/var/www/certbot
    entrypoint: "/bin/sh -c 'trap exit TERM; while :; do certbot renew; sleep 12h & wait $${!}; done;'"
```

### Xin certificate lần đầu:

```bash
# Stop nginx nếu đang chạy
sudo systemctl stop nginx

# Chạy certbot standalone
docker run -it --rm \
  -v $PWD/ssl:/etc/letsencrypt \
  -p 80:80 \
  certbot/certbot certonly --standalone \
  -d your-domain.com \
  -d www.your-domain.com \
  --email your-email@example.com \
  --agree-tos

# Start lại docker compose
docker-compose up -d
```

## Troubleshooting

### Certificate không tự động gia hạn

```bash
# Check certbot timer
sudo systemctl status certbot.timer

# Manual renew
sudo certbot renew

# Check logs
sudo journalctl -u certbot.timer
```

### Lỗi "too many certificates"

Let's Encrypt giới hạn 5 certificates/domain/week. Đợi hoặc dùng staging environment:

```bash
sudo certbot --staging --nginx -d your-domain.com
```

### Mixed Content Errors

Đảm bảo tất cả resources được load qua HTTPS. Trong `.env`:

```env
DOMAIN=your-domain.com  # Không có http:// hay https://
```

Ứng dụng sẽ tự detect protocol.

### WebSocket không hoạt động qua HTTPS

Đảm bảo Nginx config có:

```nginx
location /socket.io/ {
    proxy_pass http://localhost:3000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
}
```

## Security Best Practices

### 1. SSL Labs Test

Kiểm tra SSL configuration:
```
https://www.ssllabs.com/ssltest/analyze.html?d=your-domain.com
```

### 2. HSTS Preload

Thêm vào Nginx config:
```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
```

Submit tại: https://hstspreload.org/

### 3. Security Headers

```nginx
add_header X-Frame-Options "DENY" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;
add_header Content-Security-Policy "default-src 'self' https:; script-src 'self' 'unsafe-inline' 'unsafe-eval' https:; style-src 'self' 'unsafe-inline' https:;" always;
```

### 4. Disable TLS 1.0 and 1.1

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
```

### 5. OCSP Stapling

```nginx
ssl_stapling on;
ssl_stapling_verify on;
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 5s;
```

## Monitoring

### Check certificate expiry

```bash
# Manual check
sudo certbot certificates

# Or
echo | openssl s_client -servername your-domain.com -connect your-domain.com:443 2>/dev/null | openssl x509 -noout -dates
```

### Setup expiry alerts

Tạo script `/usr/local/bin/check-ssl-expiry.sh`:

```bash
#!/bin/bash
DOMAIN="your-domain.com"
DAYS_UNTIL_EXPIRY=$(echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:443 2>/dev/null | openssl x509 -noout -enddate | cut -d= -f2 | xargs -I {} date -d "{}" +%s | awk '{print ($1 - systime()) / 86400}')

if (( $(echo "$DAYS_UNTIL_EXPIRY < 30" | bc -l) )); then
    echo "SSL certificate expiring in $DAYS_UNTIL_EXPIRY days!" | mail -s "SSL Alert: $DOMAIN" admin@example.com
fi
```

Thêm vào crontab:
```bash
sudo crontab -e
# Check daily at 9 AM
0 9 * * * /usr/local/bin/check-ssl-expiry.sh
```

## Quick Reference

```bash
# Check SSL expiry
sudo certbot certificates

# Renew certificate
sudo certbot renew

# Renew specific domain
sudo certbot renew --cert-name your-domain.com

# Revoke certificate
sudo certbot revoke --cert-path /etc/letsencrypt/live/your-domain.com/cert.pem

# Delete certificate
sudo certbot delete --cert-name your-domain.com

# Test renewal
sudo certbot renew --dry-run
```

---

**Chúc bạn thiết lập HTTPS thành công! 🔒**
