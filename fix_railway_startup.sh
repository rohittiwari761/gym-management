#!/bin/bash

# 🔧 Fix Railway Startup Issues
echo "🔧 Fixing Railway startup and WSGI issues..."

cd "$(dirname "$0")"

# Add changes to git
git add .

# Commit startup fixes
git commit -m "🔧 Fix Railway startup and WSGI issues

✅ Critical Startup Fixes:
- Fixed WSGI production config (removed invalid paths)
- Simplified Procfile with direct Gunicorn command
- Disabled problematic middleware (Silk profiling)
- Made Redis apps conditional (only if Redis available)
- Removed file-based logging completely

🚀 Django Startup:
- WSGI application simplified for Railway
- No more WhiteNoise path errors
- Migrations run before server start
- Single worker process for Railway environment
- Direct PORT binding without complex config"

# Push to GitHub (triggers Railway re-deployment)
git push origin main

echo "✅ Startup fixes pushed to GitHub!"
echo "🚀 Railway will re-deploy with simplified Django configuration!"
echo "🎯 Django should start successfully and health check should pass!"