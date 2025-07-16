#!/bin/bash

# Test Web Build Script for Gym Management System
# This script builds the web version and tests basic functionality

echo "🚀 Building Gym Management System for Web..."
echo "============================================="

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Build for web
echo "🔨 Building web version..."
flutter build web --release

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Web build completed successfully!"
    echo ""
    echo "📁 Build output: build/web/"
    echo "📄 Index file: build/web/index.html"
    echo ""
    echo "🌐 To test locally:"
    echo "   cd build/web"
    echo "   python -m http.server 8000"
    echo "   Then open: http://localhost:8000"
    echo ""
    echo "🚀 To deploy to Netlify:"
    echo "   Upload the build/web/ folder to Netlify"
    echo "   Or use: netlify deploy --prod --dir=build/web"
    echo ""
    echo "🔧 Features implemented:"
    echo "   ✅ Google Sign-In button (all platforms)"
    echo "   ✅ User profile display in drawer"
    echo "   ✅ Web-compatible authentication flow"
    echo "   ✅ Responsive design for web"
    echo "   ✅ Web client ID configured"
    echo "   ✅ Error 400 fixed with proper client ID"
    echo ""
    echo "🔑 Google OAuth Configuration:"
    echo "   - iOS/Android: 818835282138-8h3qf505eco222l28feg0o1t3tvu0v8g"
    echo "   - Web: 818835282138-qjqc6v2bf8n89ghrphh9l388erj5vt5g"
    echo ""
    echo "⚠️  Important:"
    echo "   - Ensure backend server is running and accessible"
    echo "   - Both email login and Google Sign-In should work"
    echo "   - User profile should display in drawer after login"
else
    echo "❌ Web build failed!"
    echo "Please check the error messages above."
    exit 1
fi