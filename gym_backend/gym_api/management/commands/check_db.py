"""
Management command to check database connection and configuration.
"""

from django.core.management.base import BaseCommand
from django.db import connection
from django.conf import settings
import os


class Command(BaseCommand):
    help = 'Check database connection and configuration'

    def handle(self, *args, **options):
        """Check database configuration and connection."""
        
        # Check DATABASE_URL environment variable
        database_url = os.environ.get('DATABASE_URL')
        if database_url:
            self.stdout.write(
                self.style.SUCCESS(f'✅ DATABASE_URL found: {database_url[:50]}...')
            )
        else:
            self.stdout.write(
                self.style.WARNING('⚠️  DATABASE_URL not found in environment variables')
            )
        
        # Check Django database configuration
        db_config = settings.DATABASES['default']
        engine = db_config.get('ENGINE')
        
        if 'postgresql' in engine:
            self.stdout.write(
                self.style.SUCCESS(f'✅ Using PostgreSQL: {engine}')
            )
        elif 'sqlite' in engine:
            self.stdout.write(
                self.style.WARNING(f'⚠️  Using SQLite: {engine}')
            )
        else:
            self.stdout.write(
                self.style.ERROR(f'❌ Unknown database engine: {engine}')
            )
        
        # Test database connection
        try:
            with connection.cursor() as cursor:
                if 'postgresql' in engine:
                    cursor.execute("SELECT version()")
                    result = cursor.fetchone()
                    self.stdout.write(
                        self.style.SUCCESS(f'✅ PostgreSQL connection successful')
                    )
                    self.stdout.write(f'Database version: {result[0]}')
                elif 'sqlite' in engine:
                    cursor.execute("SELECT sqlite_version()")
                    result = cursor.fetchone()
                    self.stdout.write(
                        self.style.SUCCESS(f'✅ SQLite connection successful')
                    )
                    self.stdout.write(f'SQLite version: {result[0]}')
                else:
                    cursor.execute("SELECT 1")
                    cursor.fetchone()
                    self.stdout.write(
                        self.style.SUCCESS(f'✅ Database connection successful')
                    )
        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'❌ Database connection failed: {str(e)}')
            )
        
        # Show full database configuration (without sensitive data)
        self.stdout.write('\n--- Database Configuration ---')
        for key, value in db_config.items():
            if key in ['PASSWORD', 'SECRET_KEY']:
                self.stdout.write(f'{key}: ***hidden***')
            else:
                self.stdout.write(f'{key}: {value}')