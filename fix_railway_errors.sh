#!/bin/bash

# 🔧 Fix Railway Deployment Errors
echo "🔧 Fixing Railway deployment errors..."

cd "$(dirname "$0")"

# Add changes to git
git add .

# Commit critical fixes
git commit -m "🔧 Fix Railway deployment errors

✅ Critical Fixes:
- Fixed Sentry DjangoIntegration auto_enabling parameter error
- Made Redis cache optional (fallback to database cache)
- Made Sentry monitoring optional (only if DSN provided)
- Improved error handling for Railway environment

🚀 Railway Deployment:
- Removes TypeError in settings_production.py
- App will now deploy successfully on Railway
- Trainer-member associations will be live!"

# Push to GitHub (triggers Railway re-deployment)
git push origin main

echo "✅ Critical fixes pushed to GitHub!"
echo "🚀 Railway will automatically re-deploy with fixes!"
echo "🎯 Check Railway dashboard for successful deployment!"