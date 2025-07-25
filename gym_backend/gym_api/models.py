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
    
    # Physical attributes
    height_cm = models.FloatField(null=True, blank=True, help_text="Height in centimeters")
    weight_kg = models.FloatField(null=True, blank=True, help_text="Weight in kilograms")
    
    # Profile picture with Railway-compatible base64 storage
    profile_picture = models.ImageField(upload_to='member_profiles/', blank=True, null=True)
    profile_picture_base64 = models.TextField(blank=True, null=True, help_text="Base64 encoded profile picture for Railway deployment")
    profile_picture_content_type = models.CharField(max_length=50, blank=True, null=True, help_text="Content type of the base64 image")
    
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
    
    @property
    def bmi(self):
        """Calculate BMI if height and weight are available"""
        if self.height_cm and self.weight_kg and self.height_cm > 0:
            height_m = self.height_cm / 100  # Convert to meters
            return round(self.weight_kg / (height_m ** 2), 1)
        return None
    
    @property
    def bmi_category(self):
        """Get BMI category based on WHO standards"""
        bmi = self.bmi
        if bmi is None:
            return None
        elif bmi < 18.5:
            return "Underweight"
        elif bmi < 25:
            return "Normal weight"
        elif bmi < 30:
            return "Overweight"
        else:
            return "Obese"
    
    @property
    def profile_picture_url(self):
        """Get the full URL for the profile picture - prefer base64 data URL for Railway"""
        # First try base64 data URL (works reliably on Railway)
        if self.profile_picture_base64 and self.profile_picture_content_type:
            data_url = f"data:{self.profile_picture_content_type};base64,{self.profile_picture_base64}"
            return data_url
        
        # Fallback to traditional file URL
        if self.profile_picture and self.profile_picture.name:
            # Note: This might not work on Railway due to ephemeral storage
            return self.profile_picture.url
        return None
    
    @property
    def age(self):
        """Calculate age from date of birth"""
        if self.date_of_birth:
            from datetime import date
            today = date.today()
            return today.year - self.date_of_birth.year - ((today.month, today.day) < (self.date_of_birth.month, self.date_of_birth.day))
        return None


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
    subscription_id = models.CharField(max_length=20, blank=True)  # Unique subscription ID
    start_date = models.DateField()
    end_date = models.DateField()
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='active')
    auto_renew = models.BooleanField(default=False)
    amount_paid = models.DecimalField(max_digits=8, decimal_places=2)
    payment_method = models.CharField(max_length=15, blank=True)
    notes = models.TextField(blank=True)
    created_date = models.DateTimeField(auto_now_add=True)
    updated_date = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['gym_owner', 'subscription_id']
        indexes = [
            models.Index(fields=['gym_owner', 'status']),
            models.Index(fields=['gym_owner', 'member']),
            models.Index(fields=['gym_owner', 'start_date']),
            models.Index(fields=['subscription_id']),
        ]
    
    def __str__(self):
        return f"{self.member} - {self.subscription_plan.name} - {self.gym_owner.gym_name}"
    
    def save(self, *args, **kwargs):
        if not self.subscription_id:
            # Generate unique subscription ID for this gym
            last_subscription = MemberSubscription.objects.filter(gym_owner=self.gym_owner).order_by('-id').first()
            if last_subscription and last_subscription.subscription_id and last_subscription.subscription_id.startswith('SUB-'):
                try:
                    last_number = int(last_subscription.subscription_id.split('-')[1])
                    new_number = last_number + 1
                    self.subscription_id = f"SUB-{new_number:04d}"
                except (ValueError, IndexError):
                    self.subscription_id = "SUB-0001"
            else:
                self.subscription_id = "SUB-0001"
        super().save(*args, **kwargs)
    
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
        is_new = self.pk is None
        
        if not self.payment_id:
            # Generate unique payment ID for this gym
            try:
                last_payment = MembershipPayment.objects.filter(gym_owner=self.gym_owner).order_by('-id').first()
                if last_payment and last_payment.payment_id and last_payment.payment_id.startswith('PAY-'):
                    try:
                        last_num = int(last_payment.payment_id.split('-')[-1])
                        self.payment_id = f"PAY-{last_num + 1:04d}"
                    except (ValueError, IndexError):
                        # Fallback if payment_id format is unexpected
                        count = MembershipPayment.objects.filter(gym_owner=self.gym_owner).count()
                        self.payment_id = f"PAY-{count + 1:04d}"
                else:
                    self.payment_id = "PAY-0001"
                
                # Ensure uniqueness within this gym with safe parsing
                counter = 1
                base_payment_id = self.payment_id
                while MembershipPayment.objects.filter(gym_owner=self.gym_owner, payment_id=self.payment_id).exists():
                    try:
                        base_num = int(base_payment_id.split('-')[-1])
                        self.payment_id = f"PAY-{base_num + counter:04d}"
                    except (ValueError, IndexError):
                        # Fallback for unexpected format
                        count = MembershipPayment.objects.filter(gym_owner=self.gym_owner).count()
                        self.payment_id = f"PAY-{count + counter:04d}"
                    counter += 1
                    
                    # Safety break to prevent infinite loop
                    if counter > 9999:
                        import uuid
                        self.payment_id = f"PAY-{str(uuid.uuid4())[:8].upper()}"
                        break
                        
            except Exception as e:
                # Ultimate fallback if anything goes wrong
                import uuid
                self.payment_id = f"PAY-{str(uuid.uuid4())[:8].upper()}"
                print(f"⚠️ PAYMENT: Error generating payment_id, using UUID fallback: {e}")
        
        super().save(*args, **kwargs)
        
        # Auto-extend membership when payment is created (with error handling)
        if is_new and self.member and self.membership_months and self.status == 'completed':
            try:
                print(f'💳 PAYMENT: Auto-extending membership for payment ID {self.id}')
                member_name = self.member.user.get_full_name() if self.member.user else 'Unknown Member'
                print(f'💳 PAYMENT: Member: {member_name}')
                print(f'💳 PAYMENT: Membership months: {self.membership_months}')
                print(f'💳 PAYMENT: Current member expiry: {self.member.membership_expiry}')
                
                from datetime import timedelta
                from django.utils import timezone
                
                member = self.member
                today = timezone.now().date()
                
                # Calculate new expiry date
                if member.membership_expiry and member.membership_expiry > today:
                    # Extend from current expiry date if still valid
                    new_expiry = member.membership_expiry + timedelta(days=self.membership_months * 30)
                    print(f'💳 PAYMENT: Extending membership from {member.membership_expiry} to {new_expiry}')
                else:
                    # Start from today if membership is expired
                    new_expiry = today + timedelta(days=self.membership_months * 30)
                    print(f'💳 PAYMENT: Starting new membership from {today} to {new_expiry}')
                
                # Update member's expiry date and reactivate if needed
                member.membership_expiry = new_expiry
                if not member.is_active:
                    member.is_active = True
                    print(f'💳 PAYMENT: Reactivating member {member_name}')
                
                member.save()
                
                # Create or update MemberSubscription if subscription_plan is specified
                if self.subscription_plan:
                    try:
                        member_subscription, created = MemberSubscription.objects.get_or_create(
                            member=member,
                            subscription_plan=self.subscription_plan,
                            defaults={
                                'gym_owner': self.gym_owner,
                                'start_date': new_expiry - timedelta(days=self.membership_months * 30),
                                'end_date': new_expiry,
                                'status': 'active',
                                'amount_paid': self.amount,
                                'payment_method': self.payment_method
                            }
                        )
                        if not created:
                            # Update existing subscription
                            member_subscription.end_date = new_expiry
                            member_subscription.status = 'active'
                            member_subscription.save()
                        print(f'💳 PAYMENT: {"Created" if created else "Updated"} subscription for {member_name}')
                    except Exception as sub_error:
                        print(f'⚠️ PAYMENT: Subscription creation/update failed: {sub_error}')
                        # Don't fail the payment if subscription fails
                
                print(f'✅ PAYMENT: Member {member_name} membership extended to {new_expiry}')
                
            except Exception as membership_error:
                print(f'⚠️ PAYMENT: Membership extension failed: {membership_error}')
                # Don't fail the payment if membership extension fails
        
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


