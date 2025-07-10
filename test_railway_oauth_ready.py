#!/usr/bin/env python3
"""
Test that Railway Google OAuth is properly configured and ready
"""
import subprocess
import json

def test_oauth_readiness():
    print("🔍 Testing Railway Google OAuth Configuration...")
    print("=" * 50)
    
    # Test 1: Endpoint availability
    print("📡 Test 1: Endpoint Availability")
    try:
        result = subprocess.run([
            'curl', '-s', '-X', 'POST',
            'https://gym-management-production-4343.up.railway.app/api/auth/google/',
            '-H', 'Content-Type: application/json',
            '-d', '{"google_token": "invalid_test_token"}',
            '-w', '%{http_code}'
        ], capture_output=True, text=True, timeout=10)
        
        # Split response and status code
        output = result.stdout
        if len(output) > 3 and output[-3:].isdigit():
            response_body = output[:-3]
            status_code = output[-3:]
        else:
            response_body = output
            status_code = "unknown"
        
        print(f"   Status Code: {status_code}")
        print(f"   Response: {response_body}")
        
        if status_code == "401":
            try:
                data = json.loads(response_body)
                error = data.get('error', '')
                
                if 'Invalid Google token' in error:
                    print("   ✅ Endpoint working - properly validates tokens")
                    endpoint_ok = True
                elif 'GOOGLE_OAUTH2_CLIENT_ID' in error:
                    print("   ❌ Environment variables not loaded")
                    endpoint_ok = False
                else:
                    print(f"   ⚠️ Unexpected error: {error}")
                    endpoint_ok = False
            except json.JSONDecodeError:
                print("   ❌ Invalid JSON response")
                endpoint_ok = False
        else:
            print(f"   ❌ Unexpected status code: {status_code}")
            endpoint_ok = False
            
    except Exception as e:
        print(f"   ❌ Request failed: {e}")
        endpoint_ok = False
    
    print()
    
    # Test 2: Missing token handling
    print("📡 Test 2: Missing Token Handling")
    try:
        result = subprocess.run([
            'curl', '-s', '-X', 'POST',
            'https://gym-management-production-4343.up.railway.app/api/auth/google/',
            '-H', 'Content-Type: application/json',
            '-d', '{}',
            '-w', '%{http_code}'
        ], capture_output=True, text=True, timeout=10)
        
        output = result.stdout
        if len(output) > 3 and output[-3:].isdigit():
            response_body = output[:-3]
            status_code = output[-3:]
        else:
            response_body = output
            status_code = "unknown"
        
        print(f"   Status Code: {status_code}")
        print(f"   Response: {response_body}")
        
        if status_code == "400":
            try:
                data = json.loads(response_body)
                error = data.get('error', '')
                if 'Google token is required' in error:
                    print("   ✅ Properly handles missing tokens")
                    missing_token_ok = True
                else:
                    print(f"   ⚠️ Unexpected error: {error}")
                    missing_token_ok = False
            except json.JSONDecodeError:
                print("   ❌ Invalid JSON response")
                missing_token_ok = False
        else:
            print(f"   ❌ Unexpected status code: {status_code}")
            missing_token_ok = False
            
    except Exception as e:
        print(f"   ❌ Request failed: {e}")
        missing_token_ok = False
    
    print()
    print("=" * 50)
    print("🏁 Summary:")
    print(f"   Endpoint Working: {'✅' if endpoint_ok else '❌'}")
    print(f"   Token Validation: {'✅' if missing_token_ok else '❌'}")
    
    if endpoint_ok and missing_token_ok:
        print("\n🎉 Google OAuth is ready! Flutter app should now be able to sign in.")
        print("📱 Try Google Sign-In from the Flutter app now.")
    else:
        print("\n❌ Google OAuth configuration needs attention.")
    
    return endpoint_ok and missing_token_ok

if __name__ == "__main__":
    test_oauth_readiness()