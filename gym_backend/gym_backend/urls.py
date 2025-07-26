"""
URL configuration for gym_backend project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/4.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse
from django.conf import settings
from django.conf.urls.static import static
from gym_api.simple_health import simple_health_check, live_check
from gym_api.views import web_attendance_page, web_attendance_submit

def ultra_simple_health(request):
    """Ultra simple health check - just return 200."""
    import time
    from django.http import HttpResponse
    
    # For Railway health checks, return simple 200 OK
    if 'RailwayHealthCheck' in request.META.get('HTTP_USER_AGENT', ''):
        return HttpResponse('OK', status=200, content_type='text/plain')
    
    # For other requests, return JSON
    return JsonResponse({
        'status': 'ok',
        'timestamp': time.time(),
        'message': 'Gym Management API is running'
    })

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('gym_api.urls')),
    
    # Web attendance endpoints (for QR code access)
    path('attendance/qr/', web_attendance_page, name='web_attendance_page'),
    path('attendance/submit/', web_attendance_submit, name='web_attendance_submit'),
    
    # Health endpoints for Railway (both with and without trailing slash)
    path('health/', ultra_simple_health, name='ultra_health'),
    path('health', ultra_simple_health, name='ultra_health_no_slash'),
    path('health-detailed/', simple_health_check, name='detailed_health'),
    path('live/', live_check, name='live_check'),
    path('live', live_check, name='live_check_no_slash'),
    
    # Root endpoint for basic connectivity test
    path('', ultra_simple_health, name='root_health'),
]

# Serve media files in development and production
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
else:
    # For production (Railway), also serve media files
    # Railway doesn't have a separate media server, so Django needs to serve them
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
