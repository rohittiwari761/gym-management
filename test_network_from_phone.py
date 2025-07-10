#!/usr/bin/env python3
"""
Test script to verify network connectivity from different devices
Run this to help debug iPhone -> Mac connectivity
"""
import socket
import requests
import subprocess
import sys

def test_port_open(host, port, timeout=5):
    """Test if a port is open on a host"""
    try:
        socket.create_connection((host, port), timeout=timeout)
        return True
    except (socket.timeout, ConnectionRefusedError, OSError):
        return False

def get_network_info():
    """Get network information"""
    print("🌐 Network Information:")
    print("=" * 50)
    
    # Get all network interfaces
    try:
        result = subprocess.run(['ifconfig'], capture_output=True, text=True)
        lines = result.stdout.split('\n')
        
        for line in lines:
            if 'inet ' in line and '127.0.0.1' not in line:
                parts = line.strip().split()
                if len(parts) >= 2:
                    ip = parts[1]
                    print(f"📍 Network IP: {ip}")
                    
                    # Test if Django is accessible on this IP
                    if test_port_open(ip, 8000):
                        print(f"✅ Port 8000 open on {ip}")
                        
                        # Test HTTP request
                        try:
                            response = requests.get(f'http://{ip}:8000/api/', timeout=3)
                            print(f"✅ HTTP request successful: {response.status_code}")
                        except Exception as e:
                            print(f"❌ HTTP request failed: {e}")
                    else:
                        print(f"❌ Port 8000 closed on {ip}")
    except Exception as e:
        print(f"Error getting network info: {e}")

def test_endpoints():
    """Test all possible endpoint URLs"""
    print("\n🔍 Testing Endpoint URLs:")
    print("=" * 50)
    
    urls = [
        'http://127.0.0.1:8000/api/',
        'http://localhost:8000/api/',
        'http://192.168.1.13:8000/api/',
    ]
    
    for url in urls:
        try:
            print(f"Testing: {url}")
            response = requests.get(url, timeout=3)
            print(f"✅ Status: {response.status_code}")
        except requests.exceptions.ConnectionError:
            print(f"❌ Connection refused")
        except requests.exceptions.Timeout:
            print(f"⏱️ Timeout")
        except Exception as e:
            print(f"💥 Error: {e}")
        print("-" * 30)

def instructions_for_phone():
    """Print instructions for testing from phone"""
    print("\n📱 Instructions for testing from your iPhone:")
    print("=" * 50)
    print("1. Open Safari on your iPhone")
    print("2. Navigate to: http://192.168.1.13:8000/api/")
    print("3. You should see a JSON response with 'detail' field")
    print("4. If you see 'This site can't be reached', there's a network issue")
    print("5. Make sure both devices are on the same WiFi network")
    print("\n🔧 If iPhone can't reach the server:")
    print("• Check Mac firewall settings (System Preferences > Security & Privacy > Firewall)")
    print("• Ensure both devices are on same WiFi network")
    print("• Try restarting Django server: python manage.py runserver 0.0.0.0:8000")

if __name__ == "__main__":
    get_network_info()
    test_endpoints()
    instructions_for_phone()