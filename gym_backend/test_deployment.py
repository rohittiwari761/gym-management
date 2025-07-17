#!/usr/bin/env python3
"""
Test script to validate Django settings before Railway deployment
"""
import os
import sys
import django
from pathlib import Path

# Add the backend directory to the Python path
BASE_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(BASE_DIR))

def test_settings():
    """Test Django settings for deployment readiness"""
    print("🔍 Testing Django settings for Railway deployment...")
    
    # Test environment variables
    settings_module = os.environ.get('DJANGO_SETTINGS_MODULE', 'gym_backend.settings_production')
    print(f"📋 Settings module: {settings_module}")
    
    # Set required environment variables for testing
    os.environ.setdefault('DATABASE_URL', 'sqlite:///test.db')
    os.environ.setdefault('DJANGO_SECRET_KEY', 'test-secret-key-for-validation')
    
    try:
        # Set Django settings
        os.environ.setdefault('DJANGO_SETTINGS_MODULE', settings_module)
        django.setup()
        
        from django.conf import settings
        from django.core.management import execute_from_command_line
        
        print("✅ Django settings imported successfully")
        
        # Test critical settings
        print(f"✅ DEBUG: {settings.DEBUG}")
        print(f"✅ ALLOWED_HOSTS: {len(settings.ALLOWED_HOSTS)} hosts configured")
        print(f"✅ SECRET_KEY: {'SET' if settings.SECRET_KEY else 'NOT SET'}")
        print(f"✅ DATABASE: {settings.DATABASES['default']['ENGINE']}")
        
        # Test CORS settings
        print(f"✅ CORS_ALLOW_ALL_ORIGINS: {settings.CORS_ALLOW_ALL_ORIGINS}")
        print(f"✅ CORS_ALLOWED_ORIGINS: {len(settings.CORS_ALLOWED_ORIGINS)} origins configured")
        
        # Validate CORS origins
        for origin in settings.CORS_ALLOWED_ORIGINS:
            if not origin.strip():
                print(f"❌ EMPTY CORS ORIGIN FOUND: '{origin}'")
                return False
            if not origin.startswith(('http://', 'https://')):
                print(f"❌ INVALID CORS ORIGIN: '{origin}' (missing scheme)")
                return False
        
        # Validate ALLOWED_HOSTS
        for host in settings.ALLOWED_HOSTS:
            if not host.strip() and host != '':
                print(f"❌ EMPTY ALLOWED_HOST FOUND: '{host}'")
                return False
        
        # Test Google OAuth settings
        google_client_id = getattr(settings, 'GOOGLE_OAUTH2_CLIENT_ID', None)
        google_client_secret = getattr(settings, 'GOOGLE_OAUTH2_CLIENT_SECRET', None)
        print(f"✅ Google OAuth Client ID: {'SET' if google_client_id else 'NOT SET'}")
        print(f"✅ Google OAuth Client Secret: {'SET' if google_client_secret else 'NOT SET'}")
        
        # Test system check
        print("🔍 Running Django system check...")
        from django.core.management.commands.check import Command as CheckCommand
        check_command = CheckCommand()
        
        # Run check with no output capture to see errors
        try:
            execute_from_command_line(['manage.py', 'check'])
            print("✅ Django system check passed")
        except SystemExit as e:
            if e.code != 0:
                print(f"❌ Django system check failed with exit code {e.code}")
                return False
        
        print("\n🎉 All settings validation checks passed!")
        print("🚀 Ready for Railway deployment!")
        return True
        
    except Exception as e:
        print(f"❌ Settings validation failed: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = test_settings()
    sys.exit(0 if success else 1)