#!/bin/bash
# Script to create downloadable package

echo "=========================================="
echo "Creating Live Stream App Package"
echo "=========================================="
echo ""

PACKAGE_NAME="livestream-app-$(date +%Y%m%d)"
TEMP_DIR="/tmp/$PACKAGE_NAME"

# Create temp directory
echo "Creating temporary directory..."
mkdir -p "$TEMP_DIR"

# Copy files
echo "Copying files..."
cp -r . "$TEMP_DIR/"

# Remove unnecessary files
echo "Cleaning up..."
cd "$TEMP_DIR"
rm -rf node_modules
rm -rf .git
rm -rf livestream.db
rm -rf media
rm -rf recordings
rm -f *.tar.gz
rm -f *.zip
rm -f create-package.sh

# Create .env.example if not exists
if [ ! -f .env.example ]; then
    echo "Creating .env.example..."
    cat > .env.example << 'EOF'
# Server Configuration
HTTP_PORT=3000
RTMP_PORT=1935

# Domain or IP
DOMAIN=localhost

# JWT Secret (change this!)
JWT_SECRET=change-this-to-a-random-secret-key

# FFmpeg path
FFMPEG_PATH=/usr/bin/ffmpeg
EOF
fi

# Create README for package
echo "Creating package README..."
cat > README-PACKAGE.txt << 'EOF'
========================================
Live Stream App - Installation Package
========================================

Quick Start:
------------
1. Extract this package
2. Install Node.js 18+ and FFmpeg
3. Run: npm install
4. Copy .env.example to .env and edit it
5. Run: npm start
6. Open http://localhost:3000

Full Documentation:
-------------------
- QUICKSTART.md - Quick start guide
- LIVESTREAM-README.md - Complete documentation
- DEPLOYMENT-GUIDE.md - Production deployment
- BROWSER-STREAMING.md - Browser streaming feature
- DOWNLOAD.md - Download instructions

Requirements:
-------------
- Node.js 18.x or higher
- FFmpeg 4.x or higher
- 2GB RAM minimum
- Ubuntu 22.04 (recommended)

Ports:
------
- 3000: HTTP Web Interface
- 1935: RTMP Streaming
- 8000: HLS Playback

Support:
--------
- GitHub: https://github.com/khacnam/dev
- Issues: https://github.com/khacnam/dev/issues

Version: $(date +%Y.%m.%d)
Package created: $(date)
EOF

# Go back to original directory
cd - > /dev/null

# Create tar.gz
echo "Creating tar.gz package..."
tar -czf "$PACKAGE_NAME.tar.gz" -C /tmp "$PACKAGE_NAME"

# Create zip
echo "Creating zip package..."
cd /tmp
zip -r "$PACKAGE_NAME.zip" "$PACKAGE_NAME" > /dev/null
cd - > /dev/null

# Move packages to current directory
mv "/tmp/$PACKAGE_NAME.tar.gz" .
mv "/tmp/$PACKAGE_NAME.zip" .

# Cleanup
echo "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

# Show results
echo ""
echo "=========================================="
echo "✅ Packages created successfully!"
echo "=========================================="
echo ""
ls -lh "$PACKAGE_NAME.tar.gz" "$PACKAGE_NAME.zip"
echo ""
echo "Packages created:"
echo "  - $PACKAGE_NAME.tar.gz (for Linux/Mac)"
echo "  - $PACKAGE_NAME.zip (for Windows)"
echo ""
echo "To extract:"
echo "  tar -xzf $PACKAGE_NAME.tar.gz   (Linux/Mac)"
echo "  unzip $PACKAGE_NAME.zip         (Windows)"
echo ""
echo "MD5 checksums:"
md5sum "$PACKAGE_NAME.tar.gz" "$PACKAGE_NAME.zip" 2>/dev/null || md5 "$PACKAGE_NAME.tar.gz" "$PACKAGE_NAME.zip"
echo ""
