#!/usr/bin/env python3
"""
Test Google OAuth authentication with production Railway server
"""
import requests
import json

def test_google_auth():
    print("🔐 Testing Google OAuth on Railway production server...")
    
    # Test with invalid token first to check endpoint
    url = "https://gym-management-production-4343.up.railway.app/api/auth/google/"
    
    test_data = {
        "google_token": "invalid_test_token"
    }
    
    headers = {
        "Content-Type": "application/json",
        "User-Agent": "TestClient/1.0"
    }
    
    try:
        response = requests.post(url, json=test_data, headers=headers, timeout=10)
        
        print(f"📡 Status Code: {response.status_code}")
        print(f"📡 Response Headers: {dict(response.headers)}")
        print(f"📡 Response Body: {response.text}")
        
        if response.status_code == 401:
            try:
                error_data = response.json()
                if "Invalid Google token" in error_data.get("error", ""):
                    print("✅ Google OAuth endpoint is working - properly rejecting invalid tokens")
                    print("💡 This means the endpoint is configured correctly!")
                    print("🔑 Just need to set environment variables on Railway")
                else:
                    print(f"⚠️ Unexpected 401 error: {error_data}")
            except:
                print("⚠️ 401 response but couldn't parse JSON")
        elif response.status_code == 500:
            print("❌ Server error - likely missing environment variables")
        else:
            print(f"❓ Unexpected status code: {response.status_code}")
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Request failed: {e}")

if __name__ == "__main__":
    test_google_auth()