from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
from datetime import timedelta
import uuid
import pytz


def get_ist_now():
    """Get current time in Indian Standard Time"""
    ist = pytz.timezone('Asia/Kolkata')
    return timezone.now().astimezone(ist)


def get_ist_date():
    """Get current date in Indian Standard Time"""
    return get_ist_now().date()


class GymOwner(models.Model):
    """
    Model representing gym owners with multi-tenant isolation
    Each gym owner manages their own gym with isolated data
    """
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    gym_name = models.CharField(max_length=100)
    gym_address = models.TextField()
    gym_description = models.TextField(blank=True)
    phone_number = models.CharField(max_length=15)
    gym_established_date = models.DateField()
    subscription_plan = models.CharField(max_length=50, default='basic')  # basic, premium, enterprise
    is_active = models.BooleanField(default=True)
    qr_code_token = models.UUIDField(default=uuid.uuid4, unique=True)  # Unique QR token for gym
    profile_picture = models.ImageField(upload_to='gym_owner_profiles/', blank=True, null=True)
    # Add base64 profile picture for Railway deployment (ephemeral storage)
    profile_picture_base64 = models.TextField(blank=True, null=True, help_text="Base64 encoded profile picture for Railway deployment")
    profile_picture_content_type = models.CharField(max_length=50, blank=True, null=True, help_text="Content type of the base64 image")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.gym_name} - {self.user.get_full_name()}"
    
    def save(self, *args, **kwargs):
        if not self.gym_established_date:
            self.gym_established_date = timezone.now().date()
        super().save(*args, **kwargs)


class Member(models.Model):
    MEMBERSHIP_TYPES = [
        ('basic', 'Basic'),
        ('premium', 'Premium'),
        ('vip', 'VIP'),
    ]
    
    GENDER_CHOICES = [
        ('male', 'Male'),
        ('female', 'Female'),
        ('other', 'Other'),
    ]
    
    gym_owner = models.ForeignKey(GymOwner, on_delete=models.CASCADE, related_name='members')
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    phone = models.CharField(max_length=15)
    date_of_birth = models.DateField()
    gender = models.CharField(max_length=10, choices=GENDER_CHOICES, default='male')
    address = models.TextField()
    membership_type = models.CharField(max_length=10, choices=MEMBERSHIP_TYPES, default='basic')
    join_date = models.DateField(auto_now_add=True)
    membership_expiry = models.DateField()
    is_active = models.BooleanField(default=True)
    emergency_contact_name = models.CharField(max_length=100)
    emergency_contact_phone = models.CharField(max_length=15)
    emergency_contact_relation = models.CharField(max_length=50, default='Family')
    member_id = models.CharField(max_length=20, blank=True)  # Unique member ID
    profile_picture = models.ImageField(upload_to='member_profiles/', blank=True, null=True)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['gym_owner', 'member_id']
        indexes = [
            models.Index(fields=['gym_owner', 'is_active']),
            models.Index(fields=['gym_owner', 'membership_expiry']),
            models.Index(fields=['gym_owner', 'join_date']),
            models.Index(fields=['member_id']),
            models.Index(fields=['user']),
        ]
    
    def __str__(self):
        return f"{self.user.first_name} {self.user.last_name} - {self.gym_owner.gym_name}"
    
    def save(self, *args, **kwargs):
        if not self.member_id:
            # Generate unique member ID for this gym
            last_member = Member.objects.filter(gym_owner=self.gym_owner).order_by('-id').first()
            if last_member and last_member.member_id and last_member.member_id.startswith('MEM-'):
                try:
                    last_num = int(last_member.member_id.split('-')[-1])
                    self.member_id = f"MEM-{last_num + 1:04d}"
                except (ValueError, IndexError):
                    # Fallback if member_id format is unexpected
                    self.member_id = f"MEM-{Member.objects.filter(gym_owner=self.gym_owner).count() + 1:04d}"
            else:
                self.member_id = "MEM-0001"
            
            # Ensure uniqueness within this gym
            counter = 1
            base_member_id = self.member_id
            while Member.objects.filter(gym_owner=self.gym_owner, member_id=self.member_id).exists():
                self.member_id = f"MEM-{int(base_member_id.split('-')[-1]) + counter:04d}"
                counter += 1
        super().save(*args, **kwargs)


