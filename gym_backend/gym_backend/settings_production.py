"""
Production settings for gym_backend project.
Optimized for 100k+ users with enterprise-level performance.
"""

import os
from decouple import config
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

# Import specific settings without database config
SECRET_KEY = 'django-insecure-(pqu1w!c*a$iydc)_le64^ncq(i=zbe)b=br5^zs#dcrjsjrvb'

# Application definition
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'rest_framework.authtoken',
    'corsheaders',
    'gym_api',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'gym_api.middleware.ServeMediaMiddleware',  # Custom media file serving
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'gym_backend.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'gym_backend.wsgi.application'

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'Asia/Kolkata'
USE_I18N = True
USE_TZ = True

# Static files
STATIC_URL = '/static/'
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# REST Framework settings
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_RENDERER_CLASSES': [
        'rest_framework.renderers.JSONRenderer',
    ],
}

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = False

ALLOWED_HOSTS = [
    '192.168.1.7',  # Your local IP
    'localhost',
    '127.0.0.1',
    '.gymmanagement.com',  # Production domain
    '.herokuapp.com',  # If using Heroku
    '.railway.app',  # Railway deployment
    '*',  # Allow all for now (restrict later)
]

# Database Configuration - Railway PostgreSQL
import dj_database_url
import re

# Try multiple ways to get PostgreSQL connection
DATABASE_URL = os.environ.get('DATABASE_URL')
PGHOST = os.environ.get('PGHOST')
PGPORT = os.environ.get('PGPORT', '5432')
PGDATABASE = os.environ.get('PGDATABASE', 'railway')
PGUSER = os.environ.get('PGUSER', 'postgres')
PGPASSWORD = os.environ.get('PGPASSWORD')

def validate_database_url(url):
    """Validate DATABASE_URL format."""
    if not url:
        return False, "DATABASE_URL is empty"
    
    # Check if it starts with postgresql://
    if not url.startswith('postgresql://'):
        return False, f"DATABASE_URL should start with 'postgresql://', got: {url[:30]}..."
    
    # Basic URL pattern check
    pattern = r'^postgresql://[^:]+:[^@]+@[^:]+:\d+/\w+$'
    if not re.match(pattern, url):
        return False, f"DATABASE_URL format is invalid. Expected: postgresql://user:pass@host:port/db, got: {url[:50]}..."
    
    return True, "Valid"

if DATABASE_URL:
    # Method 1: Validate and use DATABASE_URL if available
    is_valid, message = validate_database_url(DATABASE_URL)
    if is_valid:
        try:
            DATABASES = {
                'default': dj_database_url.config(
                    default=DATABASE_URL,
                    conn_max_age=300,
                    conn_health_checks=True,
                )
            }
            print(f"✅ Using DATABASE_URL: {DATABASE_URL[:50]}...")
        except Exception as e:
            print(f"❌ Error parsing DATABASE_URL: {e}")
            print(f"❌ DATABASE_URL value: {DATABASE_URL}")
            print("❌ Falling back to individual variables or SQLite")
            DATABASE_URL = None  # Force fallback
    else:
        print(f"❌ Invalid DATABASE_URL: {message}")
        print(f"❌ DATABASE_URL value: {DATABASE_URL}")
        DATABASE_URL = None  # Force fallback

if not DATABASE_URL and PGHOST and PGPASSWORD:
    # Method 2: Build connection from individual variables
    try:
        manual_database_url = f"postgresql://{PGUSER}:{PGPASSWORD}@{PGHOST}:{PGPORT}/{PGDATABASE}"
        print(f"🔧 Building manual DATABASE_URL: postgresql://{PGUSER}:***@{PGHOST}:{PGPORT}/{PGDATABASE}")
        
        DATABASES = {
            'default': dj_database_url.config(
                default=manual_database_url,
                conn_max_age=300,
                conn_health_checks=True,
            )
        }
        print(f"✅ Using manual PostgreSQL connection: {PGHOST}")
    except Exception as e:
        print(f"❌ Error building manual connection: {e}")
        PGHOST = None  # Force SQLite fallback

if not DATABASE_URL and not (PGHOST and PGPASSWORD):
    # Method 3: Fallback to SQLite (only for development)
    print("⚠️  WARNING: No valid PostgreSQL configuration found!")
    print("⚠️  Issues found:")
    if DATABASE_URL:
        print(f"   - DATABASE_URL format invalid: {DATABASE_URL[:50]}...")
    else:
        print("   - DATABASE_URL not set")
    if not PGHOST:
        print("   - PGHOST not set")
    if not PGPASSWORD:
        print("   - PGPASSWORD not set")
    print("⚠️  Using SQLite fallback - fix PostgreSQL variables in Railway dashboard")
    
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': BASE_DIR / 'db.sqlite3',
        }
    }

