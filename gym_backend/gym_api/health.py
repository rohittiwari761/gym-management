"""
Health check and monitoring utilities for enterprise deployment.
"""

from django.http import JsonResponse
from django.db import connections
from django.core.cache import cache
from django.conf import settings
import time
import logging

logger = logging.getLogger(__name__)


def health_check(request):
    """
    Comprehensive health check endpoint for load balancers and monitoring.
    Returns detailed status of all system components.
    """
    start_time = time.time()
    health_status = {
        'status': 'healthy',
        'timestamp': time.time(),
        'services': {},
        'metrics': {}
    }
    
    try:
        # Check database connectivity
        db_status = check_database_health()
        health_status['services']['database'] = db_status
        
        # Check Redis cache
        cache_status = check_cache_health()
        health_status['services']['cache'] = cache_status
        
        # Check overall system metrics
        metrics = get_system_metrics()
        health_status['metrics'] = metrics
        
        # Determine overall health
        if not db_status['healthy'] or not cache_status['healthy']:
            health_status['status'] = 'unhealthy'
            
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        health_status['status'] = 'error'
        health_status['error'] = str(e)
    
    health_status['response_time_ms'] = round((time.time() - start_time) * 1000, 2)
    
    # Return appropriate HTTP status code
    status_code = 200 if health_status['status'] == 'healthy' else 503
    
    return JsonResponse(health_status, status=status_code)


def check_database_health():
    """Check database connectivity and performance."""
    try:
        from django.db import connection
        from gym_api.models import GymOwner
        
        start_time = time.time()
        
        # Test basic connectivity
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()
        
        # Test application-level query
        gym_count = GymOwner.objects.count()
        
        response_time = round((time.time() - start_time) * 1000, 2)
        
        return {
            'healthy': True,
            'response_time_ms': response_time,
            'total_gyms': gym_count,
            'connection_status': 'connected'
        }
    except Exception as e:
        logger.error(f"Database health check failed: {e}")
        return {
            'healthy': False,
            'error': str(e),
            'connection_status': 'failed'
        }


def check_cache_health():
    """Check Redis cache connectivity and performance."""
    try:
        start_time = time.time()
        
        # Test cache write/read
        test_key = 'health_check_test'
        test_value = {'timestamp': time.time()}
        
        cache.set(test_key, test_value, 60)
        retrieved_value = cache.get(test_key)
        
        if retrieved_value != test_value:
            raise Exception("Cache write/read test failed")
        
        # Clean up test key
        cache.delete(test_key)
        
        response_time = round((time.time() - start_time) * 1000, 2)
        
        return {
            'healthy': True,
            'response_time_ms': response_time,
            'connection_status': 'connected'
        }
    except Exception as e:
        logger.error(f"Cache health check failed: {e}")
        return {
            'healthy': False,
            'error': str(e),
            'connection_status': 'failed'
        }


def get_system_metrics():
    """Get basic system performance metrics."""
    try:
        import psutil
        
        # CPU usage
        cpu_percent = psutil.cpu_percent(interval=1)
        
        # Memory usage
        memory = psutil.virtual_memory()
        memory_percent = memory.percent
        
        # Disk usage
        disk = psutil.disk_usage('/')
        disk_percent = (disk.used / disk.total) * 100
        
        return {
            'cpu_usage_percent': round(cpu_percent, 1),
            'memory_usage_percent': round(memory_percent, 1),
            'disk_usage_percent': round(disk_percent, 1),
            'available_memory_mb': round(memory.available / 1024 / 1024, 0)
        }
    except ImportError:
        # psutil not installed
        return {
            'message': 'System metrics unavailable (psutil not installed)'
        }
    except Exception as e:
        logger.error(f"Failed to get system metrics: {e}")
        return {
            'error': str(e)
        }


def metrics_endpoint(request):
    """
    Prometheus-compatible metrics endpoint.
    Returns metrics in Prometheus format for monitoring.
    """
    try:
        from gym_api.models import GymOwner, Member, Attendance, MembershipPayment
        from django.utils import timezone
        from datetime import timedelta
        
        today = timezone.now().date()
        week_ago = today - timedelta(days=7)
        
        # Collect application metrics
        metrics = []
        
        # Total counts
        total_gyms = GymOwner.objects.count()
        total_members = Member.objects.count()
        active_members = Member.objects.filter(is_active=True).count()
        
        # Attendance metrics
        today_attendance = Attendance.objects.filter(date=today).count()
        week_attendance = Attendance.objects.filter(date__gte=week_ago).count()
        
        # Revenue metrics
        today_revenue = MembershipPayment.objects.filter(
            payment_date__date=today,
            status='completed'
        ).aggregate(total=models.Sum('amount'))['total'] or 0
        
        # Format metrics in Prometheus format
        metrics.extend([
            f'gym_total_gyms {total_gyms}',
            f'gym_total_members {total_members}',
            f'gym_active_members {active_members}',
            f'gym_today_attendance {today_attendance}',
            f'gym_week_attendance {week_attendance}',
            f'gym_today_revenue {today_revenue}',
        ])
        
        # Database connection metrics
        db_connections = len(connections.all())
        metrics.append(f'gym_db_connections {db_connections}')
        
        # Response
        response_content = '\n'.join(metrics) + '\n'
        
        return JsonResponse({
            'metrics': response_content
        }, content_type='text/plain')
        
    except Exception as e:
        logger.error(f"Metrics endpoint failed: {e}")
        return JsonResponse({
            'error': str(e)
        }, status=500)


def ready_check(request):
    """
    Kubernetes readiness probe endpoint.
    Returns 200 if the application is ready to serve traffic.
    """
    try:
        # Quick database check
        from django.db import connection
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        
        return JsonResponse({'status': 'ready'})
    except:
        return JsonResponse({'status': 'not ready'}, status=503)


def live_check(request):
    """
    Kubernetes liveness probe endpoint.
    Returns 200 if the application is alive and running.
    """
    return JsonResponse({'status': 'alive'})