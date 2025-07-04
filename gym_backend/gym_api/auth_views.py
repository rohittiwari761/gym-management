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
import uuid


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
            
            # Serialize gym owner data
            serializer = GymOwnerSerializer(gym_owner)
            
            return Response({
                'success': True,
                'message': 'Gym owner registered successfully',
                'token': token.key,
                'gym_owner': serializer.data,
                'user': {
                    'id': user.id,
                    'email': user.email,
                    'first_name': user.first_name,
                    'last_name': user.last_name
                }
            }, status=status.HTTP_201_CREATED)
            
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
        
        # Serialize gym owner data
        serializer = GymOwnerSerializer(gym_owner)
        
        return Response({
            'success': True,
            'message': 'Login successful',
            'token': token.key,
            'gym_owner': serializer.data,
            'user': {
                'id': user.id,
                'email': user.email,
                'first_name': user.first_name,
                'last_name': user.last_name
            }
        }, status=status.HTTP_200_OK)
        
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
        serializer = GymOwnerSerializer(gym_owner)
        
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
        
        # Update user fields
        user_fields = ['first_name', 'last_name', 'email']
        for field in user_fields:
            if field in request.data:
                setattr(user, field, request.data[field])
        user.save()
        
        # Update gym owner fields
        gym_fields = ['gym_name', 'gym_address', 'gym_description', 'phone_number', 'gym_established_date', 'subscription_plan']
        for field in gym_fields:
            if field in request.data:
                setattr(gym_owner, field, request.data[field])
        gym_owner.save()
        
        # Serialize updated data
        serializer = GymOwnerSerializer(gym_owner)
        
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


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def gym_owner_upload_picture(request):
    """
    Upload profile picture for current gym owner
    """
    try:
        # Check if user is a gym owner
        if not hasattr(request.user, 'gymowner'):
            return Response({
                'error': 'User is not a gym owner'
            }, status=status.HTTP_403_FORBIDDEN)
        
        if 'profile_picture' not in request.FILES:
            return Response({
                'error': 'No profile picture file provided'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        gym_owner = request.user.gymowner
        
        # TODO: Add file validation (size, format, etc.)
        # For now, just save the uploaded file
        gym_owner.profile_picture = request.FILES['profile_picture']
        gym_owner.save()
        
        # Return updated profile data
        serializer = GymOwnerSerializer(gym_owner)
        
        return Response({
            'success': True,
            'message': 'Profile picture uploaded successfully',
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