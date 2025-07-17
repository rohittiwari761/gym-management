"""
Debug middleware for authentication troubleshooting
"""
from django.utils.deprecation import MiddlewareMixin
from rest_framework.authtoken.models import Token
from django.contrib.auth.models import User
import logging

logger = logging.getLogger(__name__)

class AuthDebugMiddleware(MiddlewareMixin):
    """
    Middleware to debug authentication issues
    """
    
    def process_request(self, request):
        # Only debug API requests
        if not request.path.startswith('/api/'):
            return
            
        # Skip health check endpoints
        if request.path.startswith('/api/health'):
            return
        
        print(f"\n🔍 AUTH DEBUG: {request.method} {request.path}")
        print(f"🔍 AUTH DEBUG: Headers: {dict(request.headers)}")
        
        # Check for Authorization header
        auth_header = request.META.get('HTTP_AUTHORIZATION')
        if auth_header:
            print(f"🔍 AUTH DEBUG: Authorization header: {auth_header}")
            
            # Parse token
            if auth_header.startswith('Token '):
                token_key = auth_header.split(' ')[1]
                print(f"🔍 AUTH DEBUG: Token key: {token_key[:20]}...")
                
                try:
                    token = Token.objects.get(key=token_key)
                    print(f"🔍 AUTH DEBUG: Token found for user: {token.user.email}")
                    print(f"🔍 AUTH DEBUG: Token created: {token.created}")
                    print(f"🔍 AUTH DEBUG: User is active: {token.user.is_active}")
                    print(f"🔍 AUTH DEBUG: User has gymowner: {hasattr(token.user, 'gymowner')}")
                except Token.DoesNotExist:
                    print("❌ AUTH DEBUG: Token not found in database")
                except Exception as e:
                    print(f"❌ AUTH DEBUG: Token validation error: {e}")
            else:
                print(f"🔍 AUTH DEBUG: Non-Token auth header: {auth_header}")
        else:
            print("❌ AUTH DEBUG: No Authorization header found")
            
        # Check for session authentication
        if hasattr(request, 'user') and request.user.is_authenticated:
            print(f"🔍 AUTH DEBUG: Session user: {request.user.email}")
        else:
            print("❌ AUTH DEBUG: No authenticated user in session")
            
        return None
    
    def process_response(self, request, response):
        # Only debug API requests
        if not request.path.startswith('/api/'):
            return response
            
        # Skip health check endpoints
        if request.path.startswith('/api/health'):
            return response
            
        print(f"🔍 AUTH DEBUG: Response status: {response.status_code}")
        
        if response.status_code == 403:
            print("❌ AUTH DEBUG: 403 Forbidden response")
            if hasattr(request, 'user'):
                print(f"❌ AUTH DEBUG: Request user: {request.user}")
                print(f"❌ AUTH DEBUG: User authenticated: {request.user.is_authenticated}")
            
        return response