#!/usr/bin/env python3
"""
Authentication Test Script for Gym Management System
Tests login/registration endpoints to ensure authentication is working properly.
"""

import requests
import json
import sys

# Configuration
BASE_URL = "http://192.168.1.7:8001/api"
HEADERS = {"Content-Type": "application/json"}

def test_login():
    """Test login endpoint"""
    print("🔐 Testing Login Endpoint...")
    
    login_data = {
        "email": "test@gym.com",
        "password": "testpass123"
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/auth/login/", 
            headers=HEADERS,
            data=json.dumps(login_data),
            timeout=10
        )
        
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                print("✅ Login successful!")
                print(f"   Token: {data['token'][:20]}...")
                print(f"   User: {data['user']['first_name']} {data['user']['last_name']}")
                print(f"   Gym: {data['gym_owner']['gym_name']}")
                return data['token']
            else:
                print("❌ Login failed - API returned success=false")
                print(f"   Error: {data.get('error', 'Unknown error')}")
        else:
            print(f"❌ Login failed - HTTP {response.status_code}")
            try:
                error_data = response.json()
                print(f"   Error: {error_data.get('error', 'Unknown error')}")
            except:
                print(f"   Raw response: {response.text[:200]}")
                
    except requests.exceptions.RequestException as e:
        print(f"❌ Login failed - Network error: {e}")
    
    return None

def test_protected_endpoint(token):
    """Test a protected endpoint with authentication"""
    print("\n🔒 Testing Protected Endpoint...")
    
    if not token:
        print("❌ Skipping protected endpoint test - no token available")
        return
    
    try:
        response = requests.get(
            f"{BASE_URL}/members/",
            headers={
                **HEADERS,
                "Authorization": f"Token {token}"
            },
            timeout=10
        )
        
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Protected endpoint successful!")
            print(f"   Retrieved {len(data)} members")
        else:
            print(f"❌ Protected endpoint failed - HTTP {response.status_code}")
            try:
                error_data = response.json()
                print(f"   Error: {error_data}")
            except:
                print(f"   Raw response: {response.text[:200]}")
                
    except requests.exceptions.RequestException as e:
        print(f"❌ Protected endpoint failed - Network error: {e}")

def test_registration():
    """Test registration endpoint"""
    print("\n📝 Testing Registration Endpoint...")
    
    import time
    unique_email = f"testuser{int(time.time())}@gym.com"
    
    registration_data = {
        "email": unique_email,
        "password": "testpass123",
        "first_name": "Test",
        "last_name": "User",
        "gym_name": "Test Registration Gym",
        "gym_address": "Test Address",
        "gym_description": "Test gym description"
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/auth/register/",
            headers=HEADERS,
            data=json.dumps(registration_data),
            timeout=10
        )
        
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 201:
            data = response.json()
            if data.get('success'):
                print("✅ Registration successful!")
                print(f"   Token: {data['token'][:20]}...")
                print(f"   User: {data['user']['first_name']} {data['user']['last_name']}")
                print(f"   Gym: {data['gym_owner']['gym_name']}")
                return True
            else:
                print("❌ Registration failed - API returned success=false")
                print(f"   Error: {data.get('error', 'Unknown error')}")
        else:
            print(f"❌ Registration failed - HTTP {response.status_code}")
            try:
                error_data = response.json()
                print(f"   Error: {error_data.get('error', 'Unknown error')}")
            except:
                print(f"   Raw response: {response.text[:200]}")
                
    except requests.exceptions.RequestException as e:
        print(f"❌ Registration failed - Network error: {e}")
    
    return False

def main():
    """Run all authentication tests"""
    print("🚀 Gym Management System - Authentication Test Suite")
    print("=" * 60)
    
    # Test login
    token = test_login()
    
    # Test protected endpoint if login successful
    test_protected_endpoint(token)
    
    # Test registration
    test_registration()
    
    print("\n" + "=" * 60)
    if token:
        print("✅ Authentication system is working correctly!")
        print("🎉 Your Flutter app should now be able to authenticate successfully.")
    else:
        print("❌ Authentication issues detected.")
        print("🔧 Please check Django server logs and configuration.")

if __name__ == "__main__":
    main()