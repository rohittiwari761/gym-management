from rest_framework import serializers
from django.contrib.auth.models import User
from .models import GymOwner, Member, Trainer, Equipment, WorkoutPlan, Exercise, WorkoutSession, MembershipPayment, Attendance, SubscriptionPlan, MemberSubscription, TrainerMemberAssociation


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name']


class GymOwnerSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    total_members = serializers.SerializerMethodField()
    total_trainers = serializers.SerializerMethodField()
    total_equipment = serializers.SerializerMethodField()
    profile_picture_url = serializers.SerializerMethodField()
    
    class Meta:
        model = GymOwner
        fields = '__all__'
    
    def get_total_members(self, obj):
        return obj.members.filter(is_active=True).count()
    
    def get_total_trainers(self, obj):
        return obj.trainers.filter(is_available=True).count()
    
    def get_total_equipment(self, obj):
        return obj.equipment.filter(is_working=True).count()
    
    def get_profile_picture_url(self, obj):
        """Get the full URL for the profile picture - prefer base64 data URL for Railway"""
        # First try base64 data URL (works reliably on Railway)
        if obj.profile_picture_base64 and obj.profile_picture_content_type:
            data_url = f"data:{obj.profile_picture_content_type};base64,{obj.profile_picture_base64}"
            print(f'🖼️ Using base64 data URL for profile picture')
            return data_url
        
        # Fallback to traditional file URL
        if obj.profile_picture and obj.profile_picture.name:
            request = self.context.get('request')
            if request:
                try:
                    return request.build_absolute_uri(obj.profile_picture.url)
                except Exception as e:
                    print(f'❌ Error building profile picture URL: {e}')
                    return obj.profile_picture.url
            else:
                return obj.profile_picture.url
        return None
    
    def create(self, validated_data):
        # Extract user data from request
        request = self.context['request']
        user_data = request.data.get('user', {})
        
        # Create user first
        try:
            email = user_data.get('email')
            if not email:
                raise serializers.ValidationError("Email is required")
            
            # Check if gym owner with this email already exists
            existing_user = User.objects.filter(email=email).first()
            if existing_user and hasattr(existing_user, 'gymowner'):
                raise serializers.ValidationError(f"A gym owner with email {email} already exists")
            
            # Create or get user
            if existing_user:
                user = existing_user
            else:
                username = user_data.get('username', email)
                user = User.objects.create_user(
                    username=username,
                    email=email,
                    first_name=user_data.get('first_name', ''),
                    last_name=user_data.get('last_name', ''),
                    password=user_data.get('password', 'defaultpass123')
                )
            
            # Create gym owner with the user
            validated_data['user'] = user
            gym_owner = GymOwner.objects.create(**validated_data)
            return gym_owner
            
        except Exception as e:
            raise serializers.ValidationError(f"Error creating gym owner: {str(e)}")


class MemberSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    gym_owner = GymOwnerSerializer(read_only=True)
    days_until_expiry = serializers.SerializerMethodField()
    
    class Meta:
        model = Member
        fields = '__all__'
        extra_kwargs = {
            'member_id': {'required': False, 'read_only': True},
            'gym_owner': {'read_only': True},
        }
    
    def get_days_until_expiry(self, obj):
        from datetime import date
        if obj.membership_expiry:
            delta = obj.membership_expiry - date.today()
            return max(0, delta.days)
        return 0
    
    def create(self, validated_data):
        # Extract user data from request
        request = self.context['request']
        user_data = request.data.get('user', {})
        
        # Create user first
        try:
            email = user_data.get('email')
            if not email:
                raise serializers.ValidationError("Email is required")
            
            # Check if a member with this email already exists
            existing_user = User.objects.filter(email=email).first()
            if existing_user and hasattr(existing_user, 'member'):
                raise serializers.ValidationError(f"A member with email {email} already exists")
            
            # Create or get user
            if existing_user:
                # Use existing user but create a new member
                user = existing_user
            else:
                # Create new user
                username = user_data.get('username', email)
                user = User.objects.create(
                    username=username,
                    email=email,
                    first_name=user_data.get('first_name', ''),
                    last_name=user_data.get('last_name', ''),
                )
            
            # Get gym_owner from request context or data
            gym_owner_id = self.context['request'].data.get('gym_owner')
            if gym_owner_id:
                try:
                    validated_data['gym_owner'] = GymOwner.objects.get(id=gym_owner_id)
                except GymOwner.DoesNotExist:
                    raise serializers.ValidationError(f"Gym owner with id {gym_owner_id} does not exist")
            
            # Create member with the user
            validated_data['user'] = user
            member = Member.objects.create(**validated_data)
            return member
            
        except Exception as e:
            raise serializers.ValidationError(f"Error creating member: {str(e)}")


class TrainerSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    gym_owner = GymOwnerSerializer(read_only=True)
    total_sessions = serializers.SerializerMethodField()
    
    class Meta:
        model = Trainer
        fields = '__all__'
        extra_kwargs = {
            'trainer_id': {'required': False, 'read_only': True},
            'gym_owner': {'read_only': True},
        }
    
    def get_total_sessions(self, obj):
        return obj.workoutsession_set.filter(completed=True).count()
    
    def create(self, validated_data):
        # Extract user data from request
        request = self.context['request']
        user_data = request.data.get('user', {})
        
        # Create user first
        try:
            email = user_data.get('email')
            if not email:
                raise serializers.ValidationError("Email is required")
            
            # Check if a trainer with this email already exists
            existing_user = User.objects.filter(email=email).first()
            if existing_user and hasattr(existing_user, 'trainer'):
                raise serializers.ValidationError(f"A trainer with email {email} already exists")
            
            # Create or get user
            if existing_user:
                # Use existing user but create a new trainer
                user = existing_user
            else:
                # Create new user
                username = user_data.get('username', email)
                user = User.objects.create(
                    username=username,
                    email=email,
                    first_name=user_data.get('first_name', ''),
                    last_name=user_data.get('last_name', ''),
                )
            
            # Get gym_owner from request context or data
            gym_owner_id = self.context['request'].data.get('gym_owner')
            if gym_owner_id:
                try:
                    validated_data['gym_owner'] = GymOwner.objects.get(id=gym_owner_id)
                except GymOwner.DoesNotExist:
                    raise serializers.ValidationError(f"Gym owner with id {gym_owner_id} does not exist")
            
            # Create trainer with the user
            validated_data['user'] = user
            trainer = Trainer.objects.create(**validated_data)
            return trainer
            
        except Exception as e:
            raise serializers.ValidationError(f"Error creating trainer: {str(e)}")


class EquipmentSerializer(serializers.ModelSerializer):
    gym_owner = GymOwnerSerializer(read_only=True)
    condition_display = serializers.CharField(source='get_condition_display', read_only=True)
    warranty_status = serializers.SerializerMethodField()
    
    class Meta:
        model = Equipment
        fields = '__all__'
        extra_kwargs = {
            'equipment_id': {'required': False, 'read_only': True},
            'gym_owner': {'read_only': True},
        }
    
    def get_warranty_status(self, obj):
        from datetime import date
        if obj.warranty_expiry:
            days_left = (obj.warranty_expiry - date.today()).days
            if days_left < 0:
                return 'Expired'
            elif days_left < 30:
                return 'Expiring Soon'
            else:
                return 'Active'
        return 'Unknown'


class ExerciseSerializer(serializers.ModelSerializer):
    equipment_needed = EquipmentSerializer(many=True, read_only=True)
    
    class Meta:
        model = Exercise
        fields = '__all__'


class WorkoutPlanSerializer(serializers.ModelSerializer):
    created_by = TrainerSerializer(read_only=True)
    
    class Meta:
        model = WorkoutPlan
        fields = '__all__'


class WorkoutSessionSerializer(serializers.ModelSerializer):
    member = MemberSerializer(read_only=True)
    trainer = TrainerSerializer(read_only=True)
    workout_plan = WorkoutPlanSerializer(read_only=True)
    
    class Meta:
        model = WorkoutSession
        fields = '__all__'


class SubscriptionPlanSerializer(serializers.ModelSerializer):
    gym_owner = GymOwnerSerializer(read_only=True)
    duration_display = serializers.SerializerMethodField()
    active_subscribers = serializers.SerializerMethodField()
    
    class Meta:
        model = SubscriptionPlan
        fields = '__all__'
        extra_kwargs = {
            'plan_id': {'required': False, 'read_only': True},
            'gym_owner': {'read_only': True},
        }
    
    def get_duration_display(self, obj):
        return f"{obj.duration_value} {obj.get_duration_type_display()}"
    
    def get_active_subscribers(self, obj):
        return obj.membersubscription_set.filter(status='active').count()


