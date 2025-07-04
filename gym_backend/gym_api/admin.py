from django.contrib import admin
from django.utils.html import format_html
from django.db.models import Count, Sum
from django.urls import reverse
from django.utils.safestring import mark_safe
from .models import (
    GymOwner, Member, Trainer, Equipment, WorkoutPlan, Exercise, 
    WorkoutSession, SubscriptionPlan, MemberSubscription, 
    MembershipPayment, Attendance
)


# Custom Admin Site Configuration
admin.site.site_header = "Gym Management System Admin"
admin.site.site_title = "Gym Management Admin"
admin.site.index_title = "Welcome to Gym Management System Administration"


@admin.register(GymOwner)
class GymOwnerAdmin(admin.ModelAdmin):
    list_display = ['gym_name', 'user_full_name', 'phone_number', 'subscription_plan', 'is_active', 'created_at']
    list_filter = ['subscription_plan', 'is_active', 'gym_established_date', 'created_at']
    search_fields = ['gym_name', 'user__first_name', 'user__last_name', 'user__email', 'phone_number']
    readonly_fields = ['qr_code_token', 'created_at', 'updated_at', 'total_stats']
    fieldsets = (
        ('Basic Information', {
            'fields': ('user', 'gym_name', 'gym_address', 'gym_description')
        }),
        ('Contact & Business Details', {
            'fields': ('phone_number', 'gym_established_date', 'subscription_plan', 'is_active')
        }),
        ('System Information', {
            'fields': ('qr_code_token', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
        ('Statistics', {
            'fields': ('total_stats',),
            'classes': ('collapse',)
        }),
    )
    
    def user_full_name(self, obj):
        return f"{obj.user.first_name} {obj.user.last_name}" or obj.user.username
    user_full_name.short_description = 'Owner Name'
    
    def total_stats(self, obj):
        members = obj.members.filter(is_active=True).count()
        trainers = obj.trainers.filter(is_available=True).count()
        equipment = obj.equipment.filter(is_working=True).count()
        return format_html(
            '<strong>Active Members:</strong> {}<br>'
            '<strong>Available Trainers:</strong> {}<br>'
            '<strong>Working Equipment:</strong> {}',
            members, trainers, equipment
        )
    total_stats.short_description = 'Gym Statistics'


@admin.register(Member)
class MemberAdmin(admin.ModelAdmin):
    list_display = ['member_id', 'full_name', 'gym_owner', 'membership_type', 'is_active', 'membership_expiry', 'days_until_expiry']
    list_filter = ['gym_owner', 'membership_type', 'is_active', 'gender', 'join_date']
    search_fields = ['member_id', 'user__first_name', 'user__last_name', 'user__email', 'phone']
    readonly_fields = ['member_id', 'join_date', 'created_at', 'updated_at', 'days_until_expiry']
    date_hierarchy = 'join_date'
    fieldsets = (
        ('Basic Information', {
            'fields': ('user', 'gym_owner', 'member_id')
        }),
        ('Personal Details', {
            'fields': ('phone', 'date_of_birth', 'gender', 'address', 'profile_picture')
        }),
        ('Membership Information', {
            'fields': ('membership_type', 'membership_expiry', 'is_active', 'notes')
        }),
        ('Emergency Contact', {
            'fields': ('emergency_contact_name', 'emergency_contact_phone', 'emergency_contact_relation')
        }),
        ('System Information', {
            'fields': ('join_date', 'days_until_expiry', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def full_name(self, obj):
        return f"{obj.user.first_name} {obj.user.last_name}" or obj.user.username
    full_name.short_description = 'Full Name'
    
    def days_until_expiry(self, obj):
        days = obj.days_until_expiry if hasattr(obj, 'days_until_expiry') else 0
        if days <= 0:
            return format_html('<span style="color: red;">Expired</span>')
        elif days <= 7:
            return format_html('<span style="color: orange;">{} days</span>', days)
        else:
            return format_html('<span style="color: green;">{} days</span>', days)
    days_until_expiry.short_description = 'Days Until Expiry'


@admin.register(Trainer)
class TrainerAdmin(admin.ModelAdmin):
    list_display = ['trainer_id', 'full_name', 'gym_owner', 'specialization', 'experience_years', 'hourly_rate', 'is_available']
    list_filter = ['gym_owner', 'specialization', 'is_available', 'experience_years']
    search_fields = ['trainer_id', 'user__first_name', 'user__last_name', 'user__email', 'phone', 'certification']
    readonly_fields = ['trainer_id', 'joining_date', 'created_at', 'updated_at', 'total_sessions']
    fieldsets = (
        ('Basic Information', {
            'fields': ('user', 'gym_owner', 'trainer_id')
        }),
        ('Contact Details', {
            'fields': ('phone', 'profile_picture')
        }),
        ('Professional Information', {
            'fields': ('specialization', 'experience_years', 'certification', 'bio')
        }),
        ('Compensation & Availability', {
            'fields': ('hourly_rate', 'monthly_salary', 'is_available', 'schedule_notes')
        }),
        ('System Information', {
            'fields': ('joining_date', 'total_sessions', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def full_name(self, obj):
        return f"{obj.user.first_name} {obj.user.last_name}" or obj.user.username
    full_name.short_description = 'Full Name'
    
    def total_sessions(self, obj):
        return obj.workoutsession_set.filter(completed=True).count()
    total_sessions.short_description = 'Completed Sessions'


@admin.register(Equipment)
class EquipmentAdmin(admin.ModelAdmin):
    list_display = ['equipment_id', 'name', 'gym_owner', 'equipment_type', 'brand', 'condition', 'is_working', 'warranty_status']
    list_filter = ['gym_owner', 'equipment_type', 'brand', 'condition', 'is_working']
    search_fields = ['equipment_id', 'name', 'brand', 'model', 'serial_number']
    readonly_fields = ['equipment_id', 'created_at', 'updated_at', 'warranty_status']
    date_hierarchy = 'purchase_date'
    fieldsets = (
        ('Basic Information', {
            'fields': ('gym_owner', 'equipment_id', 'name', 'equipment_type')
        }),
        ('Equipment Details', {
            'fields': ('brand', 'model', 'serial_number', 'quantity', 'location_in_gym')
        }),
        ('Purchase Information', {
            'fields': ('purchase_date', 'purchase_price', 'warranty_expiry')
        }),
        ('Status & Maintenance', {
            'fields': ('is_working', 'condition', 'last_maintenance_date', 'next_maintenance_date', 'maintenance_notes')
        }),
        ('System Information', {
            'fields': ('warranty_status', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def warranty_status(self, obj):
        from datetime import date
        if obj.warranty_expiry:
            days_left = (obj.warranty_expiry - date.today()).days
            if days_left < 0:
                return format_html('<span style="color: red;">Expired</span>')
            elif days_left < 30:
                return format_html('<span style="color: orange;">Expiring Soon ({} days)</span>', days_left)
            else:
                return format_html('<span style="color: green;">Active ({} days)</span>', days_left)
        return 'Unknown'
    warranty_status.short_description = 'Warranty Status'


@admin.register(SubscriptionPlan)
class SubscriptionPlanAdmin(admin.ModelAdmin):
    list_display = ['plan_id', 'name', 'gym_owner', 'price', 'duration_display', 'active_subscribers', 'is_active']
    list_filter = ['gym_owner', 'duration_type', 'is_active', 'includes_trainer', 'includes_nutrition']
    search_fields = ['plan_id', 'name', 'description']
    readonly_fields = ['plan_id', 'created_date', 'updated_date', 'active_subscribers', 'duration_in_months']
    fieldsets = (
        ('Basic Information', {
            'fields': ('gym_owner', 'plan_id', 'name', 'description')
        }),
        ('Pricing & Duration', {
            'fields': ('price', 'duration_value', 'duration_type', 'discount_percentage')
        }),
        ('Plan Features', {
            'fields': ('features', 'max_members', 'includes_trainer', 'includes_nutrition')
        }),
        ('Status & Analytics', {
            'fields': ('is_active', 'active_subscribers', 'duration_in_months')
        }),
        ('System Information', {
            'fields': ('created_date', 'updated_date'),
            'classes': ('collapse',)
        }),
    )
    
    def duration_display(self, obj):
        return f"{obj.duration_value} {obj.get_duration_type_display()}"
    duration_display.short_description = 'Duration'
    
    def active_subscribers(self, obj):
        return obj.membersubscription_set.filter(status='active').count()
    active_subscribers.short_description = 'Active Subscribers'


@admin.register(MemberSubscription)
class MemberSubscriptionAdmin(admin.ModelAdmin):
    list_display = ['member', 'subscription_plan', 'gym_owner', 'status', 'start_date', 'end_date', 'days_remaining', 'amount_paid']
    list_filter = ['gym_owner', 'status', 'auto_renew', 'payment_method']
    search_fields = ['member__user__first_name', 'member__user__last_name', 'member__member_id']
    readonly_fields = ['created_date', 'updated_date', 'is_active', 'is_expired', 'is_expiring_soon', 'days_remaining']
    date_hierarchy = 'start_date'
    fieldsets = (
        ('Subscription Details', {
            'fields': ('gym_owner', 'member', 'subscription_plan')
        }),
        ('Duration & Status', {
            'fields': ('start_date', 'end_date', 'status', 'auto_renew')
        }),
        ('Payment Information', {
            'fields': ('amount_paid', 'payment_method', 'notes')
        }),
        ('Status Indicators', {
            'fields': ('is_active', 'is_expired', 'is_expiring_soon', 'days_remaining'),
            'classes': ('collapse',)
        }),
        ('System Information', {
            'fields': ('created_date', 'updated_date'),
            'classes': ('collapse',)
        }),
    )
    
    def days_remaining(self, obj):
        days = obj.days_remaining
        if days <= 0:
            return format_html('<span style="color: red;">Expired</span>')
        elif days <= 7:
            return format_html('<span style="color: orange;">{} days</span>', days)
        else:
            return format_html('<span style="color: green;">{} days</span>', days)
    days_remaining.short_description = 'Days Remaining'


@admin.register(MembershipPayment)
class MembershipPaymentAdmin(admin.ModelAdmin):
    list_display = ['payment_id', 'member', 'gym_owner', 'amount', 'payment_method', 'status', 'payment_date']
    list_filter = ['gym_owner', 'payment_method', 'status', 'payment_date']
    search_fields = ['payment_id', 'member__user__first_name', 'member__user__last_name', 'transaction_id']
    readonly_fields = ['payment_id', 'created_at', 'updated_at']
    date_hierarchy = 'payment_date'
    fieldsets = (
        ('Payment Details', {
            'fields': ('gym_owner', 'member', 'payment_id', 'subscription_plan')
        }),
        ('Transaction Information', {
            'fields': ('amount', 'payment_date', 'payment_method', 'status', 'membership_months')
        }),
        ('Transaction Details', {
            'fields': ('transaction_id', 'receipt_number', 'discount_amount', 'tax_amount')
        }),
        ('Additional Information', {
            'fields': ('notes', 'member_subscription')
        }),
        ('System Information', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('member__user', 'gym_owner__user')


@admin.register(Attendance)
class AttendanceAdmin(admin.ModelAdmin):
    list_display = ['attendance_id', 'member', 'gym_owner', 'date', 'check_in_time', 'check_out_time', 'duration_display', 'qr_code_used']
    list_filter = ['gym_owner', 'date', 'qr_code_used']
    search_fields = ['attendance_id', 'member__user__first_name', 'member__user__last_name', 'member__member_id']
    readonly_fields = ['attendance_id', 'duration_hours', 'is_checked_out', 'created_at', 'updated_at']
    date_hierarchy = 'date'
    fieldsets = (
        ('Attendance Details', {
            'fields': ('gym_owner', 'member', 'attendance_id', 'date')
        }),
        ('Check-in/out Information', {
            'fields': ('check_in_time', 'check_out_time', 'qr_code_used')
        }),
        ('Session Details', {
            'fields': ('session_duration_minutes', 'duration_hours', 'notes')
        }),
        ('Status', {
            'fields': ('is_checked_out',)
        }),
        ('System Information', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def duration_display(self, obj):
        if obj.duration_hours:
            return f"{obj.duration_hours} hours"
        return "Not checked out"
    duration_display.short_description = 'Duration'


@admin.register(WorkoutPlan)
class WorkoutPlanAdmin(admin.ModelAdmin):
    list_display = ['name', 'gym_owner', 'created_by', 'difficulty_level', 'duration_weeks', 'is_active']
    list_filter = ['gym_owner', 'difficulty_level', 'is_active', 'created_by']
    search_fields = ['name', 'description', 'created_by__user__first_name', 'created_by__user__last_name']
    readonly_fields = ['created_date', 'updated_date']
    fieldsets = (
        ('Plan Information', {
            'fields': ('gym_owner', 'name', 'description', 'created_by')
        }),
        ('Plan Details', {
            'fields': ('difficulty_level', 'duration_weeks', 'is_active')
        }),
        ('System Information', {
            'fields': ('created_date', 'updated_date'),
            'classes': ('collapse',)
        }),
    )


@admin.register(Exercise)
class ExerciseAdmin(admin.ModelAdmin):
    list_display = ['name', 'gym_owner', 'muscle_group', 'difficulty_level', 'sets', 'reps', 'rest_time_seconds']
    list_filter = ['gym_owner', 'muscle_group', 'difficulty_level']
    search_fields = ['name', 'instructions']
    readonly_fields = ['created_date']
    filter_horizontal = ['equipment_needed']
    fieldsets = (
        ('Exercise Information', {
            'fields': ('gym_owner', 'name', 'muscle_group', 'difficulty_level')
        }),
        ('Exercise Details', {
            'fields': ('instructions', 'equipment_needed')
        }),
        ('Sets & Reps', {
            'fields': ('sets', 'reps', 'rest_time_seconds')
        }),
        ('System Information', {
            'fields': ('created_date',),
            'classes': ('collapse',)
        }),
    )


@admin.register(WorkoutSession)
class WorkoutSessionAdmin(admin.ModelAdmin):
    list_display = ['member', 'trainer', 'gym_owner', 'date', 'duration_minutes', 'completed']
    list_filter = ['gym_owner', 'completed', 'trainer']
    search_fields = ['member__user__first_name', 'member__user__last_name', 'trainer__user__first_name']
    readonly_fields = ['created_date']
    date_hierarchy = 'date'
    fieldsets = (
        ('Session Details', {
            'fields': ('gym_owner', 'member', 'trainer', 'workout_plan')
        }),
        ('Schedule & Duration', {
            'fields': ('date', 'duration_minutes', 'completed')
        }),
        ('Notes', {
            'fields': ('notes',)
        }),
        ('System Information', {
            'fields': ('created_date',),
            'classes': ('collapse',)
        }),
    )


# Custom admin actions
def make_active(modeladmin, request, queryset):
    updated = queryset.update(is_active=True)
    modeladmin.message_user(request, f'{updated} items marked as active.')
make_active.short_description = "Mark selected items as active"

def make_inactive(modeladmin, request, queryset):
    updated = queryset.update(is_active=False)
    modeladmin.message_user(request, f'{updated} items marked as inactive.')
make_inactive.short_description = "Mark selected items as inactive"

# Add actions to relevant admin classes
MemberAdmin.actions = [make_active, make_inactive]
TrainerAdmin.actions = [make_active, make_inactive]
EquipmentAdmin.actions = [make_active, make_inactive]
GymOwnerAdmin.actions = [make_active, make_inactive]