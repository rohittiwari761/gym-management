#!/bin/bash

echo "🧹 Starting project cleanup..."

# Navigate to project root
cd /Users/rohittiwari/Downloads/flutter-projects/GYMPROJECT/gym-management-system

echo "📂 Cleaning Flutter frontend..."
cd gym_frontend

# Remove build artifacts
echo "  ⚡ Removing build artifacts..."
rm -rf build/
rm -rf android/build/
rm -rf android/.gradle/
rm -rf ios/Pods/
rm -rf ios/build/
rm -rf macos/Pods/

# Remove temporary and cache files
echo "  🗑️ Removing cache and temp files..."
find . -name "*.log" -delete
find . -name ".DS_Store" -delete
find . -name "Thumbs.db" -delete
find . -name "*.tmp" -delete

# Remove IDE and editor files
echo "  💻 Removing IDE files..."
rm -rf .vscode/
rm -rf .idea/
rm -f *.iml

# Remove Android local files
echo "  📱 Cleaning Android files..."
rm -f android/local.properties
rm -f android/gradle.properties

# Remove iOS generated files
echo "  🍎 Cleaning iOS files..."
rm -rf ios/.symlinks/
rm -rf ios/Runner.xcworkspace/xcuserdata/
rm -rf ios/Runner.xcodeproj/xcuserdata/
rm -rf ios/Pods/Pods.xcodeproj/xcuserdata/

# Remove test and debug files
echo "  🔬 Removing test files..."
rm -f test_*.dart
rm -f lib/main_simple.dart
rm -rf lib/screens/debug_screen.dart
rm -rf lib/screens/qr_scanner_screen_original.dart
rm -rf lib/screens/qr_scanner_screen_web.dart

# Clean up pubspec variants
echo "  📦 Cleaning pubspec variants..."
rm -f pubspec_*.yaml
rm -f devtools_options.yaml

echo "📂 Cleaning backend..."
cd ../gym_backend

# Remove Python cache
echo "  🐍 Removing Python cache..."
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "*.pyc" -delete
find . -name "*.pyo" -delete

# Remove database files (keep model but remove data)
echo "  🗄️ Removing database files..."
rm -f db.sqlite3
rm -f *.db

# Remove log files
echo "  📋 Removing log files..."
rm -f *.log
rm -f server.log

# Remove deployment artifacts
echo "  🚀 Removing deployment artifacts..."
rm -f railway.json
rm -f railway.toml
rm -f railway_minimal.toml
rm -f Procfile.minimal
rm -f gunicorn_simple.conf.py
rm -f nginx.conf

# Remove test files
echo "  🧪 Removing test files..."
rm -f test_*.py
rm -f debug_*.py

# Remove uploaded files (keep structure but remove files)
echo "  📁 Cleaning uploaded files..."
rm -f gym_owner_profiles/*.jpg
rm -f gym_owner_profiles/*.png

echo "📂 Cleaning project root..."
cd ..

# Remove root level unwanted files
echo "  🗂️ Removing root files..."
rm -f *.py
rm -f *.sh
rm -f *.html
rm -f setup_log.txt
rm -f .DS_Store

# Remove documentation files (keep essential ones)
echo "  📚 Cleaning documentation..."
rm -f ATTENDANCE_FIX_SUMMARY.md
rm -f MEMBERSHIP_MANAGEMENT_FEATURES.md
rm -f PAYMENT_SUBSCRIPTION_IMPROVEMENTS.md

# Remove virtual environment
echo "  🐍 Removing virtual environment..."
rm -rf venv/

echo "✅ Project cleanup completed!"
echo ""
echo "📊 Project size after cleanup:"
du -sh . 2>/dev/null || echo "Size calculation unavailable"
echo ""
echo "🚀 Ready for deployment!"