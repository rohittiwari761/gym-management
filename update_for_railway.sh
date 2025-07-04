#!/bin/bash

# 🔧 Update Django for Railway PostgreSQL Compatibility
echo "🔧 Updating Django configuration for Railway..."

cd "$(dirname "$0")"

# Add changes to git
git add .

# Commit database configuration updates
git commit -m "🔧 Configure Django for Railway PostgreSQL

✅ Database Updates:
- Added dj-database-url for Railway DATABASE_URL parsing
- Updated ALLOWED_HOSTS to include .railway.app
- Configured automatic PostgreSQL connection via DATABASE_URL
- Added Railway-specific settings for production

🚀 Deployment Ready:
- Django will now automatically connect to Railway PostgreSQL
- No manual database configuration needed
- Production settings optimized for Railway platform"

# Push to GitHub (triggers Railway deployment)
git push origin main

echo "✅ Configuration updated and pushed to GitHub!"
echo "🚀 Railway will automatically deploy with new database settings!"