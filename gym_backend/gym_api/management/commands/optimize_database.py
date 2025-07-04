"""
Management command for database optimization and maintenance.
Designed for production environments with 100k+ users.
"""

from django.core.management.base import BaseCommand
from django.db import connection, transaction
from django.core.cache import cache
from django.utils import timezone
from datetime import timedelta
import logging

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = 'Optimize database performance for large-scale deployment'

    def add_arguments(self, parser):
        parser.add_argument(
            '--vacuum',
            action='store_true',
            help='Run VACUUM ANALYZE on PostgreSQL',
        )
        parser.add_argument(
            '--reindex',
            action='store_true',
            help='Rebuild database indexes',
        )
        parser.add_argument(
            '--cleanup',
            action='store_true',
            help='Clean up old data and logs',
        )
        parser.add_argument(
            '--cache-warm',
            action='store_true',
            help='Warm up application cache',
        )
        parser.add_argument(
            '--all',
            action='store_true',
            help='Run all optimization tasks',
        )

    def handle(self, *args, **options):
        start_time = timezone.now()
        
        self.stdout.write(
            self.style.SUCCESS('Starting database optimization...')
        )
        
        if options['all']:
            options['vacuum'] = True
            options['reindex'] = True
            options['cleanup'] = True
            options['cache_warm'] = True
        
        if options['vacuum']:
            self.vacuum_database()
        
        if options['reindex']:
            self.reindex_database()
        
        if options['cleanup']:
            self.cleanup_old_data()
        
        if options['cache_warm']:
            self.warm_cache()
        
        end_time = timezone.now()
        duration = (end_time - start_time).total_seconds()
        
        self.stdout.write(
            self.style.SUCCESS(
                f'Database optimization completed in {duration:.2f} seconds'
            )
        )

    def vacuum_database(self):
        """Run VACUUM ANALYZE on PostgreSQL for better performance."""
        self.stdout.write('Running VACUUM ANALYZE...')
        
        try:
            with connection.cursor() as cursor:
                # Get all table names
                cursor.execute("""
                    SELECT tablename FROM pg_tables 
                    WHERE schemaname = 'public' AND tablename LIKE 'gym_api_%'
                """)
                tables = cursor.fetchall()
                
                for table in tables:
                    table_name = table[0]
                    self.stdout.write(f'  Vacuuming {table_name}...')
                    cursor.execute(f'VACUUM ANALYZE "{table_name}";')
                    
            self.stdout.write(
                self.style.SUCCESS('✓ VACUUM ANALYZE completed')
            )
        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'✗ VACUUM failed: {e}')
            )

    def reindex_database(self):
        """Rebuild database indexes for optimal performance."""
        self.stdout.write('Rebuilding database indexes...')
        
        try:
            with connection.cursor() as cursor:
                # Get all indexes
                cursor.execute("""
                    SELECT indexname, tablename FROM pg_indexes 
                    WHERE schemaname = 'public' AND tablename LIKE 'gym_api_%'
                    AND indexname NOT LIKE '%_pkey'
                """)
                indexes = cursor.fetchall()
                
                for index_name, table_name in indexes:
                    self.stdout.write(f'  Reindexing {index_name}...')
                    cursor.execute(f'REINDEX INDEX "{index_name}";')
                    
            self.stdout.write(
                self.style.SUCCESS('✓ Database reindexing completed')
            )
        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'✗ Reindexing failed: {e}')
            )

    def cleanup_old_data(self):
        """Clean up old data to maintain performance."""
        self.stdout.write('Cleaning up old data...')
        
        try:
            from gym_api.models import Attendance, MembershipPayment
            
            # Clean up old attendance records (older than 2 years)
            old_date = timezone.now().date() - timedelta(days=730)
            old_attendance = Attendance.objects.filter(date__lt=old_date)
            count = old_attendance.count()
            
            if count > 0:
                self.stdout.write(f'  Removing {count} old attendance records...')
                old_attendance.delete()
            
            # Clean up old payment records (keep for accounting, just mark as archived)
            old_payments = MembershipPayment.objects.filter(
                payment_date__lt=timezone.now() - timedelta(days=1095)  # 3 years
            )
            
            # Add an 'archived' field to payments model if needed
            # old_payments.update(archived=True)
            
            self.stdout.write(
                self.style.SUCCESS('✓ Old data cleanup completed')
            )
        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'✗ Data cleanup failed: {e}')
            )

    def warm_cache(self):
        """Pre-populate cache with frequently accessed data."""
        self.stdout.write('Warming up application cache...')
        
        try:
            from gym_api.models import GymOwner, Member
            
            # Cache active gym counts
            for gym in GymOwner.objects.filter(is_active=True):
                cache_key = f'active_members_count_{gym.id}'
                member_count = gym.members.filter(is_active=True).count()
                cache.set(cache_key, member_count, 1800)  # 30 minutes
                
                self.stdout.write(f'  Cached member count for gym {gym.id}')
            
            # Pre-calculate some analytics
            # This would include frequently accessed dashboard data
            
            self.stdout.write(
                self.style.SUCCESS('✓ Cache warming completed')
            )
        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'✗ Cache warming failed: {e}')
            )

    def get_database_stats(self):
        """Get database performance statistics."""
        try:
            with connection.cursor() as cursor:
                # Table sizes
                cursor.execute("""
                    SELECT 
                        tablename,
                        pg_size_pretty(pg_total_relation_size(tablename::regclass)) as size
                    FROM pg_tables 
                    WHERE schemaname = 'public' AND tablename LIKE 'gym_api_%'
                    ORDER BY pg_total_relation_size(tablename::regclass) DESC;
                """)
                
                tables = cursor.fetchall()
                
                self.stdout.write('\nDatabase Statistics:')
                self.stdout.write('-' * 40)
                for table_name, size in tables:
                    self.stdout.write(f'{table_name}: {size}')
                    
        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'Failed to get database stats: {e}')
            )