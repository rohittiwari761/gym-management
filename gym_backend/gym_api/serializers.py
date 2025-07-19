from rest_framework import serializers
from django.contrib.auth.models import User
from .models import GymOwner, Member, Trainer, Equipment, WorkoutPlan, Exercise, WorkoutSession, MembershipPayment, Attendance, SubscriptionPlan, MemberSubscription, TrainerMemberAssociation, Notification


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


# Optimized User serializer for Member responses (excludes heavy data)
class UserMinimalSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'first_name', 'last_name', 'email']  # Essential fields only


# Optimized GymOwner serializer for Equipment responses (excludes heavy data)
class GymOwnerMinimalSerializer(serializers.ModelSerializer):
    class Meta:
        model = GymOwner
        fields = ['id', 'gym_name']  # Only essential fields


class MemberSerializer(serializers.ModelSerializer):
    user = UserMinimalSerializer(read_only=True)
    gym_owner = GymOwnerMinimalSerializer(read_only=True)
    days_until_expiry = serializers.SerializerMethodField()
    
    class Meta:
        model = Member
        fields = '__all__'
        extra_kwargs = {
            'member_id': {'required': False, 'read_only': True},
            'gym_owner': {'read_only': True},
        }
    
    def get_days_until_expiry(self, obj):
        if obj.membership_expiry:
            from datetime import date
            days_left = (obj.membership_expiry - date.today()).days
            return days_left
        return None


# Super minimal Member serializer for list views (excludes heavy fields)
class MemberListSerializer(serializers.ModelSerializer):
    user = UserMinimalSerializer(read_only=True)
    days_until_expiry = serializers.SerializerMethodField()
    
    class Meta:
        model = Member
        fields = [
            'id', 'member_id', 'user', 'phone', 'membership_type',
            'join_date', 'membership_expiry', 'is_active', 'days_until_expiry'
        ]
        # Exclude heavy fields: emergency_contact_*, address, medical_history, etc.
    
    def get_days_until_expiry(self, obj):
        if obj.membership_expiry:
            from datetime import date
            days_left = (obj.membership_expiry - date.today()).days
            return days_left
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
    user = UserMinimalSerializer(read_only=True)
    gym_owner = GymOwnerMinimalSerializer(read_only=True)
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


# Super minimal Trainer serializer for list views (excludes heavy fields)
class TrainerListSerializer(serializers.ModelSerializer):
    user = UserMinimalSerializer(read_only=True)
    total_sessions = serializers.SerializerMethodField()
    
    class Meta:
        model = Trainer
        fields = [
            'id', 'trainer_id', 'user', 'phone', 'specialization',
            'hourly_rate', 'is_available', 'total_sessions'
        ]
        # Exclude heavy fields: bio, certifications, experience_details, etc.
    
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
    gym_owner = GymOwnerMinimalSerializer(read_only=True)
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


# Super minimal Equipment serializer for list views (excludes heavy fields)
class EquipmentListSerializer(serializers.ModelSerializer):
    warranty_status = serializers.SerializerMethodField()
    
    class Meta:
        model = Equipment
        fields = [
            'id', 'equipment_id', 'name', 'equipment_type', 'brand', 'model',
            'is_working', 'condition', 'warranty_status', 'purchase_date',
            'warranty_expiry', 'location_in_gym', 'quantity'
        ]
        # Exclude heavy fields: maintenance_notes, description, images, etc.
    
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
    gym_owner = GymOwnerMinimalSerializer(read_only=True)
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


# Super minimal SubscriptionPlan serializer for list views
class SubscriptionPlanListSerializer(serializers.ModelSerializer):
    duration_display = serializers.SerializerMethodField()
    
    class Meta:
        model = SubscriptionPlan
        fields = [
            'id', 'plan_id', 'name', 'price', 'duration_value', 'duration_type',
            'duration_display', 'is_active'
        ]
        # Exclude heavy fields: description, terms_and_conditions, etc.
    
    def get_duration_display(self, obj):
        return f"{obj.duration_value} {obj.get_duration_type_display()}"


