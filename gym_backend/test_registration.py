#!/usr/bin/env python3
"""
Test script to verify registration endpoint is working.
"""

import requests
import json

# Test data for registration - all required fields
test_data = {
    "email": "test@gym.com",
    "password": "TestPass123!",
    "first_name": "Test",
    "last_name": "User",
    "gym_name": "Test Gym",
    "phone_number": "1234567890",  # Changed from 'phone' to 'phone_number'
    "gym_address": "123 Test Street, Test City",  # Changed from 'address' to 'gym_address'
    "gym_description": "A test gym for testing purposes"
}

def test_health():
    """Test health endpoint."""
    try:
        response = requests.get("https://gym-management-production-4343.up.railway.app/health/")
        print(f"✅ Health Check: {response.status_code} - {response.json()}")
        return True
    except Exception as e:
        print(f"❌ Health Check Failed: {e}")
        return False

def test_registration():
    """Test registration endpoint."""
    try:
        response = requests.post(
            "https://gym-management-production-4343.up.railway.app/api/auth/register/",
            json=test_data,
            headers={"Content-Type": "application/json"}
        )
        print(f"📝 Registration: {response.status_code}")
        if response.status_code == 201:
            print(f"✅ Registration Success: {response.json()}")
        elif response.status_code == 400:
            print(f"⚠️ Registration Validation Error: {response.json()}")
        else:
            print(f"❌ Registration Error: {response.text}")
        return response.status_code
    except Exception as e:
        print(f"❌ Registration Failed: {e}")
        return None

def test_login():
    """Test login endpoint."""
    try:
        login_data = {
            "email": test_data["email"],
            "password": test_data["password"]
        }
        response = requests.post(
            "https://gym-management-production-4343.up.railway.app/api/auth/login/",
            json=login_data,
            headers={"Content-Type": "application/json"}
        )
        print(f"🔐 Login: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Login Success: Token received")
            return data.get('token')
        else:
            print(f"❌ Login Error: {response.text}")
        return None
    except Exception as e:
        print(f"❌ Login Failed: {e}")
        return None

if __name__ == "__main__":
    print("🧪 Testing Railway API Endpoints...")
    print("=" * 50)
    
    # Test health
    if not test_health():
        exit(1)
    
    # Test registration
    reg_status = test_registration()
    
    if reg_status == 201:
        # Test login if registration successful
        token = test_login()
        if token:
            print("✅ All tests passed! Authentication is working.")
        else:
            print("⚠️ Registration worked but login failed.")
    elif reg_status == 400:
        print("⚠️ Registration validation failed - check required fields.")
        # Try login anyway in case user exists
        test_login()
    else:
        print("❌ Registration failed with server error.")
    
    print("=" * 50)
    print("🧪 Testing completed.")