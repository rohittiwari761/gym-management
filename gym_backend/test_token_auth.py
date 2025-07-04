#!/usr/bin/env python3
"""
Test script to verify Django token authentication is working.
"""

import requests
import json

def test_login_and_members():
    """Test login and then access protected endpoints."""
    base_url = "https://gym-management-production-4343.up.railway.app"
    
    # Test login
    print("🔐 Testing login...")
    login_response = requests.post(
        f"{base_url}/api/auth/login/",
        json={
            "email": "test@gym.com",
            "password": "TestPass123!"
        },
        headers={"Content-Type": "application/json"}
    )
    
    print(f"Login Status: {login_response.status_code}")
    if login_response.status_code == 200:
        login_data = login_response.json()
        print(f"✅ Login Success: {login_data.get('message', 'Success')}")
        token = login_data.get('token')
        print(f"🔑 Token received: {token[:20]}..." if token else "❌ No token in response")
        
        if token:
            # Test protected endpoint
            print("\n📊 Testing protected endpoint with token...")
            
            # Test members endpoint
            members_response = requests.get(
                f"{base_url}/api/members/",
                headers={
                    "Authorization": f"Token {token}",
                    "Content-Type": "application/json"
                }
            )
            
            print(f"Members Status: {members_response.status_code}")
            if members_response.status_code == 200:
                print("✅ Members endpoint accessible with token")
                members_data = members_response.json()
                print(f"Members count: {len(members_data.get('results', []))}")
            else:
                print(f"❌ Members endpoint failed: {members_response.text}")
            
            # Test trainers endpoint
            trainers_response = requests.get(
                f"{base_url}/api/trainers/",
                headers={
                    "Authorization": f"Token {token}",
                    "Content-Type": "application/json"
                }
            )
            
            print(f"Trainers Status: {trainers_response.status_code}")
            if trainers_response.status_code == 200:
                print("✅ Trainers endpoint accessible with token")
            else:
                print(f"❌ Trainers endpoint failed: {trainers_response.text}")
        
    else:
        print(f"❌ Login failed: {login_response.text}")

def test_without_token():
    """Test endpoints without token (should get 401)."""
    print("\n🚫 Testing without token (should get 401)...")
    base_url = "https://gym-management-production-4343.up.railway.app"
    
    response = requests.get(f"{base_url}/api/members/")
    print(f"No token status: {response.status_code} (Expected: 401)")
    
if __name__ == "__main__":
    print("🧪 Testing Django Token Authentication...")
    print("=" * 50)
    
    test_login_and_members()
    test_without_token()
    
    print("=" * 50)
    print("🧪 Test completed.")