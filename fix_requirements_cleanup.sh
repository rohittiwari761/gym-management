#!/bin/bash

# 🔧 Clean Up Requirements File
echo "🔧 Cleaning up requirements.txt for Railway..."

cd "$(dirname "$0")"

# Add changes to git
git add .

# Commit requirements cleanup
git commit -m "🔧 Clean up requirements.txt for Railway deployment

✅ Requirements Cleanup:
- Removed duplicate django-extensions entry
- Removed problematic packages (django-axes, django-silk, django-debug-toolbar)
- Removed django-cache-machine and django-bulk-update
- Kept essential packages only for Railway deployment
- Made Redis and Sentry optional dependencies

🚀 Essential Packages Only:
- Django core + DRF + filtering + image support
- Database: PostgreSQL + dj-database-url
- Security: JWT + CORS + rate limiting  
- Server: Gunicorn + WhiteNoise
- Environment: python-decouple

🎯 Railway Optimized:
- Faster build times with fewer dependencies
- Reduced chance of package conflicts
- Only necessary packages for gym management functionality"

# Push to GitHub (triggers Railway re-deployment)
git push origin main

echo "✅ Requirements cleanup pushed to GitHub!"
echo "🚀 Railway will build faster with essential packages only!"
echo "🎯 Deployment should succeed with clean dependencies!"