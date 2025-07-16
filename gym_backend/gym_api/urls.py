from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    GymOwnerViewSet, MemberViewSet, TrainerViewSet, EquipmentViewSet,
    WorkoutPlanViewSet, ExerciseViewSet, WorkoutSessionViewSet,
    MembershipPaymentViewSet, AttendanceViewSet, SubscriptionPlanViewSet, MemberSubscriptionViewSet,
    TrainerMemberAssociationViewSet, NotificationViewSet
)
from . import auth_views

router = DefaultRouter()
router.register(r'gym-owners', GymOwnerViewSet, basename='gymowner')
router.register(r'members', MemberViewSet, basename='member')
router.register(r'trainers', TrainerViewSet, basename='trainer')
router.register(r'equipment', EquipmentViewSet, basename='equipment')
router.register(r'workout-plans', WorkoutPlanViewSet, basename='workoutplan')
router.register(r'exercises', ExerciseViewSet, basename='exercise')
router.register(r'workout-sessions', WorkoutSessionViewSet, basename='workoutsession')
router.register(r'payments', MembershipPaymentViewSet, basename='membershippayment')
router.register(r'attendance', AttendanceViewSet, basename='attendance')
router.register(r'subscription-plans', SubscriptionPlanViewSet, basename='subscriptionplan')
router.register(r'member-subscriptions', MemberSubscriptionViewSet, basename='membersubscription')
router.register(r'trainer-member-associations', TrainerMemberAssociationViewSet, basename='trainermemberassociation')
router.register(r'notifications', NotificationViewSet, basename='notification')

urlpatterns = [
    path('', include(router.urls)),
    
    # Authentication endpoints
    path('auth/register/', auth_views.gym_owner_register, name='gym-owner-register'),
    path('auth/login/', auth_views.gym_owner_login, name='gym-owner-login'),
    path('auth/google/', auth_views.google_auth, name='google-auth'),
    path('auth/google/config/', auth_views.google_config_check, name='google-config-check'),
    path('auth/logout/', auth_views.gym_owner_logout, name='gym-owner-logout'),
    path('auth/profile/', auth_views.gym_owner_profile, name='gym-owner-profile'),
    path('auth/profile/update/', auth_views.gym_owner_update_profile, name='gym-owner-update-profile'),
    path('auth/profile/upload-picture/', auth_views.gym_owner_upload_picture, name='gym-owner-upload-picture'),
    path('auth/profile/change-password/', auth_views.gym_owner_change_password, name='gym-owner-change-password'),
    
    # QR Code endpoints
    path('qr/regenerate/', auth_views.regenerate_qr_token, name='regenerate-qr-token'),
    path('qr/verify/', auth_views.verify_qr_token, name='verify-qr-token'),
    path('attendance/qr-checkin/<uuid:qr_token>/', 
         AttendanceViewSet.as_view({'post': 'qr_checkin'}), 
         name='qr-checkin'),
]