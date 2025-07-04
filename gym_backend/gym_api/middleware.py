"""
Custom middleware for serving media files in production
"""
import os
from django.http import HttpResponse, Http404
from django.conf import settings
from django.utils.http import http_date
from django.views.static import serve
import mimetypes
import time

class ServeMediaMiddleware:
    """
    Custom middleware to serve media files in production
    Railway doesn't persist files between deployments, but this ensures
    files uploaded during the current session are accessible
    """
    
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Check if this is a media file request
        if request.path.startswith(settings.MEDIA_URL):
            return self.serve_media(request)
        
        response = self.get_response(request)
        return response

    def serve_media(self, request):
        """
        Serve media files directly
        """
        try:
            # Get the file path relative to MEDIA_URL
            relative_path = request.path[len(settings.MEDIA_URL):]
            file_path = os.path.join(settings.MEDIA_ROOT, relative_path)
            
            print(f"📁 Serving media file: {file_path}")
            
            # Check if file exists
            if not os.path.exists(file_path):
                print(f"❌ Media file not found: {file_path}")
                raise Http404("Media file not found")
            
            # Get file info
            file_size = os.path.getsize(file_path)
            content_type, _ = mimetypes.guess_type(file_path)
            if not content_type:
                content_type = 'application/octet-stream'
            
            # Create response
            with open(file_path, 'rb') as f:
                response = HttpResponse(f.read(), content_type=content_type)
                response['Content-Length'] = str(file_size)
                response['Last-Modified'] = http_date(os.path.getmtime(file_path))
                
                # Add cache headers for images
                if content_type.startswith('image/'):
                    response['Cache-Control'] = 'public, max-age=3600'  # Cache for 1 hour
                
                print(f"✅ Served media file: {relative_path} ({file_size} bytes, {content_type})")
                return response
                
        except Exception as e:
            print(f"❌ Error serving media file: {e}")
            raise Http404("Media file not found")