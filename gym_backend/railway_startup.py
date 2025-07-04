#!/usr/bin/env python3
"""
Railway startup script with network debugging.
"""

import os
import sys
import subprocess
import time

def log(message):
    """Log with timestamp."""
    print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {message}")

def main():
    """Main startup function."""
    log("🚀 Starting Railway deployment...")
    
    # Show environment variables
    port = os.environ.get('PORT', 'NOT_SET')
    database_url = os.environ.get('DATABASE_URL', 'NOT_SET')
    
    log(f"📊 Environment check:")
    log(f"   PORT: {port}")
    log(f"   DATABASE_URL: {'SET' if database_url != 'NOT_SET' else 'NOT_SET'}")
    log(f"   DJANGO_SETTINGS_MODULE: {os.environ.get('DJANGO_SETTINGS_MODULE', 'NOT_SET')}")
    
    # Network debugging
    log("🔍 Network debugging:")
    try:
        # Check if port is numeric
        if port != 'NOT_SET':
            port_num = int(port)
            log(f"   ✅ PORT is valid number: {port_num}")
        else:
            log("   ❌ PORT not set!")
    except ValueError:
        log(f"   ❌ PORT is not a valid number: {port}")
        sys.exit(1)
    
    # Run migrations
    log("📊 Running database migrations...")
    try:
        result = subprocess.run([
            'python', 'manage.py', 'migrate', 
            '--settings=gym_backend.settings_production'
        ], check=True, capture_output=True, text=True)
        log("   ✅ Migrations completed successfully")
    except subprocess.CalledProcessError as e:
        log(f"   ❌ Migration failed: {e}")
        log(f"   Error output: {e.stderr}")
        sys.exit(1)
    
    # Start gunicorn
    log(f"🚀 Starting gunicorn on 0.0.0.0:{port}...")
    
    # Build gunicorn command
    cmd = [
        'gunicorn',
        '--config', 'gunicorn.conf.py',
        'gym_backend.wsgi_production:application'
    ]
    
    log(f"   Command: {' '.join(cmd)}")
    
    # Execute gunicorn
    try:
        os.execvp('gunicorn', cmd)
    except Exception as e:
        log(f"   ❌ Failed to start gunicorn: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()