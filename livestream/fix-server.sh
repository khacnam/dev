#!/bin/bash
# Debug and Fix Script for Live Stream App
# Server: 23.142.84.207
# Domain: live.trongtamtay.com

echo "=========================================="
echo "Live Stream App - Debug & Fix Script"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root${NC}"
    exit 1
fi

DOMAIN="live.trongtamtay.com"
APP_DIR="/opt/livestream-app/livestream"

echo -e "${BLUE}1. Checking current setup...${NC}"

# Check if app directory exists
if [ ! -d "$APP_DIR" ]; then
    echo -e "${RED}✗ App directory not found: $APP_DIR${NC}"
    echo "Please run deploy-server.sh first"
    exit 1
fi

cd $APP_DIR

# Check PM2 status
echo -e "${YELLOW}Checking PM2 status...${NC}"
pm2 status livestream-app
echo ""

# Check ports
echo -e "${YELLOW}Checking ports...${NC}"
netstat -tlnp | grep -E ':(3000|1935|8000|80|443)'
echo ""

# Check logs
echo -e "${YELLOW}Recent app logs:${NC}"
pm2 logs livestream-app --lines 20 --nostream
echo ""

echo -e "${BLUE}2. Fixing Nginx configuration...${NC}"

# Backup existing config
if [ -f /etc/nginx/sites-available/livestream ]; then
    cp /etc/nginx/sites-available/livestream /etc/nginx/sites-available/livestream.backup
fi

# Create new Nginx config
cat > /etc/nginx/sites-available/livestream << 'NGINX_EOF'
# HTTP redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name live.trongtamtay.com;

    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name live.trongtamtay.com;

    # SSL certificates (will be configured by Certbot)
    ssl_certificate /etc/letsencrypt/live/live.trongtamtay.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/live.trongtamtay.com/privkey.pem;

    # SSL settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';
    ssl_prefer_server_ciphers off;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Increase upload size
    client_max_body_size 100M;

    # Main application (Node.js on port 3000)
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Socket.IO WebSocket support
    location /socket.io/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket timeouts
        proxy_connect_timeout 7d;
        proxy_send_timeout 7d;
        proxy_read_timeout 7d;
    }

    # HLS Streams (Node Media Server on port 8000)
    location /live/ {
        proxy_pass http://localhost:8000/live/;

        # CORS headers for HLS
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Range' always;
        add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range' always;

        # Cache settings for HLS
        add_header Cache-Control 'no-cache, no-store, must-revalidate' always;
        add_header Pragma 'no-cache' always;
        add_header Expires '0' always;

        # Handle OPTIONS for CORS preflight
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*';
            add_header 'Access-Control-Allow-Methods' 'GET, OPTIONS';
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain charset=UTF-8';
            add_header 'Content-Length' 0;
            return 204;
        }

        # Proxy settings
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Static files caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        proxy_pass http://localhost:3000;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
NGINX_EOF

echo -e "${GREEN}✓ Nginx config created${NC}"

# Test Nginx config
echo -e "${YELLOW}Testing Nginx configuration...${NC}"
nginx -t

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Nginx config is valid${NC}"
    systemctl reload nginx
    echo -e "${GREEN}✓ Nginx reloaded${NC}"
else
    echo -e "${RED}✗ Nginx config has errors${NC}"
    echo "Restoring backup..."
    mv /etc/nginx/sites-available/livestream.backup /etc/nginx/sites-available/livestream
    exit 1
fi

echo ""
echo -e "${BLUE}3. Checking/Fixing SSL certificate...${NC}"

# Check if SSL certificate exists
if [ ! -f /etc/letsencrypt/live/live.trongtamtay.com/fullchain.pem ]; then
    echo -e "${YELLOW}SSL certificate not found. Requesting...${NC}"

    # Temporarily use HTTP-only config
    cat > /etc/nginx/sites-available/livestream << 'TEMP_NGINX'
server {
    listen 80;
    server_name live.trongtamtay.com;

    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /socket.io/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location /live/ {
        proxy_pass http://localhost:8000/live/;
        add_header 'Access-Control-Allow-Origin' '*' always;
    }
}
TEMP_NGINX

    systemctl reload nginx

    # Install Certbot if not installed
    if ! command -v certbot &> /dev/null; then
        apt install -y certbot python3-certbot-nginx
    fi

    # Request certificate
    certbot --nginx -d live.trongtamtay.com --non-interactive --agree-tos --email admin@trongtamtay.com --redirect

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ SSL certificate obtained${NC}"
    else
        echo -e "${YELLOW}⚠ Could not get SSL certificate. Continuing with HTTP...${NC}"
    fi
