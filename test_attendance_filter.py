#!/usr/bin/env python3
"""
Test script to verify that attendance date filtering is working correctly
"""

import requests
import json
from datetime import datetime, date

# Test configuration
BASE_URL = "http://127.0.0.1:8000/api"
AUTH_TOKEN = "your_auth_token_here"  # Replace with actual token

def test_attendance_filtering():
    """Test the attendance filtering functionality"""
    print("🧪 Testing attendance date filtering...")
    
    # Test 1: Get attendances for today
    print("\n1. Testing today's attendance...")
    today = date.today().strftime('%Y-%m-%d')
    
    response = requests.get(
        f"{BASE_URL}/attendance/",
        headers={"Authorization": f"Token {AUTH_TOKEN}"},
        params={"date": today}
    )
    
    print(f"   Request URL: {response.url}")
    print(f"   Status Code: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        print(f"   Response: {json.dumps(data, indent=2)}")
    else:
        print(f"   Error: {response.text}")
    
    # Test 2: Get attendances for a specific historical date
    print("\n2. Testing historical date (2025-07-08)...")
    historical_date = "2025-07-08"
    
    response = requests.get(
        f"{BASE_URL}/attendance/",
        headers={"Authorization": f"Token {AUTH_TOKEN}"},
        params={"date": historical_date}
    )
    
    print(f"   Request URL: {response.url}")
    print(f"   Status Code: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        print(f"   Response: {json.dumps(data, indent=2)}")
    else:
        print(f"   Error: {response.text}")

if __name__ == "__main__":
    test_attendance_filtering()