from django.core.management.base import BaseCommand
from django.utils import timezone
from django.core.mail import send_mail
from django.conf import settings
from gym_api.models import Member, GymOwner, Notification, get_ist_date
import logging

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = 'Deactivate members with expired memberships and send notifications'

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Show what would be deactivated without actually doing it',
        )
        parser.add_argument(
            '--send-notifications',
            action='store_true',
            help='Send email notifications to gym owners',
        )

    def handle(self, *args, **options):
        today = get_ist_date()
        dry_run = options['dry_run']
        send_notifications = options['send_notifications']
        
        if dry_run:
            self.stdout.write(self.style.WARNING('🔍 DRY RUN MODE - No changes will be made'))
        
        # Find all expired members who are still active
        expired_members = Member.objects.filter(
            membership_expiry__lt=today,
            is_active=True
        ).select_related('user', 'gym_owner')
        
        total_expired = expired_members.count()
        self.stdout.write(f'📊 Found {total_expired} expired members to process')
        
        # Group by gym owner for notifications
        gym_owner_notifications = {}
        deactivated_count = 0
        
        for member in expired_members:
            gym_owner = member.gym_owner
            days_expired = (today - member.membership_expiry).days
            
            self.stdout.write(
                f'👤 Member: {member.user.get_full_name()} '
                f'(Gym: {gym_owner.gym_name}) - '
                f'Expired {days_expired} days ago'
            )
            
            if not dry_run:
                # Deactivate the member
                member.is_active = False
                member.save()
                deactivated_count += 1
                
                # Log the deactivation
                logger.info(f'Deactivated expired member: {member.user.get_full_name()} (ID: {member.id})')
            
            # Prepare notification data
            if gym_owner.id not in gym_owner_notifications:
                gym_owner_notifications[gym_owner.id] = {
                    'gym_owner': gym_owner,
                    'expired_members': []
                }
            
            gym_owner_notifications[gym_owner.id]['expired_members'].append({
                'member': member,
                'days_expired': days_expired
            })
        
        # Create in-app notifications and send email notifications to gym owners
        if gym_owner_notifications:
            self.stdout.write(f'📧 Processing notifications for {len(gym_owner_notifications)} gym owners')
            
            for gym_data in gym_owner_notifications.values():
                # Create in-app notification
                if not dry_run:
                    expired_members_list = [data['member'] for data in gym_data['expired_members']]
                    Notification.create_member_expiry_notification(
                        gym_data['gym_owner'], expired_members_list
                    )
                    self.stdout.write(f'✅ Created in-app notification for {gym_data["gym_owner"].gym_name}')
                
                # Send email notification if requested
                if send_notifications:
                    self._send_expiration_notification(gym_data, dry_run)
        
        # Summary
        if dry_run:
            self.stdout.write(
                self.style.SUCCESS(
                    f'✅ DRY RUN COMPLETE: Would deactivate {total_expired} expired members'
                )
            )
        else:
            self.stdout.write(
                self.style.SUCCESS(
                    f'✅ COMPLETE: Deactivated {deactivated_count} expired members'
                )
            )
    
    def _send_expiration_notification(self, gym_data, dry_run):
        """Send email notification to gym owner about expired members"""
        gym_owner = gym_data['gym_owner']
        expired_members = gym_data['expired_members']
        
        if not gym_owner.user.email:
            self.stdout.write(
                self.style.WARNING(f'⚠️  No email for gym owner: {gym_owner.gym_name}')
            )
            return
        
        # Prepare email content
        subject = f'🚨 Expired Memberships Alert - {gym_owner.gym_name}'
        
        member_list = '\n'.join([
            f'• {data["member"].user.get_full_name()} - Expired {data["days_expired"]} days ago'
            for data in expired_members
        ])
        
        message = f"""
Dear {gym_owner.user.get_full_name()},

This is an automated notification from your Gym Management System.

The following members have expired memberships and have been automatically deactivated:

{member_list}

Total expired members: {len(expired_members)}

Please contact these members to renew their memberships or take appropriate action.

You can reactivate members by:
1. Creating a new payment for the member
2. Manually updating their membership expiry date

Best regards,
Gym Management System
        """.strip()
        
        if dry_run:
            self.stdout.write(f'📧 Would send email to: {gym_owner.user.email}')
            self.stdout.write(f'📧 Subject: {subject}')
        else:
            try:
                send_mail(
                    subject=subject,
                    message=message,
                    from_email=settings.DEFAULT_FROM_EMAIL,
                    recipient_list=[gym_owner.user.email],
                    fail_silently=False,
                )
                self.stdout.write(
                    self.style.SUCCESS(f'📧 Email sent to: {gym_owner.user.email}')
                )
                logger.info(f'Expiration notification sent to {gym_owner.user.email}')
            except Exception as e:
                self.stdout.write(
                    self.style.ERROR(f'❌ Failed to send email to {gym_owner.user.email}: {e}')
                )
                logger.error(f'Failed to send expiration notification: {e}')