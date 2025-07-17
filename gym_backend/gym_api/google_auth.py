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
        Supports both web and mobile client IDs for cross-platform compatibility
        """
        try:
            print(f"🔐 GOOGLE_AUTH: Verifying token with length: {len(google_token)}")
            
            # Define all supported client IDs for cross-platform authentication
            supported_client_ids = []
            
            # Get primary client ID from environment
            primary_client_id = os.getenv('GOOGLE_OAUTH2_CLIENT_ID')
            if primary_client_id:
                supported_client_ids.append(primary_client_id)
                print(f"🔧 GOOGLE_AUTH: Added primary client ID from env: {primary_client_id[:20]}...")
            
            # Get from Django settings as fallback
            try:
                settings_client_id = getattr(settings, 'GOOGLE_OAUTH2_CLIENT_ID', None)
                if settings_client_id and settings_client_id not in supported_client_ids:
                    supported_client_ids.append(settings_client_id)
                    print(f"🔧 GOOGLE_AUTH: Added settings client ID: {settings_client_id[:20]}...")
            except Exception as e:
                print(f"🔧 GOOGLE_AUTH: Django settings error: {e}")
            
            # Add known platform-specific client IDs for cross-platform support
            # Web client ID first since most requests are from web platform
            known_client_ids = [
                '818835282138-qjqc6v2bf8n89ghrphh9l388erj5vt5g.apps.googleusercontent.com',  # Web
                '818835282138-8h3qf505eco222l28feg0o1t3tvu0v8g.apps.googleusercontent.com',  # Mobile
            ]
            
            for client_id in known_client_ids:
                if client_id not in supported_client_ids:
                    supported_client_ids.append(client_id)
                    print(f"🔧 GOOGLE_AUTH: Added known client ID: {client_id[:20]}...")
            
            if not supported_client_ids:
                print("❌ GOOGLE_AUTH: No valid client IDs found")
                return None
            
            print(f"🔑 GOOGLE_AUTH: Attempting verification with {len(supported_client_ids)} client IDs")
            print(f"🔑 GOOGLE_AUTH: Token starts with: {google_token[:50]}...")
            
            # Try verification with each supported client ID
            verification_errors = []
            for i, client_id in enumerate(supported_client_ids):
                try:
                    print(f"🔍 GOOGLE_AUTH: Attempt {i+1}/{len(supported_client_ids)} with client ID: {client_id[:20]}...")
                    
                    # Verify the token with Google
                    idinfo = id_token.verify_oauth2_token(
                        google_token, 
                        google_requests.Request(), 
                        client_id
                    )
                    
                    print(f"✅ GOOGLE_AUTH: Token verification successful with client ID: {client_id[:20]}...")
                    print(f"✅ GOOGLE_AUTH: Verified user: {idinfo.get('email')}")
                    
                    # Token is valid, return user info
                    return {
                        'email': idinfo.get('email'),
                        'first_name': idinfo.get('given_name', ''),
                        'last_name': idinfo.get('family_name', ''),
                        'picture': idinfo.get('picture', ''),
                        'email_verified': idinfo.get('email_verified', False),
                        'google_id': idinfo.get('sub'),
                        'verified_with_client_id': client_id,
                    }
                except ValueError as e:
                    error_msg = str(e)
                    verification_errors.append(f"Client {client_id[:20]}...: {error_msg}")
                    print(f"❌ GOOGLE_AUTH: Client ID {client_id[:20]}... failed: {error_msg}")
                    continue
                except Exception as e:
                    error_msg = str(e)
                    verification_errors.append(f"Client {client_id[:20]}...: {error_msg}")
                    print(f"❌ GOOGLE_AUTH: Client ID {client_id[:20]}... error: {error_msg}")
                    continue
            
            # All client IDs failed
            print(f"❌ GOOGLE_AUTH: All {len(supported_client_ids)} client IDs failed verification")
            for error in verification_errors:
                print(f"   - {error}")
            return None
            
        except Exception as e:
            print(f"❌ GOOGLE_AUTH: Unexpected error during token verification: {e}")
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


def handle_google_auth(token_or_request, user_data=None):
    """
    Handle Google authentication request or direct token
    Supports both request objects and direct token/user_data for OAuth flow
    Cross-platform support for web and mobile Google OAuth
    """
    print("🚀 GOOGLE_AUTH: Received Google authentication request")
    print("🕒 GOOGLE_AUTH: July 17, 2025 - Cross-platform authentication active")
    
    # Handle different input types
    if user_data is not None:
        # Direct user data provided (from OAuth exchange)
        print("🔄 GOOGLE_AUTH: Processing direct user data from OAuth exchange")
        platform = 'web-oauth'
        client_id_from_frontend = 'oauth-exchange'
        google_token = token_or_request  # May be None for OAuth flow
        print(f"📱 GOOGLE_AUTH: Platform: {platform}")
        print(f"👤 GOOGLE_AUTH: User email: {user_data.get('email')}")
    else:
        # Traditional request object
        request = token_or_request
        google_token = request.data.get('google_token')
        platform = request.data.get('platform', 'unknown')
        client_id_from_frontend = request.data.get('client_id', 'not provided')
        print(f"📱 GOOGLE_AUTH: Platform: {platform}")
        print(f"🔑 GOOGLE_AUTH: Frontend client ID: {client_id_from_frontend[:20]}..." if client_id_from_frontend != 'not provided' else "🔑 GOOGLE_AUTH: No client ID provided by frontend")
    
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
    
    # Handle user info verification
    if user_data is not None:
        # Direct user data provided (from OAuth exchange)
        print("🔄 GOOGLE_AUTH: Using provided user data from OAuth exchange")
        google_user_info = user_data
        print(f"✅ GOOGLE_AUTH: Using OAuth user data for: {google_user_info.get('email')}")
    else:
        # Traditional token verification
        if not google_token:
            print("❌ GOOGLE_AUTH: No Google token provided in request")
            return {'success': False, 'error': 'Google token is required'}
        
        print(f"📥 GOOGLE_AUTH: Received token, attempting cross-platform verification...")
        print(f"📋 GOOGLE_AUTH: Request data keys: {list(request.data.keys())}")
        
        # Verify Google token
        google_user_info = GoogleAuthService.verify_google_token(google_token)
        if not google_user_info:
            print("❌ GOOGLE_AUTH: Google token verification failed")
            return {'success': False, 'error': 'Invalid Google token'}
            
        print(f"✅ GOOGLE_AUTH: Token verified for user: {google_user_info.get('email')}")
    
    # Authenticate or create user
    auth_result, error = GoogleAuthService.authenticate_or_create_user(google_user_info)
    if error:
        if user_data is not None:
            return {'success': False, 'error': error}
        return Response(
            {'error': error}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Serialize gym owner data - handle context for OAuth vs request
    context = {'request': token_or_request if user_data is None else None}
    gym_owner_serializer = GymOwnerSerializer(
        auth_result['gym_owner'], 
        context=context
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
    
    # Return dict for OAuth exchange, Response for traditional request
    if user_data is not None:
        return response_data
    return Response(response_data, status=status.HTTP_200_OK)