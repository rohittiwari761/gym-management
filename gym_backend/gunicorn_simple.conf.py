"""
Simple Gunicorn configuration for Railway deployment.
"""

import os

# Server socket - Railway uses PORT environment variable
port = os.environ.get('PORT', '8000')
bind = f"0.0.0.0:{port}"

# Worker processes - Keep it simple for Railway
workers = 2
worker_class = "sync"
timeout = 120
keepalive = 2

# Logging - Use stdout/stderr for Railway
accesslog = "-"
errorlog = "-"
loglevel = "info"

# Process naming
proc_name = 'gym_api'

# Environment variables
raw_env = [
    'DJANGO_SETTINGS_MODULE=gym_backend.settings_production',
]

# Preload app for better memory usage
preload_app = True