class Notification(models.Model):
    """
    Model for managing gym owner notifications
    """
    NOTIFICATION_TYPES = [
        ('member_expiry', 'Member Expiry'),
        ('member_expiring_soon', 'Member Expiring Soon'),
        ('payment_received', 'Payment Received'),
        ('system_alert', 'System Alert'),
    ]
    
    PRIORITY_LEVELS = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('urgent', 'Urgent'),
    ]
    
    gym_owner = models.ForeignKey(GymOwner, on_delete=models.CASCADE, related_name='notifications')
    type = models.CharField(max_length=20, choices=NOTIFICATION_TYPES)
    priority = models.CharField(max_length=10, choices=PRIORITY_LEVELS, default='medium')
    title = models.CharField(max_length=200)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    read_at = models.DateTimeField(null=True, blank=True)
    
    # Optional related objects
    related_member = models.ForeignKey(Member, on_delete=models.CASCADE, null=True, blank=True)
    related_payment = models.ForeignKey('MembershipPayment', on_delete=models.CASCADE, null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['gym_owner', 'is_read']),
            models.Index(fields=['gym_owner', 'type']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return f"{self.title} - {self.gym_owner.gym_name}"
    
    def mark_as_read(self):
        """Mark notification as read"""
        if not self.is_read:
            self.is_read = True
            self.read_at = timezone.now()
            self.save()
    
    @classmethod
    def create_member_expiry_notification(cls, gym_owner, expired_members):
        """Create notification for expired members"""
        member_count = len(expired_members)
        if member_count == 1:
            member = expired_members[0]
            title = f"Member Expired: {member.user.get_full_name()}"
            message = f"The membership for {member.user.get_full_name()} has expired and they have been automatically deactivated."
        else:
            title = f"{member_count} Members Expired"
            member_names = ", ".join([m.user.get_full_name() for m in expired_members[:3]])
            if member_count > 3:
                member_names += f" and {member_count - 3} others"
            message = f"The following members have expired memberships and have been automatically deactivated: {member_names}"
        
        return cls.objects.create(
            gym_owner=gym_owner,
            type='member_expiry',
            priority='high',
            title=title,
            message=message,
            related_member=expired_members[0] if member_count == 1 else None
        )
    
    @classmethod
    def create_expiring_soon_notification(cls, gym_owner, expiring_members):
        """Create notification for members expiring soon"""
        member_count = len(expiring_members)
        if member_count == 1:
            member = expiring_members[0]
            days_left = (member.membership_expiry - get_ist_date()).days
            title = f"Member Expiring Soon: {member.user.get_full_name()}"
            message = f"The membership for {member.user.get_full_name()} will expire in {days_left} days."
        else:
            title = f"{member_count} Members Expiring Soon"
            member_names = ", ".join([m.user.get_full_name() for m in expiring_members[:3]])
            if member_count > 3:
                member_names += f" and {member_count - 3} others"
            message = f"The following members have memberships expiring within 7 days: {member_names}"
        
        return cls.objects.create(
            gym_owner=gym_owner,
            type='member_expiring_soon',
            priority='medium',
            title=title,
            message=message,
            related_member=expiring_members[0] if member_count == 1 else None
        )
