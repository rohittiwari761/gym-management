#!/usr/bin/env python3
"""
Test Google OAuth configuration
"""
import os
import sys
import django
from django.conf import settings

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'gym_backend.settings')
django.setup()

from gym_api.google_auth import GoogleAuthService

def test_google_config():
    """Test Google OAuth configuration"""
    print("🔍 Testing Google OAuth Configuration")
    print("=" * 50)
    
    # Check Django settings
    client_id = getattr(settings, 'GOOGLE_OAUTH2_CLIENT_ID', 'NOT_SET')
    client_secret = getattr(settings, 'GOOGLE_OAUTH2_CLIENT_SECRET', 'NOT_SET')
    
    print(f"📋 Django GOOGLE_OAUTH2_CLIENT_ID: {client_id}")
    print(f"📋 Django GOOGLE_OAUTH2_CLIENT_SECRET: {'SET' if client_secret != 'NOT_SET' else 'NOT_SET'}")
    
    # Test with a fake token to see error handling
    print("\n🧪 Testing token verification with fake token...")
    fake_token = "fake.token.for.testing"
    
    try:
        result = GoogleAuthService.verify_google_token(fake_token)
        print(f"❌ Unexpected success: {result}")
    except Exception as e:
        print(f"✅ Expected failure: {type(e).__name__}: {e}")
    
    print("\n📱 Flutter Configuration Should Match:")
    print(f"   serverClientId: '{client_id}'")
    
    print("\n🔧 If Google Sign-In still fails:")
    print("1. Check that Google Console project has the correct Client ID")
    print("2. Ensure iOS bundle ID matches Google Console configuration")
    print("3. Verify GoogleService-Info.plist is correct")
    print("4. Make sure Google Sign-In is enabled in Google Console")

if __name__ == "__main__":
    test_google_config()