#!/bin/bash

# 🚀 Push Gym Management System to GitHub
# Run this script to automatically push your code

set -e  # Exit on any error

echo "🎯 Starting GitHub push process..."

# Navigate to project directory
cd "$(dirname "$0")"
echo "📁 Current directory: $(pwd)"

# Check if git is initialized
if [ ! -d ".git" ]; then
    echo "🔧 Initializing git repository..."
    git init
fi

# Add all files
echo "📦 Adding all files to git..."
git add .

# Check if there are changes to commit
if git diff --staged --quiet; then
    echo "ℹ️  No changes to commit"
else
    echo "💾 Creating commit..."
    git commit -m "🎉 Complete Gym Management System

✨ Features:
- Django REST API backend with JWT authentication
- Flutter mobile app with trainer-member associations  
- Real-time de-association functionality (FIXED)
- Multi-tenant gym owner isolation
- Production-ready with Railway deployment

🏗️ Backend (Django):
- TrainerMemberAssociation model implemented
- API endpoints for association/de-association
- PostgreSQL database with migrations
- Production settings & Docker support

📱 Frontend (Flutter):
- Fixed trainer association UI
- De-association functionality working
- Real database integration (no more fake data)
- Material Design with responsive layouts

🚀 DevOps:
- Railway deployment configuration
- GitHub Actions CI/CD pipeline
- Docker containers for production
- Environment-based configurations"
fi

# Check if remote origin exists
if git remote | grep -q "origin"; then
    echo "🔗 Remote origin already exists, removing..."
    git remote remove origin
fi

# Add GitHub remote
echo "🔗 Adding GitHub remote..."
git remote add origin https://github.com/rohittiwari761/gym-management.git

# Set main branch and push
echo "🚀 Pushing to GitHub..."
git branch -M main
git push -u origin main

echo "✅ Successfully pushed to GitHub!"
echo "🌐 Repository: https://github.com/rohittiwari761/gym-management"
echo ""
echo "🎯 Next steps:"
echo "1. Go to https://railway.app"
echo "2. Click 'New Project' > 'Deploy from GitHub repo'"
echo "3. Select 'rohittiwari761/gym-management'"
echo "4. Set root directory to 'gym_backend'"
echo "5. Add PostgreSQL database"
echo ""
echo "🚀 Your gym management system will be live!"