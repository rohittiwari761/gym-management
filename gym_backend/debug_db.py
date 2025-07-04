#!/usr/bin/env python3
"""
Debug script to check Railway environment variables
"""

import os
import sys

print("🔍 Railway Environment Debug")
print("=" * 50)

# Check for DATABASE_URL
database_url = os.environ.get('DATABASE_URL')
if database_url:
    print("✅ DATABASE_URL found:")
    # Mask the password for security
    masked_url = database_url.replace(database_url.split(':')[2].split('@')[0], "***")
    print(f"   {masked_url}")
else:
    print("❌ DATABASE_URL not found")

# Check other environment variables
env_vars = [
    'DJANGO_SETTINGS_MODULE',
    'DEBUG',
    'ALLOWED_HOSTS',
    'PORT',
    'RAILWAY_ENVIRONMENT'
]

print("\n🔧 Other Environment Variables:")
for var in env_vars:
    value = os.environ.get(var, 'Not set')
    print(f"   {var}: {value}")

print("\n🌐 Railway-specific Variables:")
railway_vars = [k for k in os.environ.keys() if 'RAILWAY' in k]
for var in railway_vars:
    print(f"   {var}: {os.environ[var]}")

print("\n" + "=" * 50)
print("🎯 Django Settings Check")

try:
    import django
    from django.conf import settings
    
    # Set up Django
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'gym_backend.settings_production')
    django.setup()
    
    print("✅ Django setup successful")
    print(f"   Database Engine: {settings.DATABASES['default']['ENGINE']}")
    print(f"   Database Name: {settings.DATABASES['default'].get('NAME', 'Not set')}")
    print(f"   Database Host: {settings.DATABASES['default'].get('HOST', 'Not set')}")
    
except Exception as e:
    print(f"❌ Django setup failed: {e}")

print("=" * 50)