class MembershipPaymentSerializer(serializers.ModelSerializer):
    member = MemberSerializer(read_only=True)
    subscription_plan = SubscriptionPlanSerializer(read_only=True)
    gym_owner = GymOwnerSerializer(read_only=True)
    payment_method_display = serializers.CharField(source='get_payment_method_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    
    class Meta:
        model = MembershipPayment
        fields = '__all__'
        extra_kwargs = {
            'payment_id': {'required': False, 'read_only': True},
            'gym_owner': {'read_only': True},
        }
    
    def create(self, validated_data):
        # Extract member and subscription_plan IDs from request data
        request = self.context['request']
        member_id = request.data.get('member')
        subscription_plan_id = request.data.get('subscription_plan')
        gym_owner_id = request.data.get('gym_owner')
        
        if gym_owner_id:
            try:
                validated_data['gym_owner'] = GymOwner.objects.get(id=gym_owner_id)
            except GymOwner.DoesNotExist:
                raise serializers.ValidationError(f"Gym owner with id {gym_owner_id} does not exist")
        
        if member_id:
            try:
                validated_data['member'] = Member.objects.get(id=member_id)
            except Member.DoesNotExist:
                raise serializers.ValidationError(f"Member with id {member_id} does not exist")
        
        if subscription_plan_id:
            try:
                validated_data['subscription_plan'] = SubscriptionPlan.objects.get(id=subscription_plan_id)
            except SubscriptionPlan.DoesNotExist:
                raise serializers.ValidationError(f"Subscription plan with id {subscription_plan_id} does not exist")
        
        return MembershipPayment.objects.create(**validated_data)


class AttendanceSerializer(serializers.ModelSerializer):
    member = MemberSerializer(read_only=True)
    gym_owner = GymOwnerSerializer(read_only=True)
    duration_display = serializers.SerializerMethodField()
    
    class Meta:
        model = Attendance
        fields = '__all__'
        extra_kwargs = {
            'attendance_id': {'required': False, 'read_only': True},
            'gym_owner': {'read_only': True},
        }
    
    def get_duration_display(self, obj):
        if obj.duration_hours:
            return f"{obj.duration_hours} hours"
        return "Not checked out"


class MemberSubscriptionSerializer(serializers.ModelSerializer):
    member = MemberSerializer(read_only=True)
    subscription_plan = SubscriptionPlanSerializer(read_only=True)
    gym_owner = GymOwnerSerializer(read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    is_active = serializers.BooleanField(read_only=True)
    is_expired = serializers.BooleanField(read_only=True)
    is_expiring_soon = serializers.BooleanField(read_only=True)
    days_remaining = serializers.IntegerField(read_only=True)
    
    class Meta:
        model = MemberSubscription
        fields = '__all__'


class WorkoutPlanSerializer(serializers.ModelSerializer):
    created_by = TrainerSerializer(read_only=True)
    gym_owner = GymOwnerSerializer(read_only=True)
    difficulty_display = serializers.CharField(source='get_difficulty_level_display', read_only=True)
    
    class Meta:
        model = WorkoutPlan
        fields = '__all__'


class ExerciseSerializer(serializers.ModelSerializer):
    equipment_needed = EquipmentSerializer(many=True, read_only=True)
    gym_owner = GymOwnerSerializer(read_only=True)
    muscle_group_display = serializers.CharField(source='get_muscle_group_display', read_only=True)
    
    class Meta:
        model = Exercise
        fields = '__all__'


class WorkoutSessionSerializer(serializers.ModelSerializer):
    member = MemberSerializer(read_only=True)
    trainer = TrainerSerializer(read_only=True)
    workout_plan = WorkoutPlanSerializer(read_only=True)
    gym_owner = GymOwnerSerializer(read_only=True)
    
    class Meta:
        model = WorkoutSession
        fields = '__all__'


class TrainerMemberAssociationSerializer(serializers.ModelSerializer):
    member = MemberSerializer(read_only=True)
    trainer = TrainerSerializer(read_only=True)
    assigned_by = UserSerializer(read_only=True)
    gym_owner = GymOwnerSerializer(read_only=True)
    
    # Write-only fields for creating associations
    member_id = serializers.IntegerField(write_only=True)
    trainer_id = serializers.IntegerField(write_only=True)
    
    class Meta:
        model = TrainerMemberAssociation
        fields = ['id', 'member', 'trainer', 'assigned_date', 'assigned_by', 'is_active', 'notes', 
                 'created_at', 'updated_at', 'member_id', 'trainer_id', 'gym_owner']
        read_only_fields = ['assigned_date', 'assigned_by', 'created_at', 'updated_at', 'gym_owner']
    
    def create(self, validated_data):
        # Set gym_owner and assigned_by from context
        validated_data['gym_owner'] = self.context['gym_owner']
        validated_data['assigned_by'] = self.context['request'].user
        
        # Get member and trainer objects
        member_id = validated_data.pop('member_id')
        trainer_id = validated_data.pop('trainer_id')
        
        try:
            validated_data['member'] = Member.objects.get(
                id=member_id, 
                gym_owner=validated_data['gym_owner']
            )
            validated_data['trainer'] = Trainer.objects.get(
                id=trainer_id, 
                gym_owner=validated_data['gym_owner']
            )
        except (Member.DoesNotExist, Trainer.DoesNotExist) as e:
            raise serializers.ValidationError(f"Invalid member or trainer: {str(e)}")
        
        return super().create(validated_data)