class Trainer(models.Model):
    SPECIALIZATIONS = [
        ('fitness', 'General Fitness'),
        ('yoga', 'Yoga'),
        ('cardio', 'Cardio'),
        ('strength', 'Strength Training'),
        ('crossfit', 'CrossFit'),
        ('pilates', 'Pilates'),
        ('martial_arts', 'Martial Arts'),
        ('dance', 'Dance'),
        ('swimming', 'Swimming'),
    ]
    
    gym_owner = models.ForeignKey(GymOwner, on_delete=models.CASCADE, related_name='trainers')
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    phone = models.CharField(max_length=15)
    specialization = models.CharField(max_length=20, choices=SPECIALIZATIONS)
    experience_years = models.IntegerField()
    certification = models.CharField(max_length=200)
    hourly_rate = models.DecimalField(max_digits=6, decimal_places=2)
    monthly_salary = models.DecimalField(max_digits=8, decimal_places=2, blank=True, null=True)
    is_available = models.BooleanField(default=True)
    joining_date = models.DateField(auto_now_add=True)
    trainer_id = models.CharField(max_length=20, blank=True)
    profile_picture = models.ImageField(upload_to='trainer_profiles/', blank=True, null=True)
    bio = models.TextField(blank=True)
    schedule_notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['gym_owner', 'trainer_id']
        indexes = [
            models.Index(fields=['gym_owner', 'is_available']),
            models.Index(fields=['gym_owner', 'specialization']),
            models.Index(fields=['trainer_id']),
            models.Index(fields=['user']),
        ]
    
    def __str__(self):
        return f"{self.user.first_name} {self.user.last_name} - {self.specialization} - {self.gym_owner.gym_name}"
    
    def save(self, *args, **kwargs):
        if not self.trainer_id:
            # Generate unique trainer ID for this gym
            last_trainer = Trainer.objects.filter(gym_owner=self.gym_owner).order_by('-id').first()
            if last_trainer and last_trainer.trainer_id and last_trainer.trainer_id.startswith('TRN-'):
                try:
                    last_num = int(last_trainer.trainer_id.split('-')[-1])
                    self.trainer_id = f"TRN-{last_num + 1:04d}"
                except (ValueError, IndexError):
                    # Fallback if trainer_id format is unexpected
                    self.trainer_id = f"TRN-{Trainer.objects.filter(gym_owner=self.gym_owner).count() + 1:04d}"
            else:
                self.trainer_id = "TRN-0001"
            
            # Ensure uniqueness within this gym
            counter = 1
            base_trainer_id = self.trainer_id
            while Trainer.objects.filter(gym_owner=self.gym_owner, trainer_id=self.trainer_id).exists():
                self.trainer_id = f"TRN-{int(base_trainer_id.split('-')[-1]) + counter:04d}"
                counter += 1
        super().save(*args, **kwargs)


