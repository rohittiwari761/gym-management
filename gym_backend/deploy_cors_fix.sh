#!/bin/bash

echo "🚀 Deploying CORS Fix to Railway"
echo "================================="

# Check if we're in the correct directory
if [ ! -f "manage.py" ]; then
    echo "❌ Error: Please run this script from the gym_backend directory"
    exit 1
fi

echo "📋 Changes being deployed:"
echo "• Added specific Netlify domain to CORS_ALLOWED_ORIGINS"
echo "• Enhanced CORS headers configuration"
echo "• Added CORS_ALLOW_METHODS configuration"
echo ""

# Add and commit changes
echo "📝 Committing changes..."
git add .
git commit -m "Fix CORS configuration for Netlify deployment

- Add specific Netlify domain to CORS_ALLOWED_ORIGINS
- Add comprehensive CORS headers configuration
- Add CORS_ALLOW_METHODS for better web compatibility
- Fix web app registration connectivity issues"

echo "🚀 Deploying to Railway..."
git push origin main

echo ""
echo "✅ Deployment initiated!"
echo ""
echo "📋 Next steps:"
echo "1. Wait 2-3 minutes for Railway to rebuild"
echo "2. Test the web app registration"
echo "3. Check Railway logs if issues persist"
echo ""
echo "🔗 Railway Dashboard: https://railway.app/dashboard"
echo "🔗 Live App: https://gym-management-production-4343.up.railway.app/"