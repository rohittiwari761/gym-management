#!/bin/bash

# 🔧 Fix Railway Logging Permission Error
echo "🔧 Fixing Railway logging permission error..."

cd "$(dirname "$0")"

# Add changes to git
git add .

# Commit logging fixes
git commit -m "🔧 Fix Railway logging permission error

✅ Critical Fix:
- Removed file-based logging that requires /var/log/gym_app/ directory
- Changed to console-only logging for Railway environment
- All logs now go to stdout/stderr (visible in Railway dashboard)
- Fixed PermissionError: [Errno 13] Permission denied

🚀 Logging Fix:
- Django will now start successfully on Railway
- No more permission denied errors for log files
- All logging visible in Railway deployment logs
- Health check should pass after this fix"

# Push to GitHub (triggers Railway re-deployment)
git push origin main

echo "✅ Logging fix pushed to GitHub!"
echo "🚀 Railway will re-deploy without logging permission errors!"
echo "🎯 Django should start successfully this time!"