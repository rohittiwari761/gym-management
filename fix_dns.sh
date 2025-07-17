#!/bin/bash

echo "🔧 Fixing DNS resolution for Railway URL..."
echo "=========================================="

echo "1. Flushing DNS cache..."
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
echo "✅ DNS cache flushed"

echo ""
echo "2. Testing Railway URL resolution..."
dig @8.8.8.8 gym-management-production-2168.up.railway.app

echo ""
echo "3. Testing with system DNS..."
nslookup gym-management-production-2168.up.railway.app

echo ""
echo "4. Testing HTTP connectivity..."
curl -I --connect-timeout 10 https://gym-management-production-2168.up.railway.app/health/

echo ""
echo "🎯 Manual DNS Override (if still not working):"
echo "Add this to your /etc/hosts file:"
echo "66.33.22.198 gym-management-production-2168.up.railway.app"
echo ""
echo "Command to add hosts entry:"
echo "sudo echo '66.33.22.198 gym-management-production-2168.up.railway.app' >> /etc/hosts"

echo ""
echo "🌐 Alternative: Change DNS servers to Google DNS"
echo "System Settings → Wi-Fi → Details → DNS"
echo "Set to: 8.8.8.8, 8.8.4.4"