"""
Management command to create a test gym owner for testing.
"""

from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from django.db import transaction
from gym_api.models import GymOwner
import uuid


class Command(BaseCommand):
    help = 'Create a test gym owner for testing'

    def add_arguments(self, parser):
        parser.add_argument(
            '--email',
            type=str,
            default='test@gym.com',
            help='Email for the test user'
        )
        parser.add_argument(
            '--password',
            type=str,
            default='TestPass123!',
            help='Password for the test user'
        )

    def handle(self, *args, **options):
        """Create test gym owner."""
        
        email = options['email']
        password = options['password']
        
        self.stdout.write(f"🧪 Creating test gym owner: {email}")
        
        try:
            with transaction.atomic():
                # Check if user already exists
                if User.objects.filter(email=email).exists():
                    self.stdout.write(
                        self.style.WARNING(f'⚠️  User {email} already exists')
                    )
                    user = User.objects.get(email=email)
                    if hasattr(user, 'gymowner'):
                        self.stdout.write(
                            self.style.SUCCESS(f'✅ Gym owner already exists: {user.gymowner.gym_name}')
                        )
                        return
                else:
                    # Create User
                    user = User.objects.create_user(
                        username=email,
                        email=email,
                        first_name='Test',
                        last_name='User',
                        password=password
                    )
                    self.stdout.write(
                        self.style.SUCCESS(f'✅ User created: {email}')
                    )
                
                # Create GymOwner
                gym_owner = GymOwner.objects.create(
                    user=user,
                    gym_name='Test Gym',
                    gym_address='123 Test Street, Test City',
                    gym_description='A test gym for testing purposes',
                    phone_number='1234567890',
                    subscription_plan='basic',
                    qr_code_token=uuid.uuid4()
                )
                
                self.stdout.write(
                    self.style.SUCCESS(f'✅ Gym owner created: {gym_owner.gym_name}')
                )
                self.stdout.write(
                    self.style.SUCCESS(f'🔑 Login credentials:')
                )
                self.stdout.write(f'   Email: {email}')
                self.stdout.write(f'   Password: {password}')
                self.stdout.write(f'   Gym: {gym_owner.gym_name}')
                self.stdout.write(f'   QR Token: {gym_owner.qr_code_token}')
                
        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'❌ Error creating test user: {str(e)}')
            )
            raise e