#!/usr/bin/env python3
"""
Check if Railway deployment has the timestamp we just added
"""
import subprocess
import time

def check_for_timestamp():
    print("🔍 Checking for deployment timestamp in server logs...")
    
    # Test various endpoints to trigger server startup logs
    endpoints = [
        "/api/auth/google/",
        "/api/auth/login/",
        "/api/auth/register/"
    ]
    
    for endpoint in endpoints:
        try:
            print(f"📡 Testing {endpoint}...")
            result = subprocess.run([
                'curl', '-s', '-X', 'POST',
                f'https://gym-management-production-4343.up.railway.app{endpoint}',
                '-H', 'Content-Type: application/json',
                '-d', '{"test": "trigger"}',
                '--max-time', '5'
            ], capture_output=True, text=True)
            
            print(f"   Response: {result.stdout[:100]}...")
            time.sleep(2)
            
        except Exception as e:
            print(f"   Error: {e}")
    
    print("\n🔍 If the deployment timestamp appears in your Railway logs,")
    print("   then the new version is deployed and Google OAuth should work.")
    print("   Look for: '🚀 DJANGO_SETTINGS: Deployment timestamp: July 10, 2025 - 09:40 IST'")

if __name__ == "__main__":
    check_for_timestamp()