"""
Google OAuth 2.0 authentication for gym management system
"""
import json
import os
import requests
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token
from django.contrib.auth.models import User
from django.conf import settings
from rest_framework import status
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from .models import GymOwner
from .serializers import GymOwnerSerializer


class GoogleAuthService:
    """Service for handling Google OAuth authentication"""
    
    @staticmethod
    def verify_google_token(google_token):
        """
        Verify Google ID token and return user info
        """
        try:
            print(f"🔐 GOOGLE_AUTH: Verifying token with length: {len(google_token)}")
            
            # Get Google OAuth Client ID directly from environment
            google_client_id = os.getenv('GOOGLE_OAUTH2_CLIENT_ID')
            print(f"🔧 GOOGLE_AUTH: Direct env lookup - GOOGLE_OAUTH2_CLIENT_ID: {google_client_id}")
            
            # Also try to get from Django settings as fallback
            try:
                settings_client_id = getattr(settings, 'GOOGLE_OAUTH2_CLIENT_ID', None)
                print(f"🔧 GOOGLE_AUTH: Django settings lookup - GOOGLE_OAUTH2_CLIENT_ID: {settings_client_id}")
            except Exception as e:
                print(f"🔧 GOOGLE_AUTH: Django settings error: {e}")
                settings_client_id = None
            
            # Use direct environment variable if available, otherwise try settings
            client_id = google_client_id or settings_client_id
            
            if not client_id:
                print("❌ GOOGLE_AUTH: GOOGLE_OAUTH2_CLIENT_ID not found in environment or settings")
                return None
            
            print(f"🔑 GOOGLE_AUTH: Using Client ID: {client_id}")
            print(f"🔑 GOOGLE_AUTH: Token starts with: {google_token[:50]}...")
            
            # Verify the token with Google
            idinfo = id_token.verify_oauth2_token(
                google_token, 
                google_requests.Request(), 
                client_id
            )
            
            print(f"✅ GOOGLE_AUTH: Token verification successful for user: {idinfo.get('email')}")
            
            # Token is valid, return user info
            return {
                'email': idinfo.get('email'),
                'first_name': idinfo.get('given_name', ''),
                'last_name': idinfo.get('family_name', ''),
                'picture': idinfo.get('picture', ''),
                'email_verified': idinfo.get('email_verified', False),
                'google_id': idinfo.get('sub'),
            }
        except ValueError as e:
            # Invalid token
            print(f"❌ GOOGLE_AUTH: Token verification failed (ValueError): {e}")
            return None
        except Exception as e:
            print(f"❌ GOOGLE_AUTH: Token verification failed (Exception): {e}")
            return None
    
    @staticmethod
    def authenticate_or_create_user(google_user_info):
        """
        Authenticate existing user or create new gym owner account
        """
        email = google_user_info.get('email')
        if not email:
            return None, "Email not provided by Google"
        
        # Check if user already exists
        try:
            user = User.objects.get(email=email)
            
            # Check if user is a gym owner
            if hasattr(user, 'gymowner'):
                gym_owner = user.gymowner
                
                # Only set Google profile picture if user doesn't have a custom one
                if google_user_info.get('picture') and not gym_owner.profile_picture_base64:
                    try:
                        import requests
                        import base64
                        response = requests.get(google_user_info['picture'])
                        if response.status_code == 200:
                            img_data = base64.b64encode(response.content).decode('utf-8')
                            gym_owner.profile_picture_base64 = img_data
                            gym_owner.profile_picture_content_type = "image/jpeg"
                            gym_owner.save()
                    except Exception as e:
                        pass
                
                # Generate or get auth token
                token, created = Token.objects.get_or_create(user=user)
                
                return {
                    'user': user,
                    'gym_owner': gym_owner,
                    'token': token.key,
                    'is_new_user': False
                }, None
            else:
                return None, "User exists but is not a gym owner"
                
        except User.DoesNotExist:
            # Create new user and gym owner
            try:
                # Create user
                user = User.objects.create_user(
                    username=email,
                    email=email,
                    first_name=google_user_info.get('first_name', ''),
                    last_name=google_user_info.get('last_name', ''),
                )
                
                # Create gym owner with minimal required fields
                gym_owner = GymOwner.objects.create(
                    user=user,
                    gym_name=f"{user.get_full_name()}'s Gym",  # Default name
                    gym_address="",  # Will be updated in profile completion
                    phone_number="",  # Will be updated in profile completion
                    gym_established_date=None,  # Will be set automatically
                )
                
                # Download and store Google profile picture as base64 for new users
                if google_user_info.get('picture'):
                    try:
                        import requests
                        import base64
                        response = requests.get(google_user_info['picture'])
                        if response.status_code == 200:
                            img_data = base64.b64encode(response.content).decode('utf-8')
                            gym_owner.profile_picture_base64 = img_data
                            gym_owner.profile_picture_content_type = "image/jpeg"
                            gym_owner.save()
                    except Exception as e:
                        pass
                
                # Generate auth token
                token = Token.objects.create(user=user)
                
                return {
                    'user': user,
                    'gym_owner': gym_owner,
                    'token': token.key,
                    'is_new_user': True,
                    'needs_profile_completion': True
                }, None
                
            except Exception as e:
                return None, f"Failed to create user: {str(e)}"


