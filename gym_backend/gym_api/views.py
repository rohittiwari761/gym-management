from rest_framework import viewsets, status, permissions, serializers
from rest_framework.decorators import action, throttle_classes
from rest_framework.response import Response
from rest_framework.throttling import UserRateThrottle, AnonRateThrottle
from rest_framework.pagination import PageNumberPagination
from django.contrib.auth.models import User
from django.shortcuts import get_object_or_404
from django.db.models import Q, Count, Sum, Prefetch, F, Avg
from django.utils import timezone
from django.views.decorators.cache import cache_page
from django.core.cache import cache
from django.utils.decorators import method_decorator
from datetime import timedelta, date
import logging

logger = logging.getLogger(__name__)
from .models import (
    GymOwner, Member, Trainer, Equipment, WorkoutPlan, Exercise, WorkoutSession, 
    MembershipPayment, Attendance, SubscriptionPlan, MemberSubscription, TrainerMemberAssociation,
    Notification, get_ist_now, get_ist_date
)
from .serializers import (
    UserSerializer, GymOwnerSerializer, MemberSerializer, TrainerSerializer, EquipmentSerializer,
    EquipmentListSerializer, GymOwnerMinimalSerializer, UserMinimalSerializer,
    MemberListSerializer, MembershipPaymentListSerializer,
    WorkoutPlanSerializer, ExerciseSerializer, WorkoutSessionSerializer,
    MembershipPaymentSerializer, AttendanceSerializer, SubscriptionPlanSerializer, 
    MemberSubscriptionSerializer, MemberSubscriptionListSerializer,
    TrainerMemberAssociationSerializer, NotificationSerializer
)


class GymOwnerViewSet(viewsets.ModelViewSet):
    queryset = GymOwner.objects.all()
    serializer_class = GymOwnerSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        # Only return the gym owner for the authenticated user
        if hasattr(self.request.user, 'gymowner'):
            return GymOwner.objects.filter(user=self.request.user)
        return GymOwner.objects.none()
    
    @action(detail=True, methods=['get'])
    def dashboard_stats(self, request, pk=None):
        gym_owner = self.get_object()
        today = timezone.now().date()
        
        stats = {
            'total_members': gym_owner.members.filter(is_active=True).count(),
            'total_trainers': gym_owner.trainers.filter(is_available=True).count(),
            'total_equipment': gym_owner.equipment.filter(is_working=True).count(),
            'active_subscriptions': gym_owner.member_subscriptions.filter(status='active').count(),
            'today_attendance': gym_owner.attendances.filter(date=today).count(),
            'monthly_revenue': gym_owner.payments.filter(
                payment_date__month=today.month,
                payment_date__year=today.year,
                status='completed'
            ).aggregate(total=Sum('amount'))['total'] or 0,
            'expiring_memberships': gym_owner.member_subscriptions.filter(
                status='active',
                end_date__lte=today + timedelta(days=7)
            ).count(),
        }
        
        return Response(stats)
    
    @action(detail=True, methods=['get'])
    def qr_code_info(self, request, pk=None):
        gym_owner = self.get_object()
        return Response({
            'qr_code_token': str(gym_owner.qr_code_token),
            'gym_name': gym_owner.gym_name,
            'qr_code_url': f'/api/attendance/qr-checkin/{gym_owner.qr_code_token}/'
        })


