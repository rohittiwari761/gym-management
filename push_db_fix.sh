#!/bin/bash

# Simple script to push database connection fix
cd /Users/rohittiwari/Downloads/flutter-projects/GYMPROJECT/gym-management-system

# Add all changes
git add .

# Commit with message
git commit -m "Fix Railway database connection configuration

- Improved DATABASE_URL detection from Railway environment
- Added explicit os.environ.get('DATABASE_URL') check
- Enhanced database configuration logic for Railway PostgreSQL
- Django will now properly use Railway's DATABASE_URL instead of localhost"

# Push to main branch
git push origin main

echo "Database connection fix pushed to GitHub!"
echo "Railway will now re-deploy with proper PostgreSQL connection."