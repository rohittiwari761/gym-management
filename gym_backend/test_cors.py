#!/usr/bin/env python3
"""
Test CORS configuration for Django backend
"""
import requests
import json

# Test CORS preflight request
def test_cors_preflight():
    url = "https://gym-management-production-4343.up.railway.app/api/auth/register/"
    headers = {
        'Origin': 'https://shiny-chebakia-43b733.netlify.app',
        'Access-Control-Request-Method': 'POST',
        'Access-Control-Request-Headers': 'Content-Type',
    }
    
    print("Testing CORS preflight (OPTIONS request)...")
    try:
        response = requests.options(url, headers=headers)
        print(f"Status: {response.status_code}")
        print(f"Headers: {dict(response.headers)}")
        
        if 'Access-Control-Allow-Origin' in response.headers:
            print("✅ CORS preflight successful")
        else:
            print("❌ CORS preflight failed - missing Access-Control-Allow-Origin")
            
    except Exception as e:
        print(f"❌ CORS preflight error: {e}")

# Test actual POST request with CORS
def test_cors_post():
    url = "https://gym-management-production-4343.up.railway.app/api/auth/register/"
    headers = {
        'Origin': 'https://shiny-chebakia-43b733.netlify.app',
        'Content-Type': 'application/json',
    }
    
    data = {
        'first_name': 'Test',
        'last_name': 'User',
        'email': 'test@example.com',
        'password': 'testpassword123',
        'gym_name': 'Test Gym',
        'gym_address': 'Test Address',
        'gym_description': 'Test Description',
    }
    
    print("\nTesting CORS POST request...")
    try:
        response = requests.post(url, headers=headers, json=data)
        print(f"Status: {response.status_code}")
        print(f"Headers: {dict(response.headers)}")
        
        if 'Access-Control-Allow-Origin' in response.headers:
            print("✅ CORS POST successful")
        else:
            print("❌ CORS POST failed - missing Access-Control-Allow-Origin")
            
        if response.status_code == 400:
            print("Note: 400 status is expected for duplicate email, CORS is working")
            
    except Exception as e:
        print(f"❌ CORS POST error: {e}")

if __name__ == "__main__":
    test_cors_preflight()
    test_cors_post()