class Equipment(models.Model):
    EQUIPMENT_TYPES = [
        ('cardio', 'Cardio'),
        ('strength', 'Strength'),
        ('free_weights', 'Free Weights'),
        ('functional', 'Functional Training'),
        ('recovery', 'Recovery'),
        ('flexibility', 'Flexibility'),
        ('accessories', 'Accessories'),
    ]
    
    CONDITION_CHOICES = [
        ('excellent', 'Excellent'),
        ('good', 'Good'),
        ('fair', 'Fair'),
        ('poor', 'Poor'),
        ('maintenance', 'Under Maintenance'),
    ]
    
    gym_owner = models.ForeignKey(GymOwner, on_delete=models.CASCADE, related_name='equipment')
    name = models.CharField(max_length=100)
    equipment_type = models.CharField(max_length=20, choices=EQUIPMENT_TYPES)
    brand = models.CharField(max_length=50)
    model = models.CharField(max_length=50, blank=True)
    purchase_date = models.DateField()
    purchase_price = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    warranty_expiry = models.DateField()
    is_working = models.BooleanField(default=True)
    condition = models.CharField(max_length=15, choices=CONDITION_CHOICES, default='excellent')
    last_maintenance_date = models.DateField(blank=True, null=True)
    next_maintenance_date = models.DateField(blank=True, null=True)
    maintenance_notes = models.TextField(blank=True)
    equipment_id = models.CharField(max_length=20, blank=True)
    quantity = models.PositiveIntegerField(default=1)
    serial_number = models.CharField(max_length=100, blank=True)
    location_in_gym = models.CharField(max_length=100, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['gym_owner', 'equipment_id']
        indexes = [
            models.Index(fields=['gym_owner', 'is_working']),
            models.Index(fields=['gym_owner', 'equipment_type']),
            models.Index(fields=['gym_owner', 'next_maintenance_date']),
            models.Index(fields=['equipment_id']),
        ]
    
    def __str__(self):
        return f"{self.name} - {self.brand} - {self.gym_owner.gym_name}"
    
    def save(self, *args, **kwargs):
        if not self.equipment_id:
            # Generate unique equipment ID for this gym
            last_equipment = Equipment.objects.filter(gym_owner=self.gym_owner).order_by('-id').first()
            if last_equipment and last_equipment.equipment_id and last_equipment.equipment_id.startswith('EQP-'):
                try:
                    last_num = int(last_equipment.equipment_id.split('-')[-1])
                    self.equipment_id = f"EQP-{last_num + 1:04d}"
                except (ValueError, IndexError):
                    # Fallback if equipment_id format is unexpected
                    self.equipment_id = f"EQP-{Equipment.objects.filter(gym_owner=self.gym_owner).count() + 1:04d}"
            else:
                self.equipment_id = "EQP-0001"
            
            # Ensure uniqueness within this gym
            counter = 1
            base_equipment_id = self.equipment_id
            while Equipment.objects.filter(gym_owner=self.gym_owner, equipment_id=self.equipment_id).exists():
                self.equipment_id = f"EQP-{int(base_equipment_id.split('-')[-1]) + counter:04d}"
                counter += 1
        super().save(*args, **kwargs)


class WorkoutPlan(models.Model):
    DIFFICULTY_LEVELS = [
        ('beginner', 'Beginner'),
        ('intermediate', 'Intermediate'),
        ('advanced', 'Advanced'),
    ]
    
    gym_owner = models.ForeignKey(GymOwner, on_delete=models.CASCADE, related_name='workout_plans')
    name = models.CharField(max_length=100)
    description = models.TextField()
    difficulty_level = models.CharField(max_length=15, choices=DIFFICULTY_LEVELS)
    duration_weeks = models.IntegerField()
    created_by = models.ForeignKey(Trainer, on_delete=models.CASCADE)
    created_date = models.DateTimeField(auto_now_add=True)
    updated_date = models.DateTimeField(auto_now=True)
    is_active = models.BooleanField(default=True)
    
    def __str__(self):
        return f"{self.name} - {self.difficulty_level} - {self.gym_owner.gym_name}"


class Exercise(models.Model):
    MUSCLE_GROUPS = [
        ('chest', 'Chest'),
        ('back', 'Back'),
        ('shoulders', 'Shoulders'),
        ('arms', 'Arms'),
        ('core', 'Core'),
        ('legs', 'Legs'),
        ('cardio', 'Cardio'),
        ('full_body', 'Full Body'),
    ]
    
    gym_owner = models.ForeignKey(GymOwner, on_delete=models.CASCADE, related_name='exercises')
    name = models.CharField(max_length=100)
    muscle_group = models.CharField(max_length=20, choices=MUSCLE_GROUPS)
    instructions = models.TextField()
    equipment_needed = models.ManyToManyField(Equipment, blank=True)
    sets = models.IntegerField(default=1)
    reps = models.CharField(max_length=20, default='10-12')  # Can be "10-12" or "30 seconds"
    rest_time_seconds = models.IntegerField(default=60)
    difficulty_level = models.CharField(max_length=15, choices=WorkoutPlan.DIFFICULTY_LEVELS, default='beginner')
    created_date = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"{self.name} - {self.muscle_group} - {self.gym_owner.gym_name}"


class WorkoutSession(models.Model):
    gym_owner = models.ForeignKey(GymOwner, on_delete=models.CASCADE, related_name='workout_sessions')
    member = models.ForeignKey(Member, on_delete=models.CASCADE)
    trainer = models.ForeignKey(Trainer, on_delete=models.SET_NULL, null=True, blank=True)
    workout_plan = models.ForeignKey(WorkoutPlan, on_delete=models.SET_NULL, null=True, blank=True)
    date = models.DateTimeField()
    duration_minutes = models.IntegerField()
    notes = models.TextField(blank=True)
    completed = models.BooleanField(default=False)
    created_date = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"{self.member} - {self.date.strftime('%Y-%m-%d')} - {self.gym_owner.gym_name}"


class SubscriptionPlan(models.Model):
    DURATION_TYPES = [
        ('days', 'Days'),
        ('weeks', 'Weeks'),
        ('months', 'Months'),
        ('years', 'Years'),
    ]
    
    gym_owner = models.ForeignKey(GymOwner, on_delete=models.CASCADE, related_name='subscription_plans')
    name = models.CharField(max_length=100)
    description = models.TextField()
    price = models.DecimalField(max_digits=8, decimal_places=2)
    duration_value = models.IntegerField()
    duration_type = models.CharField(max_length=10, choices=DURATION_TYPES, default='months')
    features = models.JSONField(default=list)  # List of features as JSON
    discount_percentage = models.DecimalField(max_digits=5, decimal_places=2, default=0.00)
    is_active = models.BooleanField(default=True)
    plan_id = models.CharField(max_length=20, blank=True)
    max_members = models.IntegerField(blank=True, null=True)  # Maximum members for this plan
    includes_trainer = models.BooleanField(default=False)
    includes_nutrition = models.BooleanField(default=False)
    created_date = models.DateTimeField(auto_now_add=True)
    updated_date = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['gym_owner', 'plan_id']
        indexes = [
            models.Index(fields=['gym_owner', 'is_active']),
            models.Index(fields=['gym_owner', 'price']),
            models.Index(fields=['plan_id']),
        ]
    
    def __str__(self):
        return f"{self.name} - ₹{self.price} - {self.gym_owner.gym_name}"
    
    @property
    def duration_in_months(self):
        """Convert duration to months for easy calculation"""
        if self.duration_type == 'days':
            return self.duration_value / 30
        elif self.duration_type == 'weeks':
            return self.duration_value / 4
        elif self.duration_type == 'months':
            return self.duration_value
        elif self.duration_type == 'years':
            return self.duration_value * 12
        return self.duration_value
    
    def save(self, *args, **kwargs):
        if not self.plan_id:
            # Generate unique plan ID for this gym
            last_plan = SubscriptionPlan.objects.filter(gym_owner=self.gym_owner).order_by('-id').first()
            if last_plan and last_plan.plan_id and last_plan.plan_id.startswith('PLN-'):
                try:
                    last_num = int(last_plan.plan_id.split('-')[-1])
                    self.plan_id = f"PLN-{last_num + 1:04d}"
                except (ValueError, IndexError):
                    # Fallback if plan_id format is unexpected
                    self.plan_id = f"PLN-{SubscriptionPlan.objects.filter(gym_owner=self.gym_owner).count() + 1:04d}"
            else:
                self.plan_id = "PLN-0001"
            
            # Ensure uniqueness within this gym
            counter = 1
            base_plan_id = self.plan_id
            while SubscriptionPlan.objects.filter(gym_owner=self.gym_owner, plan_id=self.plan_id).exists():
                self.plan_id = f"PLN-{int(base_plan_id.split('-')[-1]) + counter:04d}"
                counter += 1
        super().save(*args, **kwargs)


class MemberSubscription(models.Model):
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('expired', 'Expired'),
        ('cancelled', 'Cancelled'),
        ('suspended', 'Suspended'),
        ('pending', 'Pending'),
    ]
    
    gym_owner = models.ForeignKey(GymOwner, on_delete=models.CASCADE, related_name='member_subscriptions')
    member = models.ForeignKey(Member, on_delete=models.CASCADE)
    subscription_plan = models.ForeignKey(SubscriptionPlan, on_delete=models.CASCADE)
    start_date = models.DateField()
    end_date = models.DateField()
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='active')
    auto_renew = models.BooleanField(default=False)
    amount_paid = models.DecimalField(max_digits=8, decimal_places=2)
    payment_method = models.CharField(max_length=15, blank=True)
    notes = models.TextField(blank=True)
    created_date = models.DateTimeField(auto_now_add=True)
    updated_date = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.member} - {self.subscription_plan.name} - {self.gym_owner.gym_name}"
    
    @property
    def is_active(self):
        return self.status == 'active' and self.end_date >= timezone.now().date()
    
    @property
    def is_expired(self):
        return self.end_date < timezone.now().date()
    
    @property
    def is_expiring_soon(self):
        return self.end_date <= (timezone.now().date() + timedelta(days=7))
    
    @property
    def days_remaining(self):
        if self.end_date >= timezone.now().date():
            return (self.end_date - timezone.now().date()).days
        return 0


