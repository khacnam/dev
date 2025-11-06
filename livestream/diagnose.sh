#!/bin/bash
# Diagnostic script - Run this on server and paste output

echo "=========================================="
echo "DIAGNOSTIC REPORT"
echo "Server: 23.142.84.207"
echo "Domain: live.trongtamtay.com"
echo "Time: $(date)"
echo "=========================================="
echo ""

echo "=== 1. System Info ==="
uname -a
cat /etc/os-release | grep -E "(NAME|VERSION)"
echo ""

echo "=== 2. Node.js & NPM ==="
node --version
npm --version
echo ""

echo "=== 3. FFmpeg ==="
ffmpeg -version | head -n 1
echo ""

echo "=== 4. PM2 Status ==="
pm2 status
echo ""

echo "=== 5. PM2 Logs (last 30 lines) ==="
pm2 logs livestream-app --lines 30 --nostream
echo ""

echo "=== 6. Listening Ports ==="
netstat -tlnp | grep -E ':(80|443|3000|1935|8000)'
echo ""

echo "=== 7. Nginx Status ==="
systemctl status nginx --no-pager
echo ""

echo "=== 8. Nginx Configuration ==="
cat /etc/nginx/sites-enabled/livestream
echo ""

echo "=== 9. App .env File ==="
if [ -f /opt/livestream-app/livestream/.env ]; then
    cat /opt/livestream-app/livestream/.env
else
    echo "❌ .env not found"
fi
echo ""

echo "=== 10. App Directory ==="
ls -la /opt/livestream-app/livestream/
echo ""

echo "=== 11. SSL Certificate ==="
if [ -f /etc/letsencrypt/live/live.trongtamtay.com/fullchain.pem ]; then
    echo "✓ SSL certificate exists"
    certbot certificates | grep -A 10 "live.trongtamtay.com"
else
    echo "❌ SSL certificate not found"
fi
echo ""

echo "=== 12. Firewall Rules ==="
ufw status
echo ""

echo "=== 13. Disk Space ==="
df -h
echo ""

echo "=== 14. Memory Usage ==="
free -h
echo ""

echo "=== 15. Test Local Connections ==="
echo "Testing port 3000..."
curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost:3000 2>&1

echo "Testing port 8000..."
curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost:8000 2>&1

echo "Testing Nginx..."
curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost 2>&1

echo "Testing domain..."
curl -s -o /dev/null -w "Status: %{http_code}\n" https://live.trongtamtay.com 2>&1
echo ""

echo "=== 16. Recent System Logs ==="
journalctl -u nginx --no-pager -n 20
echo ""

echo "=========================================="
echo "DIAGNOSTIC COMPLETE"
echo "=========================================="
echo ""
echo "📋 Copy ALL output above and send to developer"