else
    echo -e "${GREEN}✓ SSL certificate exists${NC}"
fi

echo ""
echo -e "${BLUE}4. Checking .env configuration...${NC}"

# Check and update .env
if [ -f "$APP_DIR/.env" ]; then
    # Update DOMAIN in .env
    sed -i "s/^DOMAIN=.*/DOMAIN=live.trongtamtay.com/" $APP_DIR/.env
    echo -e "${GREEN}✓ .env updated with correct domain${NC}"
    cat $APP_DIR/.env | grep DOMAIN
else
    echo -e "${RED}✗ .env file not found${NC}"
fi

echo ""
echo -e "${BLUE}5. Checking firewall...${NC}"

# Ensure all ports are open
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000/tcp
ufw allow 1935/tcp
ufw allow 8000/tcp

echo -e "${GREEN}✓ Firewall rules updated${NC}"
ufw status | grep -E '(80|443|3000|1935|8000)'

echo ""
echo -e "${BLUE}6. Restarting application...${NC}"

# Restart PM2 app
pm2 restart livestream-app

echo -e "${GREEN}✓ Application restarted${NC}"

# Wait for app to start
sleep 5

echo ""
echo -e "${BLUE}7. Running diagnostics...${NC}"

# Test local connections
echo -e "${YELLOW}Testing local connections:${NC}"

# Test port 3000
if curl -s http://localhost:3000 > /dev/null; then
    echo -e "${GREEN}✓ Port 3000 (App) is responding${NC}"
else
    echo -e "${RED}✗ Port 3000 (App) is NOT responding${NC}"
fi

# Test port 8000
if curl -s http://localhost:8000 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Port 8000 (HLS) is responding${NC}"
else
    echo -e "${YELLOW}⚠ Port 8000 (HLS) is NOT responding (normal if no streams)${NC}"
fi

# Test Nginx
if curl -s http://localhost > /dev/null; then
    echo -e "${GREEN}✓ Nginx is responding${NC}"
else
    echo -e "${RED}✗ Nginx is NOT responding${NC}"
fi

echo ""
echo -e "${BLUE}8. Checking Node Media Server...${NC}"

# Check if Node Media Server ports are listening
if netstat -tlnp | grep -q ':1935'; then
    echo -e "${GREEN}✓ RTMP server (port 1935) is listening${NC}"
else
    echo -e "${RED}✗ RTMP server (port 1935) is NOT listening${NC}"
fi

if netstat -tlnp | grep -q ':8000'; then
    echo -e "${GREEN}✓ HLS server (port 8000) is listening${NC}"
else
    echo -e "${YELLOW}⚠ HLS server (port 8000) is NOT listening (starts with first stream)${NC}"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}Fix completed!${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}Access your app:${NC}"
echo "  https://live.trongtamtay.com"
echo ""
echo -e "${BLUE}Test streaming:${NC}"
echo "  1. Go to: https://live.trongtamtay.com/dashboard"
echo "  2. Click 'Go Live từ Browser'"
echo "  3. Allow camera/mic"
echo "  4. Click 'Go Live'"
echo "  5. Copy and open watch link"
echo ""
echo -e "${BLUE}View logs:${NC}"
echo "  pm2 logs livestream-app --lines 100"
echo ""
echo -e "${BLUE}Check status:${NC}"
echo "  pm2 status"
echo "  systemctl status nginx"
echo ""

# Show current PM2 status
echo -e "${BLUE}Current PM2 status:${NC}"
pm2 status

echo ""
echo -e "${YELLOW}Note about browser streaming:${NC}"
echo "Browser streaming uses WebRTC/MediaRecorder which:"
echo "- Records video in browser"
echo "- Sends chunks via Socket.IO"
echo "- Currently shows in browser preview only"
echo "- To show to viewers, consider using OBS/Larix with RTMP"
echo ""
echo -e "${BLUE}For better streaming with video playback:${NC}"
echo "1. Use OBS Studio or Larix Broadcaster"
echo "2. RTMP URL: rtmp://live.trongtamtay.com:1935/live"
echo "3. Stream Key: (get from dashboard)"
echo ""
