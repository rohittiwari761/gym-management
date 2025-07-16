#!/usr/bin/env python3
"""
Test Django settings for Railway deployment
"""
import os
import sys

# Set environment variables for testing
os.environ.setdefault('DATABASE_URL', 'postgresql://test:test@localhost:5432/test')
os.environ.setdefault('GOOGLE_OAUTH2_CLIENT_ID', 'test_client_id')
os.environ.setdefault('GOOGLE_OAUTH2_CLIENT_SECRET', 'test_client_secret')

try:
    # Try to import Django settings
    from gym_backend.settings_production import *
    print("✅ Django settings imported successfully")
    
    # Check critical settings
    print(f"✅ DEBUG: {DEBUG}")
    print(f"✅ ALLOWED_HOSTS: {ALLOWED_HOSTS}")
    print(f"✅ CORS_ALLOW_ALL_ORIGINS: {CORS_ALLOW_ALL_ORIGINS}")
    print(f"✅ CORS_ALLOW_ALL_HEADERS: {CORS_ALLOW_ALL_HEADERS}")
    print(f"✅ DATABASE ENGINE: {DATABASES['default']['ENGINE']}")
    
    # Check Google OAuth settings
    print(f"✅ GOOGLE_OAUTH2_CLIENT_ID: {locals().get('GOOGLE_OAUTH2_CLIENT_ID', 'NOT SET')}")
    print(f"✅ GOOGLE_OAUTH2_CLIENT_SECRET: {'SET' if locals().get('GOOGLE_OAUTH2_CLIENT_SECRET') else 'NOT SET'}")
    
    print("\n🎉 All settings loaded successfully!")
    
except Exception as e:
    print(f"❌ Error loading settings: {e}")
    import traceback
    traceback.print_exc()