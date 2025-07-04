"""
Simple health check for Railway deployment.
"""

from django.http import JsonResponse
from django.db import connection
import logging

logger = logging.getLogger(__name__)


def simple_health_check(request):
    """
    Simple health check endpoint for Railway.
    Just checks if Django is running and database is accessible.
    """
    try:
        # Simple database check
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()
        
        return JsonResponse({
            'status': 'healthy',
            'message': 'Gym Management API is running'
        })
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return JsonResponse({
            'status': 'unhealthy',
            'error': str(e)
        }, status=503)


def live_check(request):
    """
    Simple liveness check - just return 200 if Django is running.
    """
    return JsonResponse({'status': 'alive'})