class MembershipPaymentSerializer(serializers.ModelSerializer):
    member = MemberListSerializer(read_only=True)
    subscription_plan = SubscriptionPlanListSerializer(read_only=True)
    gym_owner = GymOwnerMinimalSerializer(read_only=True)
    payment_method_display = serializers.CharField(source='get_payment_method_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    
    class Meta:
        model = MembershipPayment
        fields = '__all__'
        extra_kwargs = {
            'payment_id': {'required': False, 'read_only': True},
            'gym_owner': {'read_only': True},
        }


# Super minimal Payment serializer for list views (excludes heavy nested data)
class MembershipPaymentListSerializer(serializers.ModelSerializer):
    member_name = serializers.SerializerMethodField()
    plan_name = serializers.SerializerMethodField()
    payment_method_display = serializers.CharField(source='get_payment_method_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    
    class Meta:
        model = MembershipPayment
        fields = [
            'id', 'payment_id', 'amount', 'payment_date', 'payment_method_display',
            'status_display', 'member_name', 'plan_name', 'membership_months'
        ]
        # Exclude heavy fields: member object, subscription_plan object, notes, etc.
    
    def get_member_name(self, obj):
        if obj.member and obj.member.user:
            return f"{obj.member.user.first_name} {obj.member.user.last_name}"
        return "Unknown Member"
    
    def get_plan_name(self, obj):
        return obj.subscription_plan.name if obj.subscription_plan else "No Plan"
    
    def create(self, validated_data):
        # Extract member and subscription_plan IDs from request data
        request = self.context['request']
        member_id = request.data.get('member')
        subscription_plan_id = request.data.get('subscription_plan')
        gym_owner_id = request.data.get('gym_owner')
        
        print(f'💳 SERIALIZER: Creating payment with data: {request.data}')
        print(f'💳 SERIALIZER: Member ID: {member_id}')
        print(f'💳 SERIALIZER: Subscription Plan ID: {subscription_plan_id}')
        print(f'💳 SERIALIZER: Gym Owner ID: {gym_owner_id}')
        print(f'💳 SERIALIZER: Validated data: {validated_data}')
        
        # Ensure we have the current gym owner if gym_owner_id is not provided
        if gym_owner_id:
            try:
                validated_data['gym_owner'] = GymOwner.objects.get(id=gym_owner_id)
                print(f'💳 SERIALIZER: Using provided gym owner ID: {gym_owner_id}')
            except GymOwner.DoesNotExist:
                print(f'❌ SERIALIZER: Gym owner with id {gym_owner_id} does not exist')
                raise serializers.ValidationError(f"Gym owner with id {gym_owner_id} does not exist")
        elif hasattr(request.user, 'gymowner'):
            validated_data['gym_owner'] = request.user.gymowner
            print(f'💳 SERIALIZER: Using authenticated user gym owner: {request.user.gymowner.id}')
        else:
            print('❌ SERIALIZER: No gym owner found in request or user')
            raise serializers.ValidationError("No gym owner found. User must be a gym owner.")
        
        if member_id:
            try:
                # Ensure member belongs to the same gym owner for security
                member = Member.objects.get(
                    id=member_id, 
                    gym_owner=validated_data['gym_owner']
                )
                validated_data['member'] = member
                print(f'💳 SERIALIZER: Member found: {member.user.get_full_name() if member.user else "Unknown"}')
            except Member.DoesNotExist:
                print(f'❌ SERIALIZER: Member with id {member_id} does not exist for this gym')
                raise serializers.ValidationError(f"Member with id {member_id} does not exist or does not belong to your gym")
        else:
            print('❌ SERIALIZER: Member ID is required but not provided')
            raise serializers.ValidationError("Member ID is required")
        
        if subscription_plan_id:
            try:
                # Ensure subscription plan belongs to the same gym owner for security
                subscription_plan = SubscriptionPlan.objects.get(
                    id=subscription_plan_id,
                    gym_owner=validated_data['gym_owner']
                )
                validated_data['subscription_plan'] = subscription_plan
                print(f'💳 SERIALIZER: Subscription plan found: {subscription_plan.name}')
            except SubscriptionPlan.DoesNotExist:
                print(f'❌ SERIALIZER: Subscription plan with id {subscription_plan_id} does not exist for this gym')
                raise serializers.ValidationError(f"Subscription plan with id {subscription_plan_id} does not exist or does not belong to your gym")
        else:
            print('💳 SERIALIZER: No subscription plan provided (optional)')
        
        try:
            payment = MembershipPayment.objects.create(**validated_data)
            print(f'✅ SERIALIZER: Payment created successfully with ID: {payment.id}')
            return payment
        except Exception as e:
            print(f'❌ SERIALIZER: Error creating payment: {str(e)}')
            import traceback
            print(f'❌ SERIALIZER: Traceback: {traceback.format_exc()}')
            raise serializers.ValidationError(f"Failed to create payment: {str(e)}")


class AttendanceSerializer(serializers.ModelSerializer):
    member = MemberListSerializer(read_only=True)
    gym_owner = GymOwnerMinimalSerializer(read_only=True)
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
            hours = int(obj.duration_hours)
            minutes = int((obj.duration_hours - hours) * 60)
            return f"{hours}h {minutes}m"
        return "In progress"


# Super minimal Attendance serializer for list views (excludes heavy nested data)
class AttendanceListSerializer(serializers.ModelSerializer):
    member_name = serializers.SerializerMethodField()
    duration_display = serializers.SerializerMethodField()
    
    class Meta:
        model = Attendance
        fields = [
            'id', 'attendance_id', 'date', 'check_in_time', 'check_out_time',
            'member_name', 'duration_display', 'qr_code_used'
        ]
        # Exclude heavy fields: member object, gym_owner object, notes, etc.
    
    def get_member_name(self, obj):
        if obj.member and obj.member.user:
            return f"{obj.member.user.first_name} {obj.member.user.last_name}"
        return "Unknown Member"
    
    def get_duration_display(self, obj):
        if obj.duration_hours:
            hours = int(obj.duration_hours)
            minutes = int((obj.duration_hours - hours) * 60)
            return f"{hours}h {minutes}m"
        return "In progress"


class MemberSubscriptionSerializer(serializers.ModelSerializer):
    member = MemberListSerializer(read_only=True)  # Use minimal member serializer
    subscription_plan = SubscriptionPlanListSerializer(read_only=True)  # Use minimal plan serializer
    gym_owner = GymOwnerMinimalSerializer(read_only=True)  # Use minimal gym owner serializer
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    is_active = serializers.BooleanField(read_only=True)
    is_expired = serializers.BooleanField(read_only=True)
    is_expiring_soon = serializers.BooleanField(read_only=True)
    days_remaining = serializers.IntegerField(read_only=True)
    
    class Meta:
        model = MemberSubscription
        fields = '__all__'


# Super minimal MemberSubscription serializer for list views (excludes heavy nested data)
class MemberSubscriptionListSerializer(serializers.ModelSerializer):
    member_name = serializers.SerializerMethodField()
    plan_name = serializers.SerializerMethodField()
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    days_remaining = serializers.SerializerMethodField()
    
    class Meta:
        model = MemberSubscription
        fields = [
            'id', 'subscription_id', 'start_date', 'end_date', 'status_display',
            'member_name', 'plan_name', 'amount_paid', 'payment_method', 'days_remaining'
        ]
        # Exclude heavy fields: full member object, full subscription_plan object, gym_owner object, etc.
    
    def get_member_name(self, obj):
        if obj.member and obj.member.user:
            return f"{obj.member.user.first_name} {obj.member.user.last_name}"
        return "Unknown Member"
    
    def get_plan_name(self, obj):
        return obj.subscription_plan.name if obj.subscription_plan else "No Plan"
    
    def get_days_remaining(self, obj):
        return obj.days_remaining if hasattr(obj, 'days_remaining') else 0


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


class NotificationSerializer(serializers.ModelSerializer):
    """Serializer for notifications"""
    related_member_name = serializers.SerializerMethodField()
    time_ago = serializers.SerializerMethodField()
    
    class Meta:
        model = Notification
        fields = [
            'id', 'type', 'priority', 'title', 'message', 
            'is_read', 'created_at', 'read_at',
            'related_member', 'related_member_name', 'related_payment',
            'time_ago'
        ]
        read_only_fields = ['id', 'created_at', 'read_at', 'related_member_name', 'time_ago']
    
    def get_related_member_name(self, obj):
        """Get the name of the related member if exists"""
        if obj.related_member:
            return obj.related_member.user.get_full_name()
        return None
    
    def get_time_ago(self, obj):
        """Get human-readable time since notification was created"""
        from django.utils.timesince import timesince
        return timesince(obj.created_at)