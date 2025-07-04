"""
WSGI config for gym_backend project - PRODUCTION VERSION.
Optimized for enterprise deployment with 100k+ users.

This module contains the WSGI application used by Django's production servers.
It exposes the WSGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/4.2/howto/deployment/wsgi/
"""

import os
import sys
from django.core.wsgi import get_wsgi_application
from whitenoise import WhiteNoise

# Set the Django settings module for production
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'gym_backend.settings_production')

# Get the Django WSGI application
application = get_wsgi_application()

# Add WhiteNoise for efficient static file serving
application = WhiteNoise(application, root='/path/to/static/files')

# Optional: Add static file serving with compression
application.add_files('/path/to/more/static/files', prefix='more-files/')