"""
Simple health check for Railway deployment.
"""

from django.http import JsonResponse
from django.db import connection
import logging
import time

logger = logging.getLogger(__name__)


def simple_health_check(request):
    """
    Ultra-simple health check endpoint for Railway.
    Just returns 200 if Django is responding.
    """
    return JsonResponse({
        'status': 'healthy',
        'message': 'Gym Management API is running',
        'timestamp': time.time()
    })


def live_check(request):
    """
    Simple liveness check - just return 200 if Django is running.
    """
    return JsonResponse({'status': 'alive'})