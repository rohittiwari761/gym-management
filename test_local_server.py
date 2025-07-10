#!/usr/bin/env python3
"""
Simple script to test local Django server connectivity
"""
import requests
import json
import sys

def test_server_health():
    """Test if the Django server is running and responsive"""
    urls_to_test = [
        'http://127.0.0.1:8000/api/',
        'http://127.0.0.1:8000/api/auth/login/',
        'http://127.0.0.1:8000/api/auth/google/',
    ]
    
    print("🔍 Testing Django server connectivity...")
    print("=" * 50)
    
    for url in urls_to_test:
        try:
            print(f"Testing: {url}")
            response = requests.get(url, timeout=5)
            print(f"✅ Status: {response.status_code}")
            
            # Try to parse as JSON if possible
            try:
                if response.content:
                    data = response.json()
                    print(f"📄 Response keys: {list(data.keys()) if isinstance(data, dict) else 'Not a dict'}")
                else:
                    print("📄 Empty response")
            except:
                print(f"📄 Response length: {len(response.content)} bytes")
            
        except requests.exceptions.ConnectionError:
            print(f"❌ Connection failed - Server not running on {url}")
        except requests.exceptions.Timeout:
            print(f"⏱️ Timeout - Server too slow to respond")
        except Exception as e:
            print(f"💥 Error: {e}")
        
        print("-" * 30)

def test_google_auth_endpoint():
    """Test the Google auth endpoint specifically"""
    print("\n🔐 Testing Google Auth endpoint...")
    print("=" * 50)
    
    url = 'http://127.0.0.1:8000/api/auth/google/'
    
    # Test with invalid token to see if endpoint exists
    test_data = {
        'google_token': 'test_token_12345'
    }
    
    try:
        response = requests.post(
            url, 
            json=test_data,
            headers={'Content-Type': 'application/json'},
            timeout=5
        )
        print(f"✅ Endpoint accessible - Status: {response.status_code}")
        
        try:
            data = response.json()
            print(f"📄 Response: {json.dumps(data, indent=2)}")
        except:
            print(f"📄 Raw response: {response.text[:200]}...")
            
    except requests.exceptions.ConnectionError:
        print(f"❌ Google auth endpoint not accessible")
        print("🔧 Please ensure:")
        print("   • Django server is running: python manage.py runserver")
        print("   • Google auth endpoint is configured in urls.py")
        print("   • google-auth package is installed: pip install google-auth")
    except Exception as e:
        print(f"💥 Error testing Google auth: {e}")

if __name__ == "__main__":
    test_server_health()
    test_google_auth_endpoint()
    
    print("\n📋 Next steps if server is not running:")
    print("1. Navigate to gym_backend directory")
    print("2. Activate virtual environment: source ../venv/bin/activate")
    print("3. Install requirements: pip install -r requirements.txt")
    print("4. Run server: python manage.py runserver")
    print("5. Test again: python test_local_server.py")