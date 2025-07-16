#!/usr/bin/env python3
"""
Test script to verify Google OAuth configuration on Railway
"""
import os
import sys
import django
from pathlib import Path

# Add the backend directory to the Python path
BASE_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(BASE_DIR))

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'gym_backend.settings_production')
django.setup()

from django.conf import settings

def test_google_oauth_config():
    """Test Google OAuth configuration"""
    print("🔍 Testing Google OAuth Configuration on Railway")
    print("=" * 50)
    
    # Test 1: Check environment variables
    print("\n1. Environment Variables:")
    client_id = os.getenv('GOOGLE_OAUTH2_CLIENT_ID')
    client_secret = os.getenv('GOOGLE_OAUTH2_CLIENT_SECRET')
    
    print(f"   GOOGLE_OAUTH2_CLIENT_ID: {'✅ SET' if client_id else '❌ NOT SET'}")
    if client_id:
        print(f"   Client ID: {client_id[:20]}...")
    
    print(f"   GOOGLE_OAUTH2_CLIENT_SECRET: {'✅ SET' if client_secret else '❌ NOT SET'}")
    if client_secret:
        print(f"   Client Secret: {client_secret[:10]}...")
    
    # Test 2: Check Django settings
    print("\n2. Django Settings:")
    try:
        settings_client_id = getattr(settings, 'GOOGLE_OAUTH2_CLIENT_ID', None)
        settings_client_secret = getattr(settings, 'GOOGLE_OAUTH2_CLIENT_SECRET', None)
        
        print(f"   settings.GOOGLE_OAUTH2_CLIENT_ID: {'✅ SET' if settings_client_id else '❌ NOT SET'}")
        print(f"   settings.GOOGLE_OAUTH2_CLIENT_SECRET: {'✅ SET' if settings_client_secret else '❌ NOT SET'}")
        
        if settings_client_id:
            print(f"   Settings Client ID: {settings_client_id[:20]}...")
        
    except Exception as e:
        print(f"   ❌ Error accessing Django settings: {e}")
    
    # Test 3: Test Google library import
    print("\n3. Google Auth Library:")
    try:
        from google.auth.transport import requests as google_requests
        from google.oauth2 import id_token
        print("   ✅ Google auth library imported successfully")
    except ImportError as e:
        print(f"   ❌ Google auth library import failed: {e}")
    
    # Test 4: Test token verification (with dummy token)
    print("\n4. Token Verification Test:")
    if client_id and client_secret:
        try:
            # This will fail but we can see the error
            dummy_token = "dummy_token_for_testing"
            idinfo = id_token.verify_oauth2_token(
                dummy_token, 
                google_requests.Request(), 
                client_id
            )
            print("   ✅ Token verification setup working")
        except Exception as e:
            if "Invalid token" in str(e) or "Unable to verify" in str(e):
                print("   ✅ Token verification setup working (expected failure with dummy token)")
            else:
                print(f"   ❌ Token verification setup error: {e}")
    else:
        print("   ⚠️  Skipping token verification test (missing credentials)")
    
    # Test 5: Database connection
    print("\n5. Database Connection:")
    try:
        from django.db import connection
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            print("   ✅ Database connection successful")
    except Exception as e:
        print(f"   ❌ Database connection failed: {e}")
    
    print("\n" + "=" * 50)
    print("🎯 Configuration Status:")
    
    if client_id and client_secret:
        print("✅ Google OAuth credentials are configured")
        print("✅ Ready for Google Sign-In")
    else:
        print("❌ Google OAuth credentials missing")
        print("❌ Google Sign-In will not work")
    
    print("\n🔧 Next Steps:")
    if not client_id or not client_secret:
        print("1. Set Railway environment variables:")
        print("   railway variables --set 'GOOGLE_OAUTH2_CLIENT_ID=your_client_id'")
        print("   railway variables --set 'GOOGLE_OAUTH2_CLIENT_SECRET=your_client_secret'")
        print("2. Redeploy: railway up")
    else:
        print("1. Configuration looks good!")
        print("2. Test with actual Google token from frontend")

if __name__ == "__main__":
    test_google_oauth_config()