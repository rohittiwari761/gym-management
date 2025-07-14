#!/bin/bash

echo "🚀 Building Flutter Web App for Netlify..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build for web
echo "🌐 Building for web..."
flutter build web --release

# Create _redirects file for SPA routing
echo "🔄 Creating redirects for SPA..."
echo "/*    /index.html   200" > build/web/_redirects

# Optional: Create a simple health check endpoint
echo "✅ Creating health check..."
echo "OK" > build/web/health

echo "✨ Build complete!"
echo ""
echo "📂 Your web app is ready in: build/web/"
echo ""
echo "🌐 Next steps for Netlify:"
echo "1. Go to https://netlify.com"
echo "2. Drag the 'build/web' folder to deploy"
echo "3. Or connect your GitHub repo for auto-deployment"
echo ""
echo "🔗 Your app will be available at: https://[random-name].netlify.app"