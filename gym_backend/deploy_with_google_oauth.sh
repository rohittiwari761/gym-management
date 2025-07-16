#!/bin/bash

# Deploy Backend with Google OAuth Configuration
# This script sets up Railway environment variables and deploys

echo "🚀 Deploying Gym Management Backend with Google OAuth..."
echo "========================================================"

# Navigate to backend directory
cd "$(dirname "$0")"

# Set Railway environment variables for Google OAuth
echo "🔧 Setting Railway environment variables..."

# Set Google OAuth credentials
railway variables set GOOGLE_OAUTH2_CLIENT_ID="818835282138-8h3qf505eco222l28feg0o1t3tvu0v8g.apps.googleusercontent.com"
railway variables set GOOGLE_OAUTH2_CLIENT_SECRET="GOCSPX-YOUR-CLIENT-SECRET-HERE"

# Set Django settings
railway variables set DJANGO_SETTINGS_MODULE="gym_backend.settings_production"

# Deploy to Railway
echo "🚀 Deploying to Railway..."
railway up

echo ""
echo "✅ Deployment completed!"
echo ""
echo "📋 Environment variables set:"
echo "   - GOOGLE_OAUTH2_CLIENT_ID: 818835282138-8h3qf505eco222l28feg0o1t3tvu0v8g.apps.googleusercontent.com"
echo "   - GOOGLE_OAUTH2_CLIENT_SECRET: [HIDDEN]"
echo "   - DJANGO_SETTINGS_MODULE: gym_backend.settings_production"
echo ""
echo "🔍 To verify deployment:"
echo "   railway logs"
echo "   curl https://gym-management-production-2168.up.railway.app/api/"
echo ""
echo "⚠️  Don't forget to replace YOUR-CLIENT-SECRET-HERE with actual secret!"