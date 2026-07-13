from pathlib import Path
from decouple import config, Csv
from datetime import timedelta

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = config('SECRET_KEY', default='django-insecure-dev-key-change-in-production-abc123')
DEBUG      = config('DEBUG', default=True, cast=bool)
ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='localhost,127.0.0.1,10.0.2.2', cast=Csv())

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
    'django_filters',
    'drf_spectacular',
    'api',
]

AUTH_USER_MODEL = 'api.User'

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'backend_django.urls'
WSGI_APPLICATION = 'backend_django.wsgi.application'

TEMPLATES = [{
    'BACKEND': 'django.template.backends.django.DjangoTemplates',
    'DIRS': [BASE_DIR / 'templates'],
    'APP_DIRS': True,
    'OPTIONS': {'context_processors': [
        'django.template.context_processors.debug',
        'django.template.context_processors.request',
        'django.contrib.auth.context_processors.auth',
        'django.contrib.messages.context_processors.messages',
    ]},
}]

DATABASES = {
    'default': {
        'ENGINE':   'django.db.backends.sqlite3',
        'NAME':     BASE_DIR / 'db.sqlite3',
    }
}

# Upgrade to PostgreSQL by setting these env vars (or DATABASE_URL)
import os
_db_url = os.environ.get('DATABASE_URL')
if _db_url:
    import dj_database_url
    DATABASES['default'] = dj_database_url.parse(_db_url, conn_max_age=60)
else:
    _pg_name = config('DB_NAME', default='')
    if _pg_name:
        DATABASES = {
            'default': {
                'ENGINE':   'django.db.backends.postgresql',
                'NAME':     _pg_name,
                'USER':     config('DB_USER',     default='postgres'),
                'PASSWORD': config('DB_PASSWORD', default=''),
                'HOST':     config('DB_HOST',     default='localhost'),
                'PORT':     config('DB_PORT',     default='5432'),
                'CONN_MAX_AGE': 60,
                'OPTIONS': {'connect_timeout': 5},
            }
        }

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator', 'OPTIONS': {'min_length': 8}},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': ['rest_framework.permissions.IsAuthenticated'],
    'DEFAULT_FILTER_BACKENDS': [
        'django_filters.rest_framework.DjangoFilterBackend',
        'rest_framework.filters.OrderingFilter',
    ],
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 30,
    'DEFAULT_SCHEMA_CLASS': 'drf_spectacular.openapi.AutoSchema',
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.AnonRateThrottle',
        'rest_framework.throttling.UserRateThrottle',
    ],
    'DEFAULT_THROTTLE_RATES': {'anon': '50/hour', 'user': '500/hour'},
}

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME':  timedelta(days=1),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=30),
    'ROTATE_REFRESH_TOKENS':  True,
    'AUTH_HEADER_TYPES': ('Bearer', 'Token'),
}

CORS_ALLOWED_ORIGINS = config(
    'CORS_ALLOWED_ORIGINS',
    default='http://localhost:8000,http://127.0.0.1:8000,http://10.0.2.2:8000',
    cast=Csv(),
)
CORS_ALLOW_CREDENTIALS = True

SPECTACULAR_SETTINGS = {
    'TITLE': 'Smart Fish Feeder API',
    'DESCRIPTION': 'REST API for the IoT Smart Fish Feeder — Arduino + ESP8266 + Django + Flutter.',
    'VERSION': '1.0.0',
    'SERVE_INCLUDE_SCHEMA': False,
}

LANGUAGE_CODE = 'en-us'
TIME_ZONE     = 'Africa/Kampala'
USE_I18N = USE_TZ = True
STATIC_URL  = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
MEDIA_URL   = '/media/'
MEDIA_ROOT  = BASE_DIR / 'media'
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
