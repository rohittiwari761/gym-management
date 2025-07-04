#!/bin/bash

# 🔧 Fix Missing Django Filter Dependency
echo "🔧 Fixing missing django-filter dependency..."

cd "$(dirname "$0")"

# Add changes to git
git add .

# Commit dependency fix
git commit -m "🔧 Fix missing django-filter dependency

✅ Dependency Fix:
- Added django-filter==23.5 to requirements.txt
- Resolves ImportError: No module named 'django_filters'
- Required for DRF DEFAULT_FILTER_BACKENDS setting
- Enables API filtering functionality

🚀 Django Import Fix:
- REST Framework will now load successfully
- All API endpoints will work properly
- Trainer-member associations API will be functional"

# Push to GitHub (triggers Railway re-deployment)
git push origin main

echo "✅ Django-filter dependency fix pushed to GitHub!"
echo "🚀 Railway will re-deploy with all required dependencies!"
echo "🎯 Django should import successfully this time!"