# Debug database configuration
print(f"🔍 Database Engine: {DATABASES['default']['ENGINE']}")
if 'postgresql' in DATABASES['default']['ENGINE']:
    print(f"🐘 PostgreSQL Host: {DATABASES['default'].get('HOST', 'Unknown')}")
    print(f"🐘 PostgreSQL Database: {DATABASES['default'].get('NAME', 'Unknown')}")

# Cache Configuration - Simplified for Railway
# Use local memory cache for simplicity (no Redis setup required)
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
        'LOCATION': 'gym-management-cache',
        'TIMEOUT': 300,  # 5 minutes default timeout
        'OPTIONS': {
            'MAX_ENTRIES': 1000,
            'CULL_FREQUENCY': 3,
        }
    }
}

# Use database for session storage (simple and reliable)
SESSION_ENGINE = 'django.contrib.sessions.backends.db'

SESSION_COOKIE_AGE = 86400  # 24 hours

# Security Settings
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True

# API Rate Limiting
RATELIMIT_ENABLE = True
RATELIMIT_USE_CACHE = 'default'

# JWT Configuration for Scalable Authentication
from datetime import timedelta

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'UPDATE_LAST_LOGIN': True,
    'ALGORITHM': 'HS256',
    'SIGNING_KEY': SECRET_KEY,
    'VERIFYING_KEY': None,
    'AUDIENCE': None,
    'ISSUER': None,
    'JWK_URL': None,
    'LEEWAY': 0,
    'AUTH_HEADER_TYPES': ('Bearer', 'Token'),
    'AUTH_HEADER_NAME': 'HTTP_AUTHORIZATION',
    'USER_ID_FIELD': 'id',
    'USER_ID_CLAIM': 'user_id',
    'USER_AUTHENTICATION_RULE': 'rest_framework_simplejwt.authentication.default_user_authentication_rule',
    'AUTH_TOKEN_CLASSES': ('rest_framework_simplejwt.tokens.AccessToken',),
    'TOKEN_TYPE_CLAIM': 'token_type',
    'TOKEN_USER_CLASS': 'rest_framework_simplejwt.models.TokenUser',
    'JTI_CLAIM': 'jti',
    'SLIDING_TOKEN_REFRESH_EXP_CLAIM': 'refresh_exp',
    'SLIDING_TOKEN_LIFETIME': timedelta(minutes=60),
    'SLIDING_TOKEN_REFRESH_LIFETIME': timedelta(days=1),
}

# Enhanced REST Framework Configuration
REST_FRAMEWORK.update({
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',  # Primary - Django tokens
        'rest_framework_simplejwt.authentication.JWTAuthentication',  # Secondary - JWT
        'rest_framework.authentication.SessionAuthentication',
    ],
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.AnonRateThrottle',
        'rest_framework.throttling.UserRateThrottle'
    ],
    'DEFAULT_THROTTLE_RATES': {
        'anon': '100/hour',  # Anonymous users
        'user': '1000/hour',  # Authenticated users
        'login': '5/min',     # Login attempts
        'burst': '60/min',    # Burst protection
    },
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 50,  # Optimize for mobile apps
    'DEFAULT_FILTER_BACKENDS': [
        'django_filters.rest_framework.DjangoFilterBackend',
        'rest_framework.filters.SearchFilter',
        'rest_framework.filters.OrderingFilter',
    ],
})

# Logging Configuration for Railway (Console-only)
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
        'simple': {
            'format': '{levelname} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'console': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
            'formatter': 'simple'
        },
        'console_verbose': {
            'level': 'DEBUG',
            'class': 'logging.StreamHandler',
            'formatter': 'verbose'
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'INFO',
    },
    'loggers': {
        'django': {
            'handlers': ['console'],
            'level': 'INFO',
            'propagate': False,
        },
        'gym_api': {
            'handlers': ['console_verbose'],
            'level': 'INFO',
            'propagate': False,
        },
    },
}

# Static and Media Files Configuration
STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

# Media files configuration - Railway deployment
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

# Ensure media directory exists
os.makedirs(MEDIA_ROOT, exist_ok=True)
print(f"📁 MEDIA_ROOT: {MEDIA_ROOT}")
print(f"🌐 MEDIA_URL: {MEDIA_URL}")

# For Railway, we need to ensure WhiteNoise can serve media files in production
# Add media files to WhiteNoise configuration
WHITENOISE_USE_FINDERS = True
WHITENOISE_AUTOREFRESH = True

# CORS Configuration for Production
CORS_ALLOW_ALL_ORIGINS = False
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",  # Flutter web dev
    "http://127.0.0.1:3000",
    "http://192.168.1.7:3000",
    "https://yourdomain.com",  # Production domain
    # Add Netlify domains for web deployment
    "https://*.netlify.app",  # All Netlify apps
    "https://shiny-chebakia-43b733.netlify.app",  # Specific Netlify domain
]

# Temporarily allow all origins for Netlify deployment
# You can restrict this later by adding your specific Netlify URL
CORS_ALLOW_ALL_ORIGINS = True

