#!/bin/bash
# Auto-deployment script for Live Stream App
# Run this on your Ubuntu 22.04 server

set -e

echo "=========================================="
echo "Live Stream App - Auto Deployment"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

# Get server info
echo -e "${YELLOW}Enter deployment information:${NC}"
read -p "Server IP or Domain: " SERVER_DOMAIN
read -p "Admin email (for SSL certificate): " ADMIN_EMAIL
read -p "Create admin username: " ADMIN_USERNAME
read -sp "Create admin password: " ADMIN_PASSWORD
echo ""

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
else
    echo -e "${RED}Cannot detect OS${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Detected OS: $OS $VER${NC}"

# Update system
echo -e "${YELLOW}📦 Updating system...${NC}"
apt update && apt upgrade -y

# Install Node.js 18.x
echo -e "${YELLOW}📦 Installing Node.js 18.x...${NC}"
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt install -y nodejs
fi
echo -e "${GREEN}✓ Node.js $(node --version) installed${NC}"

# Install FFmpeg
echo -e "${YELLOW}📦 Installing FFmpeg...${NC}"
if ! command -v ffmpeg &> /dev/null; then
    apt install -y ffmpeg
fi
echo -e "${GREEN}✓ FFmpeg installed${NC}"

# Install build tools
echo -e "${YELLOW}📦 Installing build tools...${NC}"
apt install -y build-essential python3 git

# Install PM2
echo -e "${YELLOW}📦 Installing PM2...${NC}"
if ! command -v pm2 &> /dev/null; then
    npm install -g pm2
fi
echo -e "${GREEN}✓ PM2 installed${NC}"

# Install Nginx
echo -e "${YELLOW}📦 Installing Nginx...${NC}"
if ! command -v nginx &> /dev/null; then
    apt install -y nginx
fi
echo -e "${GREEN}✓ Nginx installed${NC}"

# Create app directory
APP_DIR="/opt/livestream-app"
echo -e "${YELLOW}📁 Creating app directory at $APP_DIR...${NC}"
mkdir -p $APP_DIR
cd $APP_DIR

# Clone repository
echo -e "${YELLOW}📥 Cloning repository...${NC}"
if [ -d ".git" ]; then
    git pull
else
    git clone https://github.com/khacnam/dev.git .
fi

# Navigate to livestream directory
cd livestream

# Install dependencies
echo -e "${YELLOW}📦 Installing app dependencies...${NC}"
npm install --production

# Generate JWT secret
JWT_SECRET=$(openssl rand -base64 32)

# Create .env file
echo -e "${YELLOW}⚙️  Creating .env file...${NC}"
cat > .env << EOF
# Server Configuration
HTTP_PORT=3000
RTMP_PORT=1935

# Domain
DOMAIN=$SERVER_DOMAIN

# JWT Secret
JWT_SECRET=$JWT_SECRET

# FFmpeg path
FFMPEG_PATH=/usr/bin/ffmpeg
EOF

echo -e "${GREEN}✓ .env file created${NC}"

# Create directories
mkdir -p media recordings

# Setup firewall
echo -e "${YELLOW}🔥 Configuring firewall...${NC}"
ufw --force enable
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw allow 3000/tcp comment 'App HTTP'
ufw allow 1935/tcp comment 'RTMP'
ufw allow 8000/tcp comment 'HLS'
echo -e "${GREEN}✓ Firewall configured${NC}"

# Configure Nginx
echo -e "${YELLOW}🌐 Configuring Nginx...${NC}"
cat > /etc/nginx/sites-available/livestream << EOF
server {
    listen 80;
    server_name $SERVER_DOMAIN;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /socket.io/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }

    location /live/ {
        proxy_pass http://localhost:8000/live/;
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header Cache-Control 'no-cache';
    }
}
EOF

# Enable Nginx site
ln -sf /etc/nginx/sites-available/livestream /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx
echo -e "${GREEN}✓ Nginx configured${NC}"

# Start application with PM2
echo -e "${YELLOW}🚀 Starting application...${NC}"
pm2 stop livestream-app 2>/dev/null || true
pm2 delete livestream-app 2>/dev/null || true
pm2 start server-enhanced.js --name livestream-app
pm2 save
pm2 startup systemd -u root --hp /root
echo -e "${GREEN}✓ Application started${NC}"

# Install Certbot for SSL
if [[ ! -z "$ADMIN_EMAIL" ]]; then
    echo -e "${YELLOW}🔒 Installing Certbot for SSL...${NC}"
    apt install -y certbot python3-certbot-nginx

    # Try to get SSL certificate
    echo -e "${YELLOW}🔒 Requesting SSL certificate...${NC}"
    certbot --nginx -d $SERVER_DOMAIN --non-interactive --agree-tos --email $ADMIN_EMAIL --redirect || {
        echo -e "${YELLOW}⚠️  SSL certificate not obtained. You can run this later:${NC}"
        echo "    sudo certbot --nginx -d $SERVER_DOMAIN"
    }
fi

# Wait for app to start
echo -e "${YELLOW}⏳ Waiting for app to start...${NC}"
sleep 5

# Create admin user via database
echo -e "${YELLOW}👤 Creating admin user...${NC}"
cat > /tmp/create_admin.sql << EOF
INSERT OR IGNORE INTO users (username, password, email, stream_key, is_admin)
VALUES (
    '$ADMIN_USERNAME',
    '$(node -e "console.log(require('bcryptjs').hashSync('$ADMIN_PASSWORD', 10))")',
    '$ADMIN_EMAIL',
    '$(uuidgen)',
    1
);
EOF

# Wait a bit more for DB to be created
sleep 3

# Execute SQL
sqlite3 $APP_DIR/livestream/livestream.db < /tmp/create_admin.sql 2>/dev/null || {
    echo -e "${YELLOW}⚠️  Admin user not created via script${NC}"
    echo -e "${YELLOW}Please register manually and run:${NC}"
    echo "    sqlite3 $APP_DIR/livestream/livestream.db"
    echo "    UPDATE users SET is_admin = 1 WHERE username = '$ADMIN_USERNAME';"
}

rm /tmp/create_admin.sql

# Show status
echo ""
echo "=========================================="
echo -e "${GREEN}✅ Deployment completed!${NC}"
echo "=========================================="
echo ""
echo "📊 Service Status:"
pm2 status
echo ""
echo "🌐 Access your app at:"
echo "   http://$SERVER_DOMAIN"
if certbot certificates 2>/dev/null | grep -q "$SERVER_DOMAIN"; then
    echo "   https://$SERVER_DOMAIN"
fi
echo ""
echo "👤 Admin Login:"
echo "   Username: $ADMIN_USERNAME"
echo "   Password: $ADMIN_PASSWORD"
echo ""
echo "📝 Useful commands:"
echo "   pm2 status             # Check status"
echo "   pm2 logs livestream-app  # View logs"
echo "   pm2 restart livestream-app  # Restart app"
echo "   pm2 monit              # Monitor resources"
echo ""
echo "📚 Documentation:"
echo "   cd $APP_DIR/livestream"
echo "   cat QUICKSTART.md"
echo ""
echo "🔐 Security Notes:"
echo "   - Change admin password after first login"
echo "   - Database: $APP_DIR/livestream/livestream.db"
echo "   - Logs: pm2 logs livestream-app"
echo ""
echo "🎉 Happy streaming!"
echo ""