def handle_google_auth(request):
    """
    Handle Google authentication request
    """
    print("🚀 GOOGLE_AUTH: Received Google authentication request")
    print("🕒 GOOGLE_AUTH: July 16, 2025 - 18:45 IST - Environment variable diagnostic active")
    
    # Enhanced diagnostic logging
    client_id_env = os.getenv('GOOGLE_OAUTH2_CLIENT_ID')
    client_secret_env = os.getenv('GOOGLE_OAUTH2_CLIENT_SECRET')
    
    print(f"🔧 GOOGLE_AUTH: Environment diagnostic:")
    print(f"   - GOOGLE_OAUTH2_CLIENT_ID env: {'✅ SET' if client_id_env else '❌ NOT SET'}")
    print(f"   - GOOGLE_OAUTH2_CLIENT_SECRET env: {'✅ SET' if client_secret_env else '❌ NOT SET'}")
    
    if client_id_env:
        print(f"   - Client ID (first 20 chars): {client_id_env[:20]}...")
    if client_secret_env:
        print(f"   - Client Secret (first 10 chars): {client_secret_env[:10]}...")
    
    # Check Django settings as fallback
    try:
        settings_client_id = getattr(settings, 'GOOGLE_OAUTH2_CLIENT_ID', None)
        settings_client_secret = getattr(settings, 'GOOGLE_OAUTH2_CLIENT_SECRET', None)
        print(f"   - Django settings client ID: {'✅ SET' if settings_client_id else '❌ NOT SET'}")
        print(f"   - Django settings client secret: {'✅ SET' if settings_client_secret else '❌ NOT SET'}")
    except Exception as e:
        print(f"   - Django settings error: {e}")
    
    # Check if all Google Auth dependencies are available
    try:
        from google.auth.transport import requests as google_requests
        from google.oauth2 import id_token
        print(f"   - Google auth library: ✅ AVAILABLE")
    except ImportError as e:
        print(f"   - Google auth library: ❌ NOT AVAILABLE - {e}")
        return Response(
            {'error': 'Google authentication library not available'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    
    google_token = request.data.get('google_token')
    if not google_token:
        print("❌ GOOGLE_AUTH: No Google token provided in request")
        return Response(
            {'error': 'Google token is required'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    print(f"📥 GOOGLE_AUTH: Received token, attempting verification...")
    
    # Verify Google token
    google_user_info = GoogleAuthService.verify_google_token(google_token)
    if not google_user_info:
        print("❌ GOOGLE_AUTH: Google token verification failed")
        return Response(
            {'error': 'Invalid Google token'}, 
            status=status.HTTP_401_UNAUTHORIZED
        )
        
    print(f"✅ GOOGLE_AUTH: Token verified for user: {google_user_info.get('email')}")
    
    # Authenticate or create user
    auth_result, error = GoogleAuthService.authenticate_or_create_user(google_user_info)
    if error:
        return Response(
            {'error': error}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Serialize gym owner data
    gym_owner_serializer = GymOwnerSerializer(
        auth_result['gym_owner'], 
        context={'request': request}
    )
    
    # Generate appropriate message based on user status
    is_new_user = auth_result.get('is_new_user', False)
    message = 'New account created and signed in successfully' if is_new_user else 'Signed in successfully'
    
    response_data = {
        'success': True,  # Add success flag for Flutter frontend
        'token': auth_result['token'],
        'user': {
            'id': auth_result['user'].id,
            'email': auth_result['user'].email,
            'first_name': auth_result['user'].first_name,
            'last_name': auth_result['user'].last_name,
        },
        'gym_owner': gym_owner_serializer.data,
        'is_new_user': is_new_user,
        'needs_profile_completion': auth_result.get('needs_profile_completion', False),
        'message': message
    }
    
    return Response(response_data, status=status.HTTP_200_OK)