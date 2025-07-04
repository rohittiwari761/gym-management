"""
WSGI config for gym_backend project - Railway Production.
Simple and reliable configuration for Railway deployment.
"""

import os
from django.core.wsgi import get_wsgi_application

# Set the Django settings module for production
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'gym_backend.settings_production')

# Get the Django WSGI application
application = get_wsgi_application()