class MemberViewSet(viewsets.ModelViewSet):
    serializer_class = MemberSerializer
    permission_classes = [permissions.IsAuthenticated]
    throttle_classes = [UserRateThrottle]
    
    def get_queryset(self):
        # Filter members by gym owner with optimized queries
        if hasattr(self.request.user, 'gymowner'):
            return Member.objects.select_related('user', 'gym_owner').filter(
                gym_owner=self.request.user.gymowner
            ).order_by('-created_at')
        return Member.objects.none()
    
    def get_serializer_class(self):
        """Use optimized serializer for list views to reduce response size"""
        if self.action == 'list':
            # Check if client wants minimal data
            if self.request.query_params.get('minimal', 'false').lower() == 'true':
                return MemberListSerializer
        return MemberSerializer
    
    def list(self, request, *args, **kwargs):
        """Optimized list with pagination to reduce response sizes"""
        queryset = self.filter_queryset(self.get_queryset())
        
        # Apply pagination with small page size by default
        page_size = int(request.query_params.get('page_size', 25))  # Default 25 items
        page_size = min(page_size, 100)  # Max 100 items per page
        
        # Manual pagination to control response size
        page = int(request.query_params.get('page', 1))
        start = (page - 1) * page_size
        end = start + page_size
        
        total_count = queryset.count()
        queryset = queryset[start:end]
        
        # Use minimal serializer by default for list views
        serializer_class = self.get_serializer_class()
        serializer = serializer_class(queryset, many=True, context={'request': request})
        
        # Calculate response size estimate
        import sys
        response_size_kb = sys.getsizeof(str(serializer.data)) / 1024
        
        logger.info(f'Member list response: {len(queryset)} items, ~{response_size_kb:.1f}KB')
        
        return Response({
            'count': total_count,
            'page': page,
            'page_size': page_size,
            'total_pages': (total_count + page_size - 1) // page_size,
            'response_size_kb': round(response_size_kb, 1),
            'results': serializer.data
        })
    
    def perform_create(self, serializer):
        # Automatically assign gym owner on creation
        if hasattr(self.request.user, 'gymowner'):
            serializer.save(gym_owner=self.request.user.gymowner)
        else:
            raise serializers.ValidationError("User must be a gym owner to create members")
    
    @action(detail=True, methods=['get'])
    @method_decorator(cache_page(300))  # Cache for 5 minutes
    def attendance_history(self, request, pk=None):
        member = self.get_object()
        # Filter attendance by gym owner for security with optimized query
        attendance = Attendance.objects.select_related('member', 'gym_owner').filter(
            member=member,
            gym_owner=member.gym_owner
        ).order_by('-date')[:100]  # Limit to last 100 records
        serializer = AttendanceSerializer(attendance, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['get'])
    @method_decorator(cache_page(300))  # Cache for 5 minutes
    def payment_history(self, request, pk=None):
        member = self.get_object()
        # Filter payments by gym owner for security with optimized query
        payments = MembershipPayment.objects.select_related(
            'member', 'gym_owner', 'subscription_plan'
        ).filter(
            member=member,
            gym_owner=member.gym_owner
        ).order_by('-payment_date')[:50]  # Limit to last 50 payments
        serializer = MembershipPaymentSerializer(payments, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def active_members(self, request):
        # Get active members for current gym with pagination
        if hasattr(request.user, 'gymowner'):
            members = Member.objects.filter(
                gym_owner=request.user.gymowner,
                is_active=True
            ).select_related('user')
            
            # Apply pagination
            page_size = int(request.query_params.get('page_size', 25))
            page_size = min(page_size, 100)
            
            page = int(request.query_params.get('page', 1))
            start = (page - 1) * page_size
            end = start + page_size
            
            total_count = members.count()
            members = members[start:end]
            
            serializer = MemberListSerializer(members, many=True, context={'request': request})
            return Response({
                'count': total_count,
                'page': page,
                'page_size': page_size,
                'total_pages': (total_count + page_size - 1) // page_size,
                'results': serializer.data
            })
        return Response({'error': 'User must be a gym owner'}, status=status.HTTP_403_FORBIDDEN)
    
    @action(detail=False, methods=['get'])
    def expiring_memberships(self, request):
        # Get members with expiring memberships with pagination
        if hasattr(request.user, 'gymowner'):
            expiry_date = timezone.now().date() + timedelta(days=7)
            members = Member.objects.filter(
                gym_owner=request.user.gymowner,
                is_active=True,
                membership_expiry__lte=expiry_date
            ).select_related('user')
            
            # Apply pagination
            page_size = int(request.query_params.get('page_size', 25))
            page_size = min(page_size, 100)
            
            page = int(request.query_params.get('page', 1))
            start = (page - 1) * page_size
            end = start + page_size
            
            total_count = members.count()
            members = members[start:end]
            
            serializer = MemberListSerializer(members, many=True, context={'request': request})
            return Response({
                'count': total_count,
                'expiry_date': expiry_date.isoformat(),
                'page': page,
                'page_size': page_size,
                'total_pages': (total_count + page_size - 1) // page_size,
                'results': serializer.data
            })
        return Response({'error': 'User must be a gym owner'}, status=status.HTTP_403_FORBIDDEN)


class TrainerViewSet(viewsets.ModelViewSet):
    serializer_class = TrainerSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        # Filter trainers by gym owner
        if hasattr(self.request.user, 'gymowner'):
            return Trainer.objects.filter(gym_owner=self.request.user.gymowner)
        return Trainer.objects.none()
    
    def perform_create(self, serializer):
        # Automatically assign gym owner on creation
        if hasattr(self.request.user, 'gymowner'):
            serializer.save(gym_owner=self.request.user.gymowner)
        else:
            raise serializers.ValidationError("User must be a gym owner to create trainers")
    
    @action(detail=False, methods=['get'])
    def available(self, request):
        # Filter available trainers by gym owner
        if hasattr(request.user, 'gymowner'):
            available_trainers = Trainer.objects.filter(
                gym_owner=request.user.gymowner,
                is_available=True
            )
            serializer = self.get_serializer(available_trainers, many=True)
            return Response(serializer.data)
        return Response({'error': 'User must be a gym owner'}, status=status.HTTP_403_FORBIDDEN)
    
    @action(detail=True, methods=['get'])
    def members(self, request, pk=None):
        """Get all members associated with this trainer"""
        trainer = self.get_object()
        
        # Get active associations for this trainer
        associations = TrainerMemberAssociation.objects.filter(
            trainer=trainer,
            gym_owner=request.user.gymowner,
            is_active=True
        ).select_related('member', 'member__user')
        
        serializer = TrainerMemberAssociationSerializer(associations, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def associate_member(self, request, pk=None):
        """Associate a member with this trainer"""
        trainer = self.get_object()
        member_id = request.data.get('member_id')
        
        if not member_id:
            return Response({'error': 'member_id is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if member exists and belongs to this gym
        try:
            member = Member.objects.get(id=member_id, gym_owner=request.user.gymowner)
        except Member.DoesNotExist:
            return Response({'error': 'Member not found'}, status=status.HTTP_404_NOT_FOUND)
        
        # Check if association already exists
        existing_association = TrainerMemberAssociation.objects.filter(
            trainer=trainer,
            member=member,
            gym_owner=request.user.gymowner,
            is_active=True
        ).first()
        
        if existing_association:
            return Response({'error': 'Member is already associated with this trainer'}, 
                          status=status.HTTP_400_BAD_REQUEST)
        
        # Create new association
        serializer = TrainerMemberAssociationSerializer(
            data={
                'member_id': member_id,
                'trainer_id': trainer.id,
                'notes': request.data.get('notes', '')
            },
            context={
                'request': request,
                'gym_owner': request.user.gymowner
            }
        )
        
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['delete'])
    def unassociate_member(self, request, pk=None):
        """Remove association between trainer and member"""
        trainer = self.get_object()
        member_id = request.data.get('member_id')
        
        if not member_id:
            return Response({'error': 'member_id is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Find and deactivate the association
        try:
            association = TrainerMemberAssociation.objects.get(
                trainer=trainer,
                member_id=member_id,
                gym_owner=request.user.gymowner,
                is_active=True
            )
            association.deactivate()
            return Response({'message': 'Member successfully unassociated from trainer'}, 
                          status=status.HTTP_200_OK)
        except TrainerMemberAssociation.DoesNotExist:
            return Response({'error': 'Association not found'}, status=status.HTTP_404_NOT_FOUND)


class EquipmentViewSet(viewsets.ModelViewSet):
    serializer_class = EquipmentSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        # Filter equipment by gym owner with optimized ordering
        if hasattr(self.request.user, 'gymowner'):
            return Equipment.objects.filter(
                gym_owner=self.request.user.gymowner
            ).select_related('gym_owner').order_by('-created_at')
        return Equipment.objects.none()
    
    def get_serializer_class(self):
        """Use optimized serializer for list views to reduce response size"""
        if self.action == 'list':
            # Check if client wants minimal data
            if self.request.query_params.get('minimal', 'false').lower() == 'true':
                return EquipmentListSerializer
        return EquipmentSerializer
    
    def list(self, request, *args, **kwargs):
        """Optimized list with pagination to reduce 12MB responses to <1MB"""
        queryset = self.filter_queryset(self.get_queryset())
        
        # Apply pagination with small page size by default
        page_size = int(request.query_params.get('page_size', 10))  # Default 10 items
        page_size = min(page_size, 50)  # Max 50 items per page
        
        # Manual pagination to control response size
        page = int(request.query_params.get('page', 1))
        start = (page - 1) * page_size
        end = start + page_size
        
        total_count = queryset.count()
        queryset = queryset[start:end]
        
        # Use minimal serializer by default for list views
        serializer_class = self.get_serializer_class()
        serializer = serializer_class(queryset, many=True, context={'request': request})
        
        # Calculate response size estimate
        import sys
        response_size_kb = sys.getsizeof(str(serializer.data)) / 1024
        
        logger.info(f'Equipment list response: {len(queryset)} items, ~{response_size_kb:.1f}KB')
        
        return Response({
            'count': total_count,
            'page': page,
            'page_size': page_size,
            'total_pages': (total_count + page_size - 1) // page_size,
            'response_size_kb': round(response_size_kb, 1),
            'results': serializer.data
        })
    
    def perform_create(self, serializer):
        # Automatically assign gym owner on creation
        if hasattr(self.request.user, 'gymowner'):
            serializer.save(gym_owner=self.request.user.gymowner)
        else:
            raise serializers.ValidationError("User must be a gym owner to create equipment")
    
    @action(detail=False, methods=['get'])
    def working(self, request):
        # Filter working equipment by gym owner with pagination
        if hasattr(request.user, 'gymowner'):
            working_equipment = Equipment.objects.filter(
                gym_owner=request.user.gymowner,
                is_working=True
            ).select_related('gym_owner')
            
            # Apply pagination for working equipment too
            page_size = int(request.query_params.get('page_size', 15))  # Default 15 items
            page_size = min(page_size, 50)  # Max 50 items
            
            page = int(request.query_params.get('page', 1))
            start = (page - 1) * page_size
            end = start + page_size
            
            total_count = working_equipment.count()
            working_equipment = working_equipment[start:end]
            
            # Use minimal serializer for better performance
            serializer = EquipmentListSerializer(working_equipment, many=True, context={'request': request})
            
            return Response({
                'count': total_count,
                'page': page,
                'page_size': page_size,
                'total_pages': (total_count + page_size - 1) // page_size,
                'results': serializer.data
            })
        return Response({'error': 'User must be a gym owner'}, status=status.HTTP_403_FORBIDDEN)
    
    @action(detail=False, methods=['get'])
    def by_type(self, request):
        equipment_type = request.query_params.get('type')
        if equipment_type:
            if hasattr(request.user, 'gymowner'):
                equipment = Equipment.objects.filter(
                    gym_owner=request.user.gymowner,
                    equipment_type=equipment_type
                ).select_related('gym_owner')
                
                # Apply pagination for type filtering too
                page_size = int(request.query_params.get('page_size', 15))
                page_size = min(page_size, 50)
                
                page = int(request.query_params.get('page', 1))
                start = (page - 1) * page_size
                end = start + page_size
                
                total_count = equipment.count()
                equipment = equipment[start:end]
                
                serializer = EquipmentListSerializer(equipment, many=True, context={'request': request})
                return Response({
                    'count': total_count,
                    'equipment_type': equipment_type,
                    'page': page,
                    'page_size': page_size,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'results': serializer.data
                })
            return Response({'error': 'User must be a gym owner'}, status=status.HTTP_403_FORBIDDEN)
        return Response({'error': 'Type parameter required'}, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'])
    def maintenance_due(self, request):
        # Get equipment needing maintenance with pagination
        if hasattr(request.user, 'gymowner'):
            today = timezone.now().date()
            equipment = Equipment.objects.filter(
                gym_owner=request.user.gymowner,
                next_maintenance_date__lte=today
            ).select_related('gym_owner')
            
            # Apply pagination
            page_size = int(request.query_params.get('page_size', 15))
            page_size = min(page_size, 50)
            
            page = int(request.query_params.get('page', 1))
            start = (page - 1) * page_size
            end = start + page_size
            
            total_count = equipment.count()
            equipment = equipment[start:end]
            
            serializer = EquipmentListSerializer(equipment, many=True, context={'request': request})
            return Response({
                'count': total_count,
                'maintenance_due_date': today.isoformat(),
                'page': page,
                'page_size': page_size,
                'total_pages': (total_count + page_size - 1) // page_size,
                'results': serializer.data
            })
        return Response({'error': 'User must be a gym owner'}, status=status.HTTP_403_FORBIDDEN)


class WorkoutPlanViewSet(viewsets.ModelViewSet):
    serializer_class = WorkoutPlanSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        # Filter workout plans by gym owner
        if hasattr(self.request.user, 'gymowner'):
            return WorkoutPlan.objects.filter(gym_owner=self.request.user.gymowner)
        return WorkoutPlan.objects.none()
    
    def perform_create(self, serializer):
        # Automatically assign gym owner on creation
        if hasattr(self.request.user, 'gymowner'):
            serializer.save(gym_owner=self.request.user.gymowner)
        else:
            raise serializers.ValidationError("User must be a gym owner to create workout plans")
    
    @action(detail=False, methods=['get'])
    def by_difficulty(self, request):
        difficulty = request.query_params.get('difficulty')
        if difficulty:
            if hasattr(request.user, 'gymowner'):
                plans = WorkoutPlan.objects.filter(
                    gym_owner=request.user.gymowner,
                    difficulty_level=difficulty,
                    is_active=True
                )
                serializer = self.get_serializer(plans, many=True)
                return Response(serializer.data)
            return Response({'error': 'User must be a gym owner'}, status=status.HTTP_403_FORBIDDEN)
        return Response({'error': 'Difficulty parameter required'}, status=status.HTTP_400_BAD_REQUEST)


class ExerciseViewSet(viewsets.ModelViewSet):
    serializer_class = ExerciseSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        # Filter exercises by gym owner
        if hasattr(self.request.user, 'gymowner'):
            return Exercise.objects.filter(gym_owner=self.request.user.gymowner)
        return Exercise.objects.none()
    
    def perform_create(self, serializer):
        # Automatically assign gym owner on creation
        if hasattr(self.request.user, 'gymowner'):
            serializer.save(gym_owner=self.request.user.gymowner)
        else:
            raise serializers.ValidationError("User must be a gym owner to create exercises")
    
    @action(detail=False, methods=['get'])
    def by_muscle_group(self, request):
        muscle_group = request.query_params.get('muscle_group')
        if muscle_group:
            if hasattr(request.user, 'gymowner'):
                exercises = Exercise.objects.filter(
                    gym_owner=request.user.gymowner,
                    muscle_group=muscle_group
                )
                serializer = self.get_serializer(exercises, many=True)
                return Response(serializer.data)
            return Response({'error': 'User must be a gym owner'}, status=status.HTTP_403_FORBIDDEN)
        return Response({'error': 'Muscle group parameter required'}, status=status.HTTP_400_BAD_REQUEST)


class WorkoutSessionViewSet(viewsets.ModelViewSet):
    serializer_class = WorkoutSessionSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        # Filter workout sessions by gym owner
        if hasattr(self.request.user, 'gymowner'):
            return WorkoutSession.objects.filter(gym_owner=self.request.user.gymowner)
        return WorkoutSession.objects.none()
    
    def perform_create(self, serializer):
        # Automatically assign gym owner on creation
        if hasattr(self.request.user, 'gymowner'):
            serializer.save(gym_owner=self.request.user.gymowner)
        else:
            raise serializers.ValidationError("User must be a gym owner to create workout sessions")
    
    @action(detail=False, methods=['get'])
    def upcoming(self, request):
        if hasattr(request.user, 'gymowner'):
            upcoming_sessions = WorkoutSession.objects.filter(
                gym_owner=request.user.gymowner,
                date__gte=timezone.now(),
                completed=False
            ).order_by('date')
            serializer = self.get_serializer(upcoming_sessions, many=True)
            return Response(serializer.data)
        return Response({'error': 'User must be a gym owner'}, status=status.HTTP_403_FORBIDDEN)
    
    @action(detail=True, methods=['post'])
    def mark_completed(self, request, pk=None):
        session = self.get_object()
        session.completed = True
        session.save()
        return Response({'status': 'Session marked as completed'})


class MembershipPaymentViewSet(viewsets.ModelViewSet):
    serializer_class = MembershipPaymentSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        # Filter payments by gym owner with optimized queries and descending order
        if hasattr(self.request.user, 'gymowner'):
            return MembershipPayment.objects.select_related(
                'member__user', 'subscription_plan', 'gym_owner'
            ).filter(
                gym_owner=self.request.user.gymowner
            ).order_by('-payment_date', '-created_at')  # Newest payments first
        return MembershipPayment.objects.none()
    
    def perform_create(self, serializer):
        # Automatically assign gym owner on creation and extend membership
        if hasattr(self.request.user, 'gymowner'):
            try:
                payment = serializer.save(gym_owner=self.request.user.gymowner)
                
                # Safe logging with null checks
                member_name = 'Unknown Member'
                if payment.member and payment.member.user:
                    member_name = payment.member.user.get_full_name() or f"User ID: {payment.member.user.id}"
                
                print(f'💳 PAYMENT: Created payment ID {payment.id} for member {member_name}')
                print(f'💳 PAYMENT: Membership months: {payment.membership_months}')
                print(f'💳 PAYMENT: Amount: {payment.amount}')
                
                # Note: Membership extension is handled automatically in the MembershipPayment model's save method
                print(f'✅ PAYMENT: Payment created successfully, membership extension handled by model')
                    
            except Exception as e:
                print(f'❌ PAYMENT: Error in perform_create: {str(e)}')
                import traceback
                print(f'❌ PAYMENT: Traceback: {traceback.format_exc()}')
                raise serializers.ValidationError(f"Payment creation failed: {str(e)}")
        else:
            raise serializers.ValidationError("User must be a gym owner to create payments")
    
    @action(detail=False, methods=['get'])
    def monthly_revenue(self, request):
        # Get monthly revenue for current gym
        if hasattr(request.user, 'gymowner'):
            today = timezone.now().date()
            payments = MembershipPayment.objects.filter(
                gym_owner=request.user.gymowner,
                payment_date__month=today.month,
                payment_date__year=today.year,
                status='completed'
            )
            total_revenue = payments.aggregate(total=Sum('amount'))['total'] or 0
            payment_count = payments.count()
            
            return Response({
                'total_revenue': total_revenue,
                'payment_count': payment_count,
                'month': today.strftime('%B %Y')
            })
        return Response({'error': 'User must be a gym owner'}, status=status.HTTP_403_FORBIDDEN)
    
    @action(detail=False, methods=['get'])
    @throttle_classes([UserRateThrottle])
    def revenue_analytics(self, request):
        """Get comprehensive revenue analytics for current gym - OPTIMIZED"""
        if hasattr(request.user, 'gymowner'):
            gym_owner = request.user.gymowner
            cache_key = f'revenue_analytics_{gym_owner.id}'
            
            # Try to get from cache first
            cached_result = cache.get(cache_key)
            if cached_result:
                logger.info(f'Revenue analytics served from cache for gym {gym_owner.id}')
                return Response(cached_result)
            
            today = timezone.now().date()
            week_ago = today - timedelta(days=7)
            
            # OPTIMIZED: Single query with aggregations instead of multiple queries
            revenue_stats = MembershipPayment.objects.filter(
                gym_owner=gym_owner,
                status='completed'
            ).aggregate(
                # All time revenue
                total_revenue=Sum('amount'),
                
                # Monthly revenue
                monthly_revenue=Sum('amount', filter=Q(
                    payment_date__month=today.month,
                    payment_date__year=today.year
                )),
                
                # Weekly revenue
                weekly_revenue=Sum('amount', filter=Q(
                    payment_date__date__gte=week_ago,
                    payment_date__date__lte=today
                )),
                
                # Daily revenue
                daily_revenue=Sum('amount', filter=Q(payment_date__date=today)),
                
                # Payment counts for additional insights
                total_payments=Count('id'),
                monthly_payments=Count('id', filter=Q(
                    payment_date__month=today.month,
                    payment_date__year=today.year
                )),
                
                # Average payment amount
                avg_payment=Avg('amount')
            )
            
            result = {
                'total_revenue': float(revenue_stats['total_revenue'] or 0),
                'monthly_revenue': float(revenue_stats['monthly_revenue'] or 0),
                'weekly_revenue': float(revenue_stats['weekly_revenue'] or 0),
                'daily_revenue': float(revenue_stats['daily_revenue'] or 0),
                'analytics': {
                    'total_payments': revenue_stats['total_payments'] or 0,
                    'monthly_payments': revenue_stats['monthly_payments'] or 0,
                    'avg_payment_amount': float(revenue_stats['avg_payment'] or 0),
                    'weekly_growth': self._calculate_growth_rate(gym_owner.id, 'weekly'),
                    'monthly_growth': self._calculate_growth_rate(gym_owner.id, 'monthly'),
                },
                'currency': '₹',
                'date': today,
                'cached_at': timezone.now().isoformat()
            }
            
            # Cache the result for 10 minutes (revenue changes less frequently)
            cache.set(cache_key, result, 600)
            logger.info(f'Revenue analytics calculated and cached for gym {gym_owner.id}')
            
            return Response(result)
        return Response({'error': 'User must be a gym owner'}, status=status.HTTP_403_FORBIDDEN)
    
    def _calculate_growth_rate(self, gym_owner_id, period='weekly'):
        """Calculate growth rate for revenue analytics"""
        cache_key = f'growth_rate_{gym_owner_id}_{period}'
        cached_rate = cache.get(cache_key)
        if cached_rate is not None:
            return cached_rate
        
        # Simplified growth calculation - can be enhanced
        today = timezone.now().date()
        if period == 'weekly':
            current_start = today - timedelta(days=7)
            previous_start = today - timedelta(days=14)
            previous_end = today - timedelta(days=7)
        else:  # monthly
            current_start = today.replace(day=1)
            if today.month == 1:
                previous_start = date(today.year - 1, 12, 1)
                previous_end = date(today.year, 1, 1) - timedelta(days=1)
            else:
                previous_start = date(today.year, today.month - 1, 1)
                previous_end = current_start - timedelta(days=1)
        
        try:
            current_revenue = MembershipPayment.objects.filter(
                gym_owner_id=gym_owner_id,
                status='completed',
                payment_date__date__gte=current_start,
                payment_date__date__lte=today
            ).aggregate(total=Sum('amount'))['total'] or 0
            
            previous_revenue = MembershipPayment.objects.filter(
                gym_owner_id=gym_owner_id,
                status='completed',
                payment_date__date__gte=previous_start,
                payment_date__date__lte=previous_end
            ).aggregate(total=Sum('amount'))['total'] or 0
            
            if previous_revenue > 0:
                growth_rate = ((current_revenue - previous_revenue) / previous_revenue) * 100
            else:
                growth_rate = 100 if current_revenue > 0 else 0
                
            growth_rate = round(growth_rate, 1)
            cache.set(cache_key, growth_rate, 3600)  # Cache for 1 hour
            return growth_rate
        except:
            return 0.0


class AttendanceViewSet(viewsets.ModelViewSet):
    serializer_class = AttendanceSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        # Filter attendance by gym owner and optionally by date
        if hasattr(self.request.user, 'gymowner'):
            queryset = Attendance.objects.filter(gym_owner=self.request.user.gymowner)
            
            # Check for date parameter in query string
            date_param = self.request.query_params.get('date')
            print(f'🔍 ATTENDANCE: Received query params: {dict(self.request.query_params)}')
            print(f'🔍 ATTENDANCE: Date parameter: {date_param}')
            
            if date_param:
                try:
                    # Parse date from YYYY-MM-DD format
                    from datetime import datetime
                    filter_date = datetime.strptime(date_param, '%Y-%m-%d').date()
                    
                    # Debug: Show what we're filtering for vs what exists
                    total_count = queryset.count()
                    queryset = queryset.filter(date=filter_date)
                    filtered_count = queryset.count()
                    
                    print(f'📅 ATTENDANCE: Filtering by date {filter_date}')
                    print(f'📊 ATTENDANCE: Total records: {total_count}, After date filter: {filtered_count}')
                    
                    # Debug: Show actual dates in database
                    all_dates = Attendance.objects.filter(gym_owner=self.request.user.gymowner).values_list('date', flat=True).distinct()
                    print(f'📅 ATTENDANCE: Available dates in DB: {list(all_dates)}')
                    
                except ValueError:
                    print(f'❌ ATTENDANCE: Invalid date format {date_param}, returning all records')
            else:
                print(f'📋 ATTENDANCE: No date filter applied, returning all records')
            
            return queryset.order_by('-date', '-check_in_time')
        return Attendance.objects.none()
    
    def perform_create(self, serializer):
        # Automatically assign gym owner on creation
        if hasattr(self.request.user, 'gymowner'):
            serializer.save(gym_owner=self.request.user.gymowner)
        else:
            raise serializers.ValidationError("User must be a gym owner to create attendance records")
    
    @action(detail=False, methods=['post'])
    def check_in(self, request):
        member_id = request.data.get('member_id')
        if not member_id:
            return Response({'error': 'Member ID required'}, status=status.HTTP_400_BAD_REQUEST)
        
        if not hasattr(request.user, 'gymowner'):
            return Response({'error': 'User must be a gym owner'}, status=status.HTTP_403_FORBIDDEN)
        
        try:
            # Ensure member belongs to the current gym
            member = Member.objects.get(
                id=member_id,
                gym_owner=request.user.gymowner
            )
            today = timezone.now().date()
            
            attendance, created = Attendance.objects.get_or_create(
                member=member,
                gym_owner=request.user.gymowner,
                date=today,
                defaults={
                    'check_in_time': timezone.now(),
                    'qr_code_used': request.data.get('qr_code_used', False)
                }
            )
            
            if not created:
                return Response({'error': 'Already checked in today'}, status=status.HTTP_400_BAD_REQUEST)
            
            serializer = self.get_serializer(attendance)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        
        except Member.DoesNotExist:
            return Response({'error': 'Member not found or does not belong to your gym'}, status=status.HTTP_404_NOT_FOUND)
    
    @action(detail=False, methods=['post'])
    def check_out(self, request):
        member_id = request.data.get('member_id')
        if not member_id:
            return Response({'error': 'Member ID required'}, status=status.HTTP_400_BAD_REQUEST)
        
        if not hasattr(request.user, 'gymowner'):
            return Response({'error': 'User must be a gym owner'}, status=status.HTTP_403_FORBIDDEN)
        
        try:
            # Ensure member belongs to the current gym
            member = Member.objects.get(
                id=member_id,
                gym_owner=request.user.gymowner
            )
            today = timezone.now().date()
            
            attendance = Attendance.objects.get(
                member=member,
                gym_owner=request.user.gymowner,
                date=today
            )
            
            if attendance.check_out_time:
                return Response({'error': 'Already checked out today'}, status=status.HTTP_400_BAD_REQUEST)
            
            attendance.check_out_time = timezone.now()
            attendance.notes = request.data.get('notes', '')
            attendance.save()
            
            serializer = self.get_serializer(attendance)
            return Response(serializer.data)
        
        except Member.DoesNotExist:
            return Response({'error': 'Member not found or does not belong to your gym'}, status=status.HTTP_404_NOT_FOUND)
        except Attendance.DoesNotExist:
            return Response({'error': 'No check-in record found for today'}, status=status.HTTP_404_NOT_FOUND)
    
    @action(detail=False, methods=['post'])
    def qr_checkin(self, request, qr_token=None):
        """QR code-based check-in for members"""
        if not qr_token:
            qr_token = request.data.get('qr_token')
        
        if not qr_token:
            return Response({'error': 'QR token required'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            # Find gym by QR token
            gym_owner = GymOwner.objects.get(qr_code_token=qr_token)
            
            # Get member info from request
            member_email = request.data.get('member_email')
            member_id = request.data.get('member_id')
            
            if member_email:
                member = Member.objects.get(
                    user__email=member_email,
                    gym_owner=gym_owner
                )
            elif member_id:
                member = Member.objects.get(
                    id=member_id,
                    gym_owner=gym_owner
                )
            else:
                return Response({'error': 'Member email or ID required'}, status=status.HTTP_400_BAD_REQUEST)
            
            today = timezone.now().date()
            
            attendance, created = Attendance.objects.get_or_create(
                member=member,
                gym_owner=gym_owner,
                date=today,
                defaults={
                    'check_in_time': timezone.now(),
                    'qr_code_used': True
                }
            )
            
            if not created:
                return Response({'error': 'Already checked in today'}, status=status.HTTP_400_BAD_REQUEST)
            
            serializer = self.get_serializer(attendance)
            return Response({
                'success': True,
                'message': f'Successfully checked in to {gym_owner.gym_name}',
                'attendance': serializer.data
            }, status=status.HTTP_201_CREATED)
        
        except GymOwner.DoesNotExist:
            return Response({'error': 'Invalid QR code'}, status=status.HTTP_404_NOT_FOUND)
        except Member.DoesNotExist:
            return Response({'error': 'Member not found or not registered at this gym'}, status=status.HTTP_404_NOT_FOUND)
    
    @action(detail=False, methods=['get'])
    def today_attendance(self, request):
        """Get today's attendance for the gym"""
        if hasattr(request.user, 'gymowner'):
            today = timezone.now().date()
            attendance = Attendance.objects.filter(
                gym_owner=request.user.gymowner,
                date=today
            ).order_by('-check_in_time')
            
            serializer = self.get_serializer(attendance, many=True)
            return Response({
                'date': today,
                'total_checkins': attendance.count(),
                'total_checkouts': attendance.filter(check_out_time__isnull=False).count(),
                'attendances': serializer.data
            })
        return Response({'error': 'User must be a gym owner'}, status=status.HTTP_403_FORBIDDEN)
    
    @action(detail=False, methods=['get'])
    @throttle_classes([UserRateThrottle])
    def attendance_analytics(self, request):
        """Get comprehensive attendance analytics for current gym - OPTIMIZED"""
        if hasattr(request.user, 'gymowner'):
            gym_owner = request.user.gymowner
            cache_key = f'attendance_analytics_{gym_owner.id}'
            
            # Try to get from cache first
            cached_result = cache.get(cache_key)
            if cached_result:
                logger.info(f'Attendance analytics served from cache for gym {gym_owner.id}')
                return Response(cached_result)
            
            today = timezone.now().date()
            week_ago = today - timedelta(days=7)
            
            # OPTIMIZED: Single query with aggregations instead of multiple queries
            attendance_stats = Attendance.objects.filter(
                gym_owner=gym_owner
            ).aggregate(
                # Today's stats
                today_present=Count('id', filter=Q(date=today)),
                today_checked_out=Count('id', filter=Q(date=today, check_out_time__isnull=False)),
                
                # Week stats
                week_total_visits=Count('id', filter=Q(date__gte=week_ago, date__lte=today)),
                week_unique_members=Count('member', filter=Q(date__gte=week_ago, date__lte=today), distinct=True),
                
                # Month stats
                month_total_visits=Count('id', filter=Q(date__month=today.month, date__year=today.year)),
                month_unique_members=Count('member', filter=Q(date__month=today.month, date__year=today.year), distinct=True),
                
                # Average session time
                avg_session_time=Avg('session_duration_minutes', filter=Q(session_duration_minutes__isnull=False))
            )
            
            # Get total active members (cached separately as it changes less frequently)
            active_members_cache_key = f'active_members_count_{gym_owner.id}'
            total_active_members = cache.get(active_members_cache_key)
            if total_active_members is None:
                total_active_members = gym_owner.members.filter(is_active=True).count()
                cache.set(active_members_cache_key, total_active_members, 1800)  # Cache for 30 minutes
            
            # Calculate derived stats
            today_present = attendance_stats['today_present'] or 0
            today_checked_out = attendance_stats['today_checked_out'] or 0
            today_absent = total_active_members - today_present
            week_total_visits = attendance_stats['week_total_visits'] or 0
            month_total_visits = attendance_stats['month_total_visits'] or 0
            
            result = {
                'today': {
                    'present': today_present,
                    'absent': today_absent,
                    'checked_out': today_checked_out,
                    'still_in_gym': today_present - today_checked_out
                },
                'week': {
                    'total_visits': week_total_visits,
                    'unique_members': attendance_stats['week_unique_members'] or 0,
                    'average_daily_visits': round(week_total_visits / 7, 1)
                },
                'month': {
                    'total_visits': month_total_visits,
                    'unique_members': attendance_stats['month_unique_members'] or 0,
                    'average_daily_visits': round(month_total_visits / 30, 1) if month_total_visits > 0 else 0
                },
                'performance': {
                    'avg_session_time_minutes': round(attendance_stats['avg_session_time'] or 0, 1),
                    'utilization_rate': round((today_present / total_active_members * 100), 1) if total_active_members > 0 else 0
                },
                'total_active_members': total_active_members,
                'date': today,
                'cached_at': timezone.now().isoformat()
            }
            
            # Cache the result for 5 minutes
            cache.set(cache_key, result, 300)
            logger.info(f'Attendance analytics calculated and cached for gym {gym_owner.id}')
            
            return Response(result)
        return Response({'error': 'User must be a gym owner'}, status=status.HTTP_403_FORBIDDEN)


class SubscriptionPlanViewSet(viewsets.ModelViewSet):
    serializer_class = SubscriptionPlanSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        # Filter subscription plans by gym owner
        if hasattr(self.request.user, 'gymowner'):
            return SubscriptionPlan.objects.filter(gym_owner=self.request.user.gymowner)
        return SubscriptionPlan.objects.none()
    
    def perform_create(self, serializer):
        # Automatically assign gym owner on creation
        if hasattr(self.request.user, 'gymowner'):
            serializer.save(gym_owner=self.request.user.gymowner)
        else:
            raise serializers.ValidationError("User must be a gym owner to create subscription plans")
    
    @action(detail=False, methods=['get'])
    def active(self, request):
        if hasattr(request.user, 'gymowner'):
            active_plans = SubscriptionPlan.objects.filter(
                gym_owner=request.user.gymowner,
                is_active=True
            )
            serializer = self.get_serializer(active_plans, many=True)
            return Response(serializer.data)
        return Response({'error': 'User must be a gym owner'}, status=status.HTTP_403_FORBIDDEN)


class MemberSubscriptionViewSet(viewsets.ModelViewSet):
    serializer_class = MemberSubscriptionSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        # Filter member subscriptions by gym owner with optimized queries
        if hasattr(self.request.user, 'gymowner'):
            return MemberSubscription.objects.select_related(
                'member__user', 'subscription_plan', 'gym_owner'
            ).filter(
                gym_owner=self.request.user.gymowner
            ).order_by('-created_at')
        return MemberSubscription.objects.none()
    
    def get_serializer_class(self):
        """Use optimized serializer for list views to reduce response size"""
        if self.action == 'list':
            # Check if client wants minimal data
            if self.request.query_params.get('minimal', 'false').lower() == 'true':
                return MemberSubscriptionListSerializer
        return MemberSubscriptionSerializer
    
    def list(self, request, *args, **kwargs):
        """Optimized list with pagination to reduce response sizes"""
        queryset = self.filter_queryset(self.get_queryset())
        
        # Add pagination with reduced page size
        page_size = min(int(request.query_params.get('page_size', 25)), 50)  # Max 50 items per page
        paginator = PageNumberPagination()
        paginator.page_size = page_size
        page = paginator.paginate_queryset(queryset, request)
        
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            response = paginator.get_paginated_response(serializer.data)
            
            # Log response size for monitoring
            response_size = len(str(response.data))
            print(f'📊 MEMBER_SUBSCRIPTIONS: Returning page with {len(page)} items (~{response_size} bytes)')
            
            return response
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    def perform_create(self, serializer):
        # Automatically assign gym owner on creation
        if hasattr(self.request.user, 'gymowner'):
            serializer.save(gym_owner=self.request.user.gymowner)
        else:
            raise serializers.ValidationError("User must be a gym owner to create member subscriptions")
    
    @action(detail=False, methods=['get'])
    def active(self, request):
        if hasattr(request.user, 'gymowner'):
            active_subscriptions = MemberSubscription.objects.filter(
                gym_owner=request.user.gymowner,
                status='active'
            )
            serializer = self.get_serializer(active_subscriptions, many=True)
            return Response(serializer.data)
        return Response({'error': 'User must be a gym owner'}, status=status.HTTP_403_FORBIDDEN)
    
    @action(detail=False, methods=['get'])
    def expiring_soon(self, request):
        if hasattr(request.user, 'gymowner'):
            soon_date = timezone.now().date() + timedelta(days=7)
            expiring_subscriptions = MemberSubscription.objects.filter(
                gym_owner=request.user.gymowner,
                status='active',
                end_date__lte=soon_date
            )
            serializer = self.get_serializer(expiring_subscriptions, many=True)
            return Response(serializer.data)
        return Response({'error': 'User must be a gym owner'}, status=status.HTTP_403_FORBIDDEN)


class TrainerMemberAssociationViewSet(viewsets.ModelViewSet):
    serializer_class = TrainerMemberAssociationSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        # Filter associations by gym owner
        if hasattr(self.request.user, 'gymowner'):
            return TrainerMemberAssociation.objects.filter(
                gym_owner=self.request.user.gymowner
            ).select_related('trainer', 'member', 'trainer__user', 'member__user')
        return TrainerMemberAssociation.objects.none()
    
    def perform_create(self, serializer):
        # Automatically assign gym owner on creation
        if hasattr(self.request.user, 'gymowner'):
            serializer.save(
                gym_owner=self.request.user.gymowner,
                assigned_by=self.request.user
            )
        else:
            raise serializers.ValidationError("User must be a gym owner to create associations")
    
    @action(detail=False, methods=['get'])
    def active(self, request):
        """Get all active trainer-member associations"""
        if hasattr(request.user, 'gymowner'):
            active_associations = self.get_queryset().filter(is_active=True)
            serializer = self.get_serializer(active_associations, many=True)
            return Response(serializer.data)
        return Response({'error': 'User must be a gym owner'}, status=status.HTTP_403_FORBIDDEN)
    
    @action(detail=False, methods=['get'])
    def by_trainer(self, request):
        """Get associations grouped by trainer"""
        if not hasattr(request.user, 'gymowner'):
            return Response({'error': 'User must be a gym owner'}, status=status.HTTP_403_FORBIDDEN)
        
        trainer_id = request.query_params.get('trainer_id')
        if not trainer_id:
            return Response({'error': 'trainer_id parameter is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        associations = self.get_queryset().filter(
            trainer_id=trainer_id,
            is_active=True
        )
        serializer = self.get_serializer(associations, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def by_member(self, request):
        """Get associations for a specific member"""
        if not hasattr(request.user, 'gymowner'):
            return Response({'error': 'User must be a gym owner'}, status=status.HTTP_403_FORBIDDEN)
        
        member_id = request.query_params.get('member_id')
        if not member_id:
            return Response({'error': 'member_id parameter is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        associations = self.get_queryset().filter(
            member_id=member_id,
            is_active=True
        )
        serializer = self.get_serializer(associations, many=True)
        return Response(serializer.data)


class NotificationViewSet(viewsets.ModelViewSet):
    """ViewSet for managing gym owner notifications"""
    serializer_class = NotificationSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        """Filter notifications by gym owner"""
        if hasattr(self.request.user, 'gymowner'):
            return Notification.objects.filter(
                gym_owner=self.request.user.gymowner
            ).select_related('related_member__user', 'related_payment')
        return Notification.objects.none()
    
    @action(detail=False, methods=['get'])
    def unread_count(self, request):
        """Get count of unread notifications"""
        if hasattr(request.user, 'gymowner'):
            count = self.get_queryset().filter(is_read=False).count()
            return Response({'unread_count': count})
        return Response({'error': 'User must be a gym owner'}, status=status.HTTP_403_FORBIDDEN)
    
    @action(detail=True, methods=['post'])
    def mark_as_read(self, request, pk=None):
        """Mark a specific notification as read"""
        notification = self.get_object()
        notification.mark_as_read()
        return Response({'status': 'marked as read'})
    
    @action(detail=False, methods=['post'])
    def mark_all_as_read(self, request):
        """Mark all notifications as read for the gym owner"""
        if hasattr(request.user, 'gymowner'):
            updated = self.get_queryset().filter(is_read=False).update(
                is_read=True,
                read_at=timezone.now()
            )
            return Response({'status': f'marked {updated} notifications as read'})
        return Response({'error': 'User must be a gym owner'}, status=status.HTTP_403_FORBIDDEN)
    
    @action(detail=False, methods=['get'])
    def check_expiring_members(self, request):
        """Check for expiring members and create notifications"""
        if hasattr(request.user, 'gymowner'):
            gym_owner = request.user.gymowner
            today = get_ist_date()
            next_week = today + timedelta(days=7)
            
            # Find members expiring within 7 days
            expiring_members = Member.objects.filter(
                gym_owner=gym_owner,
                is_active=True,
                membership_expiry__gte=today,
                membership_expiry__lte=next_week
            )
            
            if expiring_members.exists():
                # Check if we already have a recent notification for expiring members
                recent_notification = Notification.objects.filter(
                    gym_owner=gym_owner,
                    type='member_expiring_soon',
                    created_at__gte=today
                ).exists()
                
                if not recent_notification:
                    # Create notification for expiring members
                    Notification.create_expiring_soon_notification(
                        gym_owner, list(expiring_members)
                    )
                    
            return Response({
                'expiring_count': expiring_members.count(),
                'notification_created': expiring_members.exists() and not recent_notification
            })
        return Response({'error': 'User must be a gym owner'}, status=status.HTTP_403_FORBIDDEN)


# Web attendance views for QR code access
from django.http import HttpResponse, JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
import json

@require_http_methods(["GET"])
def web_attendance_page(request):
    """
    Web page for member attendance via QR code
    Accessible to members without app installation
    """
    gym_id = request.GET.get('gym_id')
    gym_name = request.GET.get('gym_name', 'Gym')
    
    # Decode gym name if URL encoded
    import urllib.parse
    gym_name = urllib.parse.unquote(gym_name)
    
    html_content = f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>{gym_name} - Attendance</title>
        <style>
            * {{
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }}
            body {{
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
                display: flex;
                align-items: center;
                justify-content: center;
                padding: 20px;
            }}
            .container {{
                background: white;
                border-radius: 20px;
                padding: 40px 30px;
                max-width: 400px;
                width: 100%;
                box-shadow: 0 20px 40px rgba(0,0,0,0.1);
                text-align: center;
            }}
            .gym-icon {{
                width: 80px;
                height: 80px;
                background: linear-gradient(135deg, #667eea, #764ba2);
                border-radius: 50%;
                margin: 0 auto 20px;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 30px;
                color: white;
            }}
            h1 {{
                color: #333;
                margin-bottom: 10px;
                font-size: 24px;
            }}
            .gym-name {{
                color: #666;
                margin-bottom: 30px;
                font-size: 16px;
            }}
            .input-group {{
                margin-bottom: 20px;
                text-align: left;
            }}
            label {{
                display: block;
                margin-bottom: 8px;
                color: #555;
                font-weight: 500;
            }}
            input {{
                width: 100%;
                padding: 15px;
                border: 2px solid #e1e5e9;
                border-radius: 10px;
                font-size: 16px;
                transition: border-color 0.3s;
            }}
            input:focus {{
                outline: none;
                border-color: #667eea;
            }}
            .btn {{
                width: 100%;
                padding: 15px;
                background: linear-gradient(135deg, #667eea, #764ba2);
                color: white;
                border: none;
                border-radius: 10px;
                font-size: 16px;
                font-weight: 600;
                cursor: pointer;
                transition: transform 0.2s;
            }}
            .btn:hover {{
                transform: translateY(-2px);
            }}
            .btn:disabled {{
                opacity: 0.7;
                cursor: not-allowed;
                transform: none;
            }}
            .message {{
                margin-top: 20px;
                padding: 15px;
                border-radius: 10px;
                font-weight: 500;
            }}
            .success {{
                background: #d4edda;
                color: #155724;
                border: 1px solid #c3e6cb;
            }}
            .error {{
                background: #f8d7da;
                color: #721c24;
                border: 1px solid #f5c6cb;
            }}
            .loading {{
                background: #d1ecf1;
                color: #0c5460;
                border: 1px solid #bee5eb;
            }}
            .info {{
                background: #f8f9fa;
                color: #6c757d;
                padding: 15px;
                border-radius: 10px;
                margin-top: 20px;
                font-size: 14px;
                text-align: left;
            }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="gym-icon">🏋️</div>
            <h1>Mark Attendance</h1>
            <div class="gym-name">{gym_name}</div>
            
            <form id="attendanceForm">
                <div class="input-group">
                    <label for="memberId">Member ID</label>
                    <input type="text" id="memberId" name="memberId" placeholder="Enter your member ID (e.g., MEM-0008)" required>
                </div>
                <button type="submit" class="btn" id="submitBtn">Log Attendance</button>
            </form>
            
            <div id="message"></div>
            
            <div class="info">
                <strong>Instructions:</strong><br>
                • Enter your unique Member ID (format: MEM-XXXX)<br>
                • Tap "Log Attendance" to check in<br>
                • Your attendance will be recorded instantly<br>
                • Contact gym staff if you don't know your Member ID
            </div>
        </div>

        <script>
            const form = document.getElementById('attendanceForm');
            const submitBtn = document.getElementById('submitBtn');
            const messageDiv = document.getElementById('message');
            
            form.addEventListener('submit', async (e) => {{
                e.preventDefault();
                
                const memberId = document.getElementById('memberId').value;
                
                if (!memberId) {{
                    showMessage('Please enter your Member ID', 'error');
                    return;
                }}
                
                // Show loading state
                submitBtn.disabled = true;
                submitBtn.textContent = 'Logging Attendance...';
                showMessage('Processing your attendance...', 'loading');
                
                try {{
                    const response = await fetch('/attendance/submit/', {{
                        method: 'POST',
                        headers: {{
                            'Content-Type': 'application/json',
                        }},
                        body: JSON.stringify({{
                            member_id: memberId,
                            gym_id: '{gym_id}'
                        }})
                    }});
                    
                    const data = await response.json();
                    
                    if (data.success) {{
                        showMessage('✅ Attendance logged successfully! Welcome to {gym_name}', 'success');
                        form.reset();
                        
                        // Auto-close after 3 seconds
                        setTimeout(() => {{
                            showMessage('You can now close this page', 'success');
                        }}, 3000);
                    }} else {{
                        showMessage('❌ ' + (data.message || 'Failed to log attendance'), 'error');
                    }}
                }} catch (error) {{
                    showMessage('❌ Network error. Please try again.', 'error');
                }} finally {{
                    submitBtn.disabled = false;
                    submitBtn.textContent = 'Log Attendance';
                }}
            }});
            
            function showMessage(text, type) {{
                messageDiv.innerHTML = `<div class="message ${{type}}">${{text}}</div>`;
            }}
        </script>
    </body>
    </html>
    """
    
    return HttpResponse(html_content, content_type='text/html')


@csrf_exempt
@require_http_methods(["POST"])
def web_attendance_submit(request):
    """
    Handle attendance submission from web page
    """
    try:
        # Parse request data
        data = json.loads(request.body)
        member_id = data.get('member_id')
        gym_id = data.get('gym_id')
        
        # Validate input
        if not member_id or not gym_id:
            return JsonResponse({
                'success': False,
                'message': 'Member ID and Gym ID are required'
            })
        
        # Find the gym owner
        try:
            gym_owner = GymOwner.objects.get(id=gym_id)
        except GymOwner.DoesNotExist:
            return JsonResponse({
                'success': False,
                'message': 'Invalid gym code'
            })
        
        # Find the member
        try:
            member = Member.objects.get(
                member_id=member_id,
                gym_owner=gym_owner,
                is_active=True
            )
        except Member.DoesNotExist:
            return JsonResponse({
                'success': False,
                'message': f'Member ID {member_id} not found or inactive'
            })
        
        # Get current date in IST
        today = get_ist_date()
        
        # Check if already checked in today
        existing_attendance = Attendance.objects.filter(
            member=member,
            date=today
        ).first()
        
        if existing_attendance:
            return JsonResponse({
                'success': True,
                'message': f'Welcome back {member.user.first_name}! You are already checked in today.'
            })
        
        # Create new attendance record
        attendance = Attendance.objects.create(
            member=member,
            gym_owner=gym_owner,
            date=today,
            check_in_time=get_ist_now(),
            qr_code_used=True,
            notes='QR Code Check-in via Web'
        )
        
        return JsonResponse({
            'success': True,
            'message': f'Welcome {member.user.first_name}! Attendance logged successfully.',
            'attendance_id': str(attendance.attendance_id),
            'debug_info': {
                'gym_owner_id': gym_owner.id,
                'gym_name': gym_owner.gym_name,
                'member_id': member.member_id,
                'qr_code_used': True,
                'date': str(today)
            }
        })
        
    except json.JSONDecodeError as e:
        logger.error(f"JSON decode error: {e}")
        return JsonResponse({
            'success': False,
            'message': 'Invalid request format'
        })
    except Exception as e:
        import traceback
        logger.error(f"Web attendance error: {e}")
        logger.error(f"Traceback: {traceback.format_exc()}")
        return JsonResponse({
            'success': False,
            'message': f'Server error: {str(e)}'
        })