CORS_ALLOW_CREDENTIALS = True
CORS_PREFLIGHT_MAX_AGE = 86400  # 24 hours

# Temporary: Allow all headers to prevent CORS issues during development
CORS_ALLOW_ALL_HEADERS = True

# Additional CORS settings for web compatibility - comprehensive header list
CORS_ALLOW_HEADERS = [
    'accept',
    'accept-encoding',
    'accept-language',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
    'x-request-id',  # Fix for x-request-id CORS error
    'access-control-allow-origin',
    'access-control-allow-methods',
    'access-control-allow-headers',
    'strict-transport-security',  # Fix for Netlify CORS error
    'sec-fetch-site',
    'sec-fetch-mode',
    'sec-fetch-dest',
    'sec-ch-ua',
    'sec-ch-ua-mobile',
    'sec-ch-ua-platform',
    'referer',
    'cache-control',
    'pragma',
    'expires',
    'if-modified-since',
    'if-none-match',
    'range',
    'x-forwarded-for',
    'x-forwarded-proto',
    'x-real-ip',
]

CORS_ALLOW_METHODS = [
    'DELETE',
    'GET',
    'OPTIONS',
    'PATCH',
    'POST',
    'PUT',
]

# Email Configuration for Production
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = config('EMAIL_HOST', default='smtp.gmail.com')
EMAIL_PORT = config('EMAIL_PORT', default=587, cast=int)
EMAIL_USE_TLS = True
EMAIL_HOST_USER = config('EMAIL_HOST_USER', default='')
EMAIL_HOST_PASSWORD = config('EMAIL_HOST_PASSWORD', default='')

# Sentry Configuration for Error Monitoring (Optional)
# Only initialize Sentry if DSN is provided
SENTRY_DSN = config('SENTRY_DSN', default='')
if SENTRY_DSN:
    import sentry_sdk
    from sentry_sdk.integrations.django import DjangoIntegration
    from sentry_sdk.integrations.redis import RedisIntegration

    sentry_sdk.init(
        dsn=SENTRY_DSN,
        integrations=[
            DjangoIntegration(),  # Removed auto_enabling parameter
            RedisIntegration(),
        ],
        traces_sample_rate=0.1,  # 10% of transactions for performance monitoring
        send_default_pii=False,
        environment=config('ENVIRONMENT', default='production'),
    )

# Performance Optimization Settings
USE_TZ = True
USE_I18N = False  # Disable if not needed
USE_L10N = False  # Disable if not needed

# Database Query Optimization
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# Add performance monitoring middleware (disabled for Railway)
# MIDDLEWARE.insert(0, 'silk.middleware.SilkyMiddleware')

# Celery Configuration disabled for Railway (no Redis)
# CELERY_BROKER_URL = 'redis://127.0.0.1:6379/3'
# CELERY_RESULT_BACKEND = 'redis://127.0.0.1:6379/3'

# Add new apps for production (minimal for Railway)
INSTALLED_APPS += [
    'rest_framework_simplejwt',
    'drf_spectacular',  # API documentation
]

# Redis not used - using local memory cache instead

# API Documentation
SPECTACULAR_SETTINGS = {
    'TITLE': 'Gym Management API',
    'DESCRIPTION': 'Enterprise-level gym management system API',
    'VERSION': '1.0.0',
    'SERVE_INCLUDE_SCHEMA': False,
}

# Google OAuth 2.0 settings for production
try:
    print("🔧 PRODUCTION_SETTINGS: Loading Google OAuth environment variables...")
    GOOGLE_OAUTH2_CLIENT_ID = os.getenv('GOOGLE_OAUTH2_CLIENT_ID')
    GOOGLE_OAUTH2_CLIENT_SECRET = os.getenv('GOOGLE_OAUTH2_CLIENT_SECRET')
    print(f"🔑 PRODUCTION_SETTINGS: GOOGLE_OAUTH2_CLIENT_ID = {GOOGLE_OAUTH2_CLIENT_ID}")
    print(f"🔑 PRODUCTION_SETTINGS: Environment variables loaded = {bool(GOOGLE_OAUTH2_CLIENT_ID)}")
    print(f"🚀 PRODUCTION_SETTINGS: Production deployment timestamp: July 16, 2025 - 17:30 IST")
    
    # Ensure they exist as module attributes
    globals()['GOOGLE_OAUTH2_CLIENT_ID'] = GOOGLE_OAUTH2_CLIENT_ID
    globals()['GOOGLE_OAUTH2_CLIENT_SECRET'] = GOOGLE_OAUTH2_CLIENT_SECRET
    print("✅ PRODUCTION_SETTINGS: Google OAuth settings configured successfully")
except Exception as e:
    print(f"❌ PRODUCTION_SETTINGS: Error configuring Google OAuth: {e}")
    GOOGLE_OAUTH2_CLIENT_ID = None
    GOOGLE_OAUTH2_CLIENT_SECRET = None