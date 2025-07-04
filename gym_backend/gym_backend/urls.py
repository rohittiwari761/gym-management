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
from gym_api.simple_health import simple_health_check, live_check

def ultra_simple_health(request):
    """Ultra simple health check - just return 200."""
    import time
    return JsonResponse({
        'status': 'ok',
        'timestamp': time.time(),
        'message': 'Gym Management API is running'
    })

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('gym_api.urls')),
    
    # Ultra simple health endpoints for Railway
    path('health/', ultra_simple_health, name='ultra_health'),
    path('health-detailed/', simple_health_check, name='detailed_health'),
    path('live/', live_check, name='live_check'),
]
