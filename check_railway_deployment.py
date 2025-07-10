#!/usr/bin/env python3
"""
Check if Railway has deployed the latest Google OAuth fix
"""
import subprocess
import time
import json

def check_deployment():
    print("🔍 Checking Railway deployment status...")
    
    # Test the Google OAuth endpoint
    try:
        result = subprocess.run([
            'curl', '-s', '-X', 'POST',
            'https://gym-management-production-4343.up.railway.app/api/auth/google/',
            '-H', 'Content-Type: application/json',
            '-d', '{"google_token": "test_invalid_token"}',
            '-w', '\n%{http_code}'
        ], capture_output=True, text=True, timeout=10)
        
        lines = result.stdout.strip().split('\n')
        response_body = '\n'.join(lines[:-1])
        status_code = lines[-1]
        
        print(f"📡 Status Code: {status_code}")
        print(f"📡 Response: {response_body}")
        
        if status_code == "401":
            try:
                data = json.loads(response_body)
                error_msg = data.get('error', '')
                
                if 'GOOGLE_OAUTH2_CLIENT_ID' in error_msg:
                    print("❌ Still using old deployment - environment variable error persists")
                    return False
                elif 'Invalid Google token' in error_msg:
                    print("✅ New deployment active - proper token validation working!")
                    return True
                else:
                    print(f"❓ Unexpected 401 error: {error_msg}")
                    return False
            except json.JSONDecodeError:
                print("⚠️ Could not parse JSON response")
                return False
        else:
            print(f"❓ Unexpected status code: {status_code}")
            return False
            
    except subprocess.TimeoutExpired:
        print("⏰ Request timed out")
        return False
    except Exception as e:
        print(f"❌ Error checking deployment: {e}")
        return False

def wait_for_deployment(max_wait_minutes=10):
    print(f"⏳ Waiting up to {max_wait_minutes} minutes for Railway deployment...")
    
    for attempt in range(max_wait_minutes * 2):  # Check every 30 seconds
        if check_deployment():
            print("🎉 Railway deployment is ready!")
            return True
        
        if attempt < (max_wait_minutes * 2) - 1:
            print(f"⏳ Waiting 30 seconds... (attempt {attempt + 1}/{max_wait_minutes * 2})")
            time.sleep(30)
    
    print("⏰ Timeout waiting for deployment")
    return False

if __name__ == "__main__":
    wait_for_deployment()