class MembershipPayment(models.Model):
    PAYMENT_METHODS = [
        ('cash', 'Cash'),
        ('card', 'Credit/Debit Card'),
        ('upi', 'UPI'),
        ('bank_transfer', 'Bank Transfer'),
        ('online', 'Online Payment'),
        ('cheque', 'Cheque'),
    ]
    
    PAYMENT_STATUS = [
        ('completed', 'Completed'),
        ('pending', 'Pending'),
        ('failed', 'Failed'),
        ('refunded', 'Refunded'),
    ]
    
    gym_owner = models.ForeignKey(GymOwner, on_delete=models.CASCADE, related_name='payments')
    member = models.ForeignKey(Member, on_delete=models.CASCADE)
    subscription_plan = models.ForeignKey(SubscriptionPlan, on_delete=models.CASCADE, null=True, blank=True)
    member_subscription = models.ForeignKey(MemberSubscription, on_delete=models.SET_NULL, null=True, blank=True)
    amount = models.DecimalField(max_digits=8, decimal_places=2)
    payment_date = models.DateTimeField()
    payment_method = models.CharField(max_length=15, choices=PAYMENT_METHODS)
    status = models.CharField(max_length=10, choices=PAYMENT_STATUS, default='completed')
    membership_months = models.IntegerField()
    transaction_id = models.CharField(max_length=100, null=True, blank=True)
    payment_id = models.CharField(max_length=20, blank=True)
    notes = models.TextField(null=True, blank=True)
    discount_amount = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    tax_amount = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    receipt_number = models.CharField(max_length=50, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['gym_owner', 'payment_id']
        indexes = [
            models.Index(fields=['gym_owner', 'payment_date']),
            models.Index(fields=['gym_owner', 'status']),
            models.Index(fields=['gym_owner', 'member']),
            models.Index(fields=['payment_id']),
            models.Index(fields=['member', 'payment_date']),
        ]
    
    def __str__(self):
        return f"{self.member} - ₹{self.amount} - {self.payment_date.strftime('%Y-%m-%d')} - {self.gym_owner.gym_name}"
    
    def save(self, *args, **kwargs):
        if not self.payment_id:
            # Generate unique payment ID for this gym
            last_payment = MembershipPayment.objects.filter(gym_owner=self.gym_owner).order_by('-id').first()
            if last_payment and last_payment.payment_id and last_payment.payment_id.startswith('PAY-'):
                try:
                    last_num = int(last_payment.payment_id.split('-')[-1])
                    self.payment_id = f"PAY-{last_num + 1:04d}"
                except (ValueError, IndexError):
                    # Fallback if payment_id format is unexpected
                    self.payment_id = f"PAY-{MembershipPayment.objects.filter(gym_owner=self.gym_owner).count() + 1:04d}"
            else:
                self.payment_id = "PAY-0001"
            
            # Ensure uniqueness within this gym
            counter = 1
            base_payment_id = self.payment_id
            while MembershipPayment.objects.filter(gym_owner=self.gym_owner, payment_id=self.payment_id).exists():
                self.payment_id = f"PAY-{int(base_payment_id.split('-')[-1]) + counter:04d}"
                counter += 1
        super().save(*args, **kwargs)
        
        # Invalidate revenue analytics cache when payment is created/updated
        from django.core.cache import cache
        cache_key = f'revenue_analytics_{self.gym_owner.id}'
        cache.delete(cache_key)
        print(f'💰 CACHE: Invalidated revenue analytics cache for gym owner {self.gym_owner.id}')
    
    def delete(self, *args, **kwargs):
        # Store gym_owner before deletion
        gym_owner_id = self.gym_owner.id
        super().delete(*args, **kwargs)
        
        # Invalidate revenue analytics cache when payment is deleted
        from django.core.cache import cache
        cache_key = f'revenue_analytics_{gym_owner_id}'
        cache.delete(cache_key)
        print(f'💰 CACHE: Invalidated revenue analytics cache for gym owner {gym_owner_id} (payment deleted)')


class Attendance(models.Model):
    gym_owner = models.ForeignKey(GymOwner, on_delete=models.CASCADE, related_name='attendances')
    member = models.ForeignKey(Member, on_delete=models.CASCADE)
    check_in_time = models.DateTimeField()
    check_out_time = models.DateTimeField(null=True, blank=True)
    date = models.DateField()
    attendance_id = models.CharField(max_length=20, unique=True, blank=True)
    session_duration_minutes = models.IntegerField(null=True, blank=True)
    notes = models.TextField(blank=True)
    qr_code_used = models.BooleanField(default=False)  # Track if QR code was used for check-in
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['gym_owner', 'member', 'date']
        indexes = [
            models.Index(fields=['gym_owner', 'date']),
            models.Index(fields=['gym_owner', 'check_in_time']),
            models.Index(fields=['member', 'date']),
            models.Index(fields=['date', 'check_in_time']),
            models.Index(fields=['attendance_id']),
        ]
    
    def __str__(self):
        return f"{self.member} - {self.date} - {self.gym_owner.gym_name}"
    
    @property
    def duration_hours(self):
        """Calculate session duration in hours"""
        if self.check_out_time and self.check_in_time:
            delta = self.check_out_time - self.check_in_time
            return round(delta.total_seconds() / 3600, 2)
        return None
    
    @property
    def is_checked_out(self):
        """Check if member has checked out"""
        return self.check_out_time is not None
    
    def save(self, *args, **kwargs):
        if not self.attendance_id:
            # Generate unique attendance ID for this gym
            last_attendance = Attendance.objects.filter(gym_owner=self.gym_owner).order_by('-id').first()
            if last_attendance and last_attendance.attendance_id and last_attendance.attendance_id.startswith('ATT-'):
                try:
                    last_num = int(last_attendance.attendance_id.split('-')[-1])
                    self.attendance_id = f"ATT-{last_num + 1:04d}"
                except (ValueError, IndexError):
                    # Fallback if attendance_id format is unexpected
                    self.attendance_id = f"ATT-{Attendance.objects.filter(gym_owner=self.gym_owner).count() + 1:04d}"
            else:
                self.attendance_id = "ATT-0001"
            
            # Ensure uniqueness globally (since attendance_id is unique=True, not unique_together)
            counter = 1
            base_attendance_id = self.attendance_id
            while Attendance.objects.filter(attendance_id=self.attendance_id).exists():
                self.attendance_id = f"ATT-{int(base_attendance_id.split('-')[-1]) + counter:04d}"
                counter += 1
        
        # Calculate session duration on check-out
        if self.check_out_time and self.check_in_time:
            delta = self.check_out_time - self.check_in_time
            self.session_duration_minutes = int(delta.total_seconds() / 60)
        
        super().save(*args, **kwargs)


class TrainerMemberAssociation(models.Model):
    """
    Model for managing trainer-member associations
    Allows tracking which members are assigned to which trainers
    """
    gym_owner = models.ForeignKey(GymOwner, on_delete=models.CASCADE, related_name='trainer_member_associations')
    trainer = models.ForeignKey(Trainer, on_delete=models.CASCADE, related_name='member_associations')
    member = models.ForeignKey(Member, on_delete=models.CASCADE, related_name='trainer_associations')
    assigned_date = models.DateTimeField(auto_now_add=True)
    assigned_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    is_active = models.BooleanField(default=True)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['gym_owner', 'trainer', 'member']
        indexes = [
            models.Index(fields=['gym_owner', 'trainer', 'is_active']),
            models.Index(fields=['gym_owner', 'member', 'is_active']),
            models.Index(fields=['assigned_date']),
        ]
    
    def __str__(self):
        return f"{self.trainer.user.get_full_name()} -> {self.member.user.get_full_name()} ({self.gym_owner.gym_name})"
    
    @property
    def is_current(self):
        """Check if this association is currently active"""
        return self.is_active
    
    def deactivate(self):
        """Deactivate this association"""
        self.is_active = False
        self.save()
    
    def activate(self):
        """Activate this association"""
        self.is_active = True
        self.save()
