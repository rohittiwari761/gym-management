#!/bin/bash

echo "🚀 Gym Management System - Netlify Deployment"
echo "============================================="
echo ""

# Check if in correct directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Please run this script from the gym_frontend directory"
    echo "💡 Run: cd gym_frontend && ./deploy_to_netlify.sh"
    exit 1
fi

# Step 1: Clean and prepare
echo "🧹 Step 1: Cleaning project..."
flutter clean
rm -rf build/

# Step 2: Get dependencies
echo "📦 Step 2: Installing dependencies..."
flutter pub get

# Step 3: Check for web support
echo "🌐 Step 3: Ensuring web support..."
if [ ! -d "web" ]; then
    echo "⚠️  Creating web support..."
    flutter create --platforms web .
fi

# Step 4: Build for web
echo "🏗️  Step 4: Building for web (this may take a few minutes)..."
flutter build web --release --web-renderer html

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
else
    echo "❌ Build failed. Please check the errors above."
    exit 1
fi

# Step 5: Configure for SPA
echo "🔄 Step 5: Configuring Single Page Application..."
echo "/*    /index.html   200" > build/web/_redirects

# Step 6: Add health check
echo "✅ Step 6: Adding health check..."
echo "Gym Management System - $(date)" > build/web/health.txt

# Step 7: Show deployment info
echo ""
echo "🎉 SUCCESS! Your web app is ready for deployment!"
echo ""
echo "📁 Build location: $(pwd)/build/web/"
echo ""
echo "🌐 NEXT STEPS FOR NETLIFY DEPLOYMENT:"
echo ""
echo "METHOD 1 - Drag & Drop (Easiest):"
echo "  1. Go to https://netlify.com"
echo "  2. Sign up/Login"
echo "  3. Click 'Add new site' → 'Deploy manually'"
echo "  4. Drag the 'build/web' folder to the deploy area"
echo "  5. Get your live URL!"
echo ""
echo "METHOD 2 - GitHub Integration (Recommended for updates):"
echo "  1. Push your project to GitHub:"
echo "     git add ."
echo "     git commit -m 'Add web deployment'"
echo "     git push origin main"
echo "  2. In Netlify: 'Import from Git' → Select your repo"
echo "  3. Build settings:"
echo "     - Base directory: gym_frontend"
echo "     - Build command: flutter build web --release"
echo "     - Publish directory: build/web"
echo ""
echo "📱 FEATURES YOUR USERS WILL GET:"
echo "  ✅ Works on any device (mobile, tablet, desktop)"
echo "  ✅ Installable as app (Add to Home Screen)"
echo "  ✅ Automatic updates (no APK sharing needed)"
echo "  ✅ Offline caching"
echo "  ✅ Fast loading worldwide"
echo ""
echo "🔗 After deployment, share just one link with everyone!"
echo ""

# Optional: Open build folder
if command -v open >/dev/null 2>&1; then
    echo "📂 Opening build folder..."
    open build/web/
elif command -v xdg-open >/dev/null 2>&1; then
    echo "📂 Opening build folder..."
    xdg-open build/web/
fi

echo "🚀 Ready for deployment!"