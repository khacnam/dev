#!/bin/bash
# Quick start script

echo "Starting Live Stream App..."

# Check if .env exists
if [ ! -f .env ]; then
    echo "⚠️  File .env không tồn tại!"
    echo "Copy từ .env.example và chỉnh sửa:"
    echo "  cp .env.example .env"
    echo "  nano .env"
    exit 1
fi

# Check if node_modules exists
if [ ! -d node_modules ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Start with PM2 if available
if command -v pm2 &> /dev/null; then
    echo "🚀 Starting with PM2..."
    pm2 start server.js --name livestream-app
    pm2 logs livestream-app
else
    echo "🚀 Starting with Node.js..."
    node server.js
fi
