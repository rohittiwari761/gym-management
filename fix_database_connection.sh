#!/bin/bash

# 🔧 Fix Railway Database Connection
echo "🔧 Fixing Railway database connection..."

cd "$(dirname "$0")"

# Add changes to git
git add .

# Commit database connection fix
git commit -m "🔧 Fix Railway database connection configuration

✅ Database Connection Fix:
- Improved DATABASE_URL detection from Railway environment
- Added explicit os.environ.get('DATABASE_URL') check
- Added fallback configuration for local development
- Enhanced database configuration logic

🚀 Railway PostgreSQL:
- Django will now properly use Railway's DATABASE_URL
- Automatic connection to Railway PostgreSQL service
- No more localhost connection attempts
- Debug script added to check environment variables

🎯 Production Database:
- Trainer-member associations will store in Railway PostgreSQL
- All gym management data in cloud database
- Multi-tenant isolation maintained in production"

# Push to GitHub (triggers Railway re-deployment)
git push origin main

echo "✅ Database connection fix pushed to GitHub!"
echo "🚀 Railway will re-deploy with proper PostgreSQL connection!"
echo ""
echo "🔍 Next: Verify in Railway Dashboard:"
echo "   1. PostgreSQL service is running"
echo "   2. DATABASE_URL variable exists"
echo "   3. Services are connected"
echo ""
echo "🎯 Django should connect to Railway PostgreSQL successfully!"