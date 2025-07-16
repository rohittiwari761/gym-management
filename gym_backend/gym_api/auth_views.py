from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.db import transaction
from .models import GymOwner
from .serializers import GymOwnerSerializer
from .google_auth import handle_google_auth
import uuid

# Try to import JWT components (available in production)
try:
    from rest_framework_simplejwt.tokens import RefreshToken
    JWT_AVAILABLE = True
except ImportError:
    JWT_AVAILABLE = False


@api_view(['POST'])
@permission_classes([AllowAny])
def gym_owner_register(request):
    """
    Register a new gym owner with authentication
    """
    try:
        with transaction.atomic():
            # Extract data from request
            data = request.data
            
            # Validate required fields
            required_fields = ['email', 'password', 'first_name', 'last_name', 'gym_name']
            for field in required_fields:
                if not data.get(field):
                    return Response({
                        'error': f'{field} is required'
                    }, status=status.HTTP_400_BAD_REQUEST)
            
            # Check if user already exists
            if User.objects.filter(email=data['email']).exists():
                return Response({
                    'error': 'A user with this email already exists'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Create User
            user = User.objects.create_user(
                username=data['email'],  # Use email as username
                email=data['email'],
                first_name=data['first_name'],
                last_name=data['last_name'],
                password=data['password']
            )
            
            # Create GymOwner
            gym_owner = GymOwner.objects.create(
                user=user,
                gym_name=data['gym_name'],
                gym_address=data.get('gym_address', ''),
                gym_description=data.get('gym_description', ''),
                phone_number=data.get('phone_number', ''),
                gym_established_date=data.get('gym_established_date'),
                subscription_plan=data.get('subscription_plan', 'basic')
            )
            
            # Create authentication token
            token, created = Token.objects.get_or_create(user=user)
            
            # Generate JWT tokens if available (for production)
            jwt_tokens = {}
            if JWT_AVAILABLE:
                refresh = RefreshToken.for_user(user)
                jwt_tokens = {
                    'refresh': str(refresh),
                    'access': str(refresh.access_token),
                }
            
            # Serialize gym owner data
            serializer = GymOwnerSerializer(gym_owner)
            
            response_data = {
                'success': True,
                'message': 'Gym owner registered successfully',
                'token': token.key,  # Django token for backwards compatibility
                'gym_owner': serializer.data,
                'user': {
                    'id': user.id,
                    'email': user.email,
                    'first_name': user.first_name,
                    'last_name': user.last_name
                }
            }
            
            # Add JWT tokens if available
            if JWT_AVAILABLE:
                response_data['jwt'] = jwt_tokens
            
            return Response(response_data, status=status.HTTP_201_CREATED)
            
    except Exception as e:
        return Response({
            'error': f'Registration failed: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([AllowAny])
def gym_owner_login(request):
    """
    Authenticate gym owner and return token
    """
    try:
        email = request.data.get('email')
        password = request.data.get('password')
        
        if not email or not password:
            return Response({
                'error': 'Email and password are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Authenticate user
        user = authenticate(username=email, password=password)
        
        if not user:
            return Response({
                'error': 'Invalid credentials'
            }, status=status.HTTP_401_UNAUTHORIZED)
        
        # Check if user is a gym owner
        try:
            gym_owner = GymOwner.objects.get(user=user)
        except GymOwner.DoesNotExist:
            return Response({
                'error': 'User is not a gym owner'
            }, status=status.HTTP_403_FORBIDDEN)
        
        # Get or create token
        token, created = Token.objects.get_or_create(user=user)
        
        # Generate JWT tokens if available (for production)
        jwt_tokens = {}
        if JWT_AVAILABLE:
            refresh = RefreshToken.for_user(user)
            jwt_tokens = {
                'refresh': str(refresh),
                'access': str(refresh.access_token),
            }
        
        # Serialize gym owner data
        serializer = GymOwnerSerializer(gym_owner)
        
        response_data = {
            'success': True,
            'message': 'Login successful',
            'token': token.key,  # Django token for backwards compatibility
            'gym_owner': serializer.data,
            'user': {
                'id': user.id,
                'email': user.email,
                'first_name': user.first_name,
                'last_name': user.last_name
            }
        }
        
        # Add JWT tokens if available
        if JWT_AVAILABLE:
            response_data['jwt'] = jwt_tokens
        
        return Response(response_data, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'error': f'Login failed: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
def gym_owner_logout(request):
    """
    Logout gym owner by deleting token
    """
    try:
        # Delete the user's token
        Token.objects.filter(user=request.user).delete()
        
        return Response({
            'success': True,
            'message': 'Logout successful'
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'error': f'Logout failed: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
def gym_owner_profile(request):
    """
    Get current gym owner's profile information
    """
    try:
        # Check if user is a gym owner
        if not hasattr(request.user, 'gymowner'):
            return Response({
                'error': 'User is not a gym owner'
            }, status=status.HTTP_403_FORBIDDEN)
        
        gym_owner = request.user.gymowner
        serializer = GymOwnerSerializer(gym_owner, context={'request': request})
        
        return Response({
            'success': True,
            'gym_owner': serializer.data,
            'user': {
                'id': request.user.id,
                'email': request.user.email,
                'first_name': request.user.first_name,
                'last_name': request.user.last_name
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'error': f'Failed to get profile: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['PUT'])
def gym_owner_update_profile(request):
    """
    Update current gym owner's profile information
    """
    try:
        # Check if user is a gym owner
        if not hasattr(request.user, 'gymowner'):
            return Response({
                'error': 'User is not a gym owner'
            }, status=status.HTTP_403_FORBIDDEN)
        
        gym_owner = request.user.gymowner
        user = request.user
        
        print(f"🔄 PROFILE UPDATE: Received data: {request.data}")
        
        # Update user fields
        user_fields = ['first_name', 'last_name', 'email']
        updated_user_fields = []
        for field in user_fields:
            if field in request.data and request.data[field] is not None:
                setattr(user, field, request.data[field])
                updated_user_fields.append(field)
        
        if updated_user_fields:
            user.save()
            print(f"✅ PROFILE UPDATE: Updated user fields: {updated_user_fields}")
        
        # Update gym owner fields
        gym_fields = ['gym_name', 'gym_address', 'gym_description', 'phone_number', 'gym_established_date', 'subscription_plan']
        updated_gym_fields = []
        for field in gym_fields:
            if field in request.data and request.data[field] is not None:
                setattr(gym_owner, field, request.data[field])
                updated_gym_fields.append(field)
        
        if updated_gym_fields:
            gym_owner.save()
            print(f"✅ PROFILE UPDATE: Updated gym owner fields: {updated_gym_fields}")
        
        # Log fields that were sent but not processed (for debugging)
        processed_fields = set(user_fields + gym_fields)
        sent_fields = set(request.data.keys())
        ignored_fields = sent_fields - processed_fields
        if ignored_fields:
            print(f"⚠️ PROFILE UPDATE: Ignored fields (not in model): {ignored_fields}")
        
        # Serialize updated data
        serializer = GymOwnerSerializer(gym_owner, context={'request': request})
        
        return Response({
            'success': True,
            'message': 'Profile updated successfully',
            'gym_owner': serializer.data,
            'user': {
                'id': user.id,
                'email': user.email,
                'first_name': user.first_name,
                'last_name': user.last_name
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        print(f"❌ PROFILE UPDATE ERROR: {str(e)}")
        import traceback
        print(f"❌ PROFILE UPDATE TRACEBACK: {traceback.format_exc()}")
        return Response({
            'error': f'Failed to update profile: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
def regenerate_qr_token(request):
    """
    Regenerate QR code token for gym
    """
    try:
        # Check if user is a gym owner
        if not hasattr(request.user, 'gymowner'):
            return Response({
                'error': 'User is not a gym owner'
            }, status=status.HTTP_403_FORBIDDEN)
        
        gym_owner = request.user.gymowner
        
        # Generate new QR token
        gym_owner.qr_code_token = uuid.uuid4()
        gym_owner.save()
        
        return Response({
            'success': True,
            'message': 'QR code token regenerated successfully',
            'qr_code_token': str(gym_owner.qr_code_token),
            'qr_code_url': f'/api/attendance/qr-checkin/{gym_owner.qr_code_token}/'
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'error': f'Failed to regenerate QR token: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([AllowAny])
def verify_qr_token(request):
    """
    Verify if QR token is valid and return gym information
    """
    try:
        qr_token = request.data.get('qr_token')
        
        if not qr_token:
            return Response({
                'error': 'QR token is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            gym_owner = GymOwner.objects.get(qr_code_token=qr_token)
            
            return Response({
                'success': True,
                'valid': True,
                'gym_name': gym_owner.gym_name,
                'gym_address': gym_owner.gym_address,
                'qr_code_url': f'/api/attendance/qr-checkin/{qr_token}/'
            }, status=status.HTTP_200_OK)
            
        except GymOwner.DoesNotExist:
            return Response({
                'success': True,
                'valid': False,
                'message': 'Invalid QR code'
            }, status=status.HTTP_200_OK)
            
    except Exception as e:
        return Response({
            'error': f'Failed to verify QR token: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


def _handle_base64_upload(request):
    """
    Handle base64 profile picture upload
    """
    try:
        gym_owner = request.user.gymowner
        
        base64_data = request.data.get('profile_picture_base64')
        content_type = request.data.get('content_type', 'image/jpeg')
        filename = request.data.get('filename', 'profile_picture.jpg')
        
        print(f"📤 BASE64 UPLOAD: Content type: {content_type}")
        print(f"📤 BASE64 UPLOAD: Filename: {filename}")
        print(f"📤 BASE64 UPLOAD: Base64 data length: {len(base64_data)} characters")
        
        # Validate content type
        allowed_types = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/heic', 'image/heif']
        if content_type not in allowed_types:
            return Response({
                'error': f'Invalid file type. Only JPEG, PNG, GIF, and HEIC images are allowed. Received: {content_type}'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Validate base64 data
        try:
            import base64
            file_content = base64.b64decode(base64_data)
            file_size = len(file_content)
            print(f"📤 BASE64 UPLOAD: Decoded file size: {file_size} bytes")
            
            # Check file size (max 5MB)
            if file_size > 5 * 1024 * 1024:
                return Response({
                    'error': 'File size too large. Maximum size is 5MB.'
                }, status=status.HTTP_400_BAD_REQUEST)
                
        except Exception as e:
            print(f"❌ BASE64 UPLOAD: Invalid base64 data: {e}")
            return Response({
                'error': 'Invalid base64 image data'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Store the base64 data directly (Railway-compatible approach)
        gym_owner.profile_picture_base64 = base64_data
        gym_owner.profile_picture_content_type = content_type
        gym_owner.save()
        
        print(f"✅ BASE64 UPLOAD: Profile picture saved successfully")
        
        # Return updated profile data with data URL
        serializer = GymOwnerSerializer(gym_owner, context={'request': request})
        
        # Create a data URL for immediate use
        data_url = f"data:{content_type};base64,{base64_data}"
        
        return Response({
            'success': True,
            'message': 'Profile picture uploaded successfully',
            'gym_owner': serializer.data,
            'profile_picture_url': data_url,
            'user': {
                'id': request.user.id,
                'email': request.user.email,
                'first_name': request.user.first_name,
                'last_name': request.user.last_name
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        print(f"❌ BASE64 UPLOAD ERROR: {str(e)}")
        return Response({
            'error': f'Failed to upload profile picture: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def gym_owner_upload_picture(request):
    """
    Upload profile picture for current gym owner
    Supports both multipart file upload and base64 data
    """
    try:
        # Check if user is a gym owner
        if not hasattr(request.user, 'gymowner'):
            return Response({
                'error': 'User is not a gym owner'
            }, status=status.HTTP_403_FORBIDDEN)
        
        # Check if this is a base64 upload (new method)
        if 'profile_picture_base64' in request.data:
            return _handle_base64_upload(request)
        
        # Legacy multipart file upload
        if 'profile_picture' not in request.FILES:
            return Response({
                'error': 'No profile picture file provided (use profile_picture for file upload or profile_picture_base64 for base64 data)'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        gym_owner = request.user.gymowner
        
        # Basic file validation
        uploaded_file = request.FILES['profile_picture']
        
        print(f"📤 UPLOAD: File name: {uploaded_file.name}")
        print(f"📤 UPLOAD: File size: {uploaded_file.size} bytes")
        print(f"📤 UPLOAD: Content type: {uploaded_file.content_type}")
        
        # Check file size (max 5MB)
        if uploaded_file.size > 5 * 1024 * 1024:
            return Response({
                'error': 'File size too large. Maximum size is 5MB.'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Check file type - be more flexible with iOS formats
        allowed_types = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/heic', 'image/heif']
        content_type = uploaded_file.content_type.lower() if uploaded_file.content_type else ''
        
        # Also check file extension as fallback
        file_name = uploaded_file.name.lower() if uploaded_file.name else ''
        allowed_extensions = ['.jpg', '.jpeg', '.png', '.gif', '.heic', '.heif']
        
        type_valid = content_type in allowed_types or any(file_name.endswith(ext) for ext in allowed_extensions)
        
        if not type_valid:
            print(f"❌ UPLOAD: Invalid file type - Content-Type: {content_type}, Filename: {file_name}")
            return Response({
                'error': f'Invalid file type. Only JPEG, PNG, GIF, and HEIC images are allowed. Received: {content_type}'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Save the uploaded file and also store as base64 for Railway
        print(f"💾 UPLOAD: Saving file to model...")
        
        # Store as base64 for reliable access on Railway
        import base64
        uploaded_file.seek(0)  # Reset file pointer
        file_content = uploaded_file.read()
        base64_content = base64.b64encode(file_content).decode('utf-8')
        
        gym_owner.profile_picture = uploaded_file
        gym_owner.profile_picture_base64 = base64_content
        gym_owner.profile_picture_content_type = uploaded_file.content_type
        gym_owner.save()
        
        print(f"✅ UPLOAD: File saved successfully")
        print(f"📁 UPLOAD: File path: {gym_owner.profile_picture.name}")
        print(f"💾 UPLOAD: Base64 length: {len(base64_content)} characters")
        print(f"🔗 UPLOAD: Relative URL: {gym_owner.profile_picture.url}")
        
        # Return updated profile data with full image URL
        serializer = GymOwnerSerializer(gym_owner, context={'request': request})
        
        # Create a data URL for immediate use
        data_url = f"data:{uploaded_file.content_type};base64,{base64_content}"
        print(f'🖼️ Generated data URL (first 100 chars): {data_url[:100]}...')
        
        # Try to build traditional URL, but fallback to data URL
        image_url = data_url  # Use data URL as primary
        try:
            traditional_url = request.build_absolute_uri(gym_owner.profile_picture.url)
            print(f'🔗 Traditional URL: {traditional_url}')
            # Could test accessibility here, but for now use data URL
        except Exception as e:
            print(f'❌ Error generating traditional URL: {e}')
        
        return Response({
            'success': True,
            'message': 'Profile picture uploaded successfully',
            'gym_owner': serializer.data,
            'profile_picture_url': image_url,
            'user': {
                'id': request.user.id,
                'email': request.user.email,
                'first_name': request.user.first_name,
                'last_name': request.user.last_name
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'error': f'Failed to upload profile picture: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def gym_owner_change_password(request):
    """
    Change password for current gym owner
    """
    try:
        current_password = request.data.get('current_password')
        new_password = request.data.get('new_password')
        
        if not current_password or not new_password:
            return Response({
                'error': 'Both current_password and new_password are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Verify current password
        if not request.user.check_password(current_password):
            return Response({
                'error': 'Current password is incorrect'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Validate new password length
        if len(new_password) < 8:
            return Response({
                'error': 'New password must be at least 8 characters long'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Set new password
        request.user.set_password(new_password)
        request.user.save()
        
        return Response({
            'success': True,
            'message': 'Password changed successfully'
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'error': f'Failed to change password: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([AllowAny])
def google_auth(request):
    """
    Google OAuth 2.0 authentication endpoint
    Authenticates users with Google ID tokens and creates or logs in gym owners
    """
    return handle_google_auth(request)


@api_view(['GET'])
@permission_classes([AllowAny])
def google_config_check(request):
    """
    Check Google OAuth configuration status
    """
    import os
    from django.conf import settings
    
    # Check environment variables
    client_id_env = os.getenv('GOOGLE_OAUTH2_CLIENT_ID')
    client_secret_env = os.getenv('GOOGLE_OAUTH2_CLIENT_SECRET')
    
    # Check Django settings
    try:
        settings_client_id = getattr(settings, 'GOOGLE_OAUTH2_CLIENT_ID', None)
        settings_client_secret = getattr(settings, 'GOOGLE_OAUTH2_CLIENT_SECRET', None)
    except Exception as e:
        settings_client_id = None
        settings_client_secret = None
    
    # Check Google library availability
    try:
        from google.auth.transport import requests as google_requests
        from google.oauth2 import id_token
        library_available = True
    except ImportError:
        library_available = False
    
    # Determine configuration status
    config_ready = bool(client_id_env and client_secret_env and library_available)
    
    return Response({
        'success': True,
        'config_ready': config_ready,
        'environment': {
            'client_id_set': bool(client_id_env),
            'client_secret_set': bool(client_secret_env),
            'client_id_preview': client_id_env[:20] + '...' if client_id_env else None,
            'client_secret_preview': client_secret_env[:10] + '...' if client_secret_env else None,
        },
        'django_settings': {
            'client_id_set': bool(settings_client_id),
            'client_secret_set': bool(settings_client_secret),
        },
        'library_available': library_available,
        'timestamp': '2025-07-16 18:50 IST',
        'deployment_status': 'active'
    }, status=status.HTTP_200_OK)