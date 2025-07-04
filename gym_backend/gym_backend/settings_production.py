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

# Railway provides DATABASE_URL automatically
DATABASE_URL = os.environ.get('DATABASE_URL')

if DATABASE_URL:
    # Use Railway's DATABASE_URL
    DATABASES = {
        'default': dj_database_url.config(
            default=DATABASE_URL,
            conn_max_age=300,
            conn_health_checks=True,
        )
    }
else:
    # Fallback to SQLite for local development
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': BASE_DIR / 'db.sqlite3',
        }
    }

# Redis Cache Configuration (Optional - fallback to database cache)
REDIS_URL = config('REDIS_URL', default='')
if REDIS_URL:
    # Use Redis if available
    CACHES = {
        'default': {
            'BACKEND': 'django_redis.cache.RedisCache',
            'LOCATION': REDIS_URL,
            'OPTIONS': {
                'CLIENT_CLASS': 'django_redis.client.DefaultClient',
                'CONNECTION_POOL_KWARGS': {
                    'max_connections': 50,
                    'retry_on_timeout': True,
                },
                'SERIALIZER': 'django_redis.serializers.json.JSONSerializer',
                'COMPRESSOR': 'django_redis.compressors.zlib.ZlibCompressor',
            },
            'KEY_PREFIX': 'gym_app',
            'TIMEOUT': 300,  # 5 minutes default timeout
        },
    }
    # Use Redis for session storage
    SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
    SESSION_CACHE_ALIAS = 'default'
else:
    # Fallback to database cache
    CACHES = {
        'default': {
            'BACKEND': 'django.core.cache.backends.db.DatabaseCache',
            'LOCATION': 'cache_table',
        }
    }
    # Use database for session storage
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
        'rest_framework_simplejwt.authentication.JWTAuthentication',
        'rest_framework.authentication.TokenAuthentication',
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

MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

# CORS Configuration for Production
CORS_ALLOW_ALL_ORIGINS = False
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",  # Flutter web dev
    "http://127.0.0.1:3000",
    "http://192.168.1.7:3000",
    "https://yourdomain.com",  # Production domain
]

CORS_ALLOW_CREDENTIALS = True
CORS_PREFLIGHT_MAX_AGE = 86400  # 24 hours

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

# Celery Configuration for Async Tasks (if needed)
CELERY_BROKER_URL = config('REDIS_URL', default='redis://127.0.0.1:6379/3')
CELERY_RESULT_BACKEND = config('REDIS_URL', default='redis://127.0.0.1:6379/3')
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_TIMEZONE = 'UTC'

# Add new apps for production (minimal for Railway)
INSTALLED_APPS += [
    'rest_framework_simplejwt',
    'drf_spectacular',  # API documentation
]

# Add Redis app only if Redis is available
if REDIS_URL:
    INSTALLED_APPS.append('django_redis')

# API Documentation
SPECTACULAR_SETTINGS = {
    'TITLE': 'Gym Management API',
    'DESCRIPTION': 'Enterprise-level gym management system API',
    'VERSION': '1.0.0',
    'SERVE_INCLUDE_SCHEMA': False,
}