import os
import ssl
import urllib.parse
from pathlib import Path
from datetime import timedelta
import dotenv

BASE_DIR = Path(__file__).resolve().parent.parent

# Load environment variables
dotenv.load_dotenv(BASE_DIR / '.env')

SECRET_KEY = os.getenv('SECRET_KEY', 'duo-super-secret-key-change-in-production-12345')

DEBUG = os.getenv('DEBUG', 'True') == 'True'

ALLOWED_HOSTS = [
    h.strip()
    for h in os.getenv('ALLOWED_HOSTS', '.onrender.com,localhost,127.0.0.1,*').split(',')
    if h.strip()
]

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',

    # Third-party
    'corsheaders',
    'rest_framework',
    'rest_framework_simplejwt',
    'rest_framework_simplejwt.token_blacklist',

    # Duo Modular Apps
    'apps.accounts',
    'apps.connections',
    'apps.expenses',
    'apps.budgets',
    'apps.tasks',
    'apps.notifications',
]

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

try:
    import whitenoise  # noqa: F401
    MIDDLEWARE.insert(2, 'whitenoise.middleware.WhiteNoiseMiddleware')
    STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'
except ImportError:
    pass

ROOT_URLCONF = 'duo_backend.urls'

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

WSGI_APPLICATION = 'duo_backend.wsgi.application'

# Database Configuration (supports TiDB Cloud, MySQL, DATABASE_URL, or SQLite fallback)
DATABASE_URL = os.getenv('DATABASE_URL')
DB_ENGINE = os.getenv('DB_ENGINE', 'mysql').lower()
DB_SSL = os.getenv('DB_SSL', 'False').lower() in ('true', '1', 'yes')

def _build_mysql_options(host='', port='3306', force_ssl=False):
    opts = {
        'charset': 'utf8mb4',
        'init_command': "SET sql_mode='STRICT_TRANS_TABLES'",
    }
    # TiDB Cloud Serverless/Starter mandates SSL/TLS connections on port 4000 or *.tidbcloud.com
    is_tidb = 'tidbcloud.com' in str(host).lower() or str(port) == '4000'
    if force_ssl or is_tidb:
        ssl_ctx = ssl.create_default_context()
        ca_path = os.getenv('DB_SSL_CA')
        if ca_path and os.path.exists(ca_path):
            ssl_ctx.load_verify_locations(cafile=ca_path)
        opts['ssl'] = ssl_ctx
    return opts

if DATABASE_URL:
    parsed_db_url = urllib.parse.urlparse(DATABASE_URL)
    is_mysql = 'mysql' in parsed_db_url.scheme
    db_host = parsed_db_url.hostname or '127.0.0.1'
    db_port = str(parsed_db_url.port or (4000 if 'tidb' in db_host else 3306))
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.mysql' if is_mysql else 'django.db.backends.sqlite3',
            'NAME': parsed_db_url.path.lstrip('/') if is_mysql else (BASE_DIR / 'db.sqlite3'),
            'USER': urllib.parse.unquote(parsed_db_url.username or '') if parsed_db_url.username else '',
            'PASSWORD': urllib.parse.unquote(parsed_db_url.password or '') if parsed_db_url.password else '',
            'HOST': db_host,
            'PORT': db_port,
            'OPTIONS': _build_mysql_options(db_host, db_port, DB_SSL) if is_mysql else {},
        }
    }
elif DB_ENGINE == 'mysql':
    db_host = os.getenv('DB_HOST', '127.0.0.1')
    db_port = os.getenv('DB_PORT', '3306')
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.mysql',
            'NAME': os.getenv('DB_NAME', 'duo_db'),
            'USER': os.getenv('DB_USER', 'root'),
            'PASSWORD': os.getenv('DB_PASSWORD', ''),
            'HOST': db_host,
            'PORT': db_port,
            'OPTIONS': _build_mysql_options(db_host, db_port, DB_SSL),
        }
    }
else:
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': BASE_DIR / 'db.sqlite3',
        }
    }

# Custom User Model (Requirement 1)
AUTH_USER_MODEL = 'accounts.User'

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

# Business Rule: Timezone Asia/Kolkata & Currency INR
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'Asia/Kolkata'
USE_I18N = True
USE_TZ = True

STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# REST Framework Configuration
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    ),
}

# Simple JWT Configuration
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(days=30),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=90),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'AUTH_HEADER_TYPES': ('Bearer',),
}

# CORS Configuration
CORS_ALLOW_ALL_ORIGINS = DEBUG
if not DEBUG:
    CORS_ALLOWED_ORIGINS = [
        o.strip() for o in os.getenv('CORS_ALLOWED_ORIGINS', 'http://localhost:3000,http://127.0.0.1:3000').split(',') if o.strip()
    ]
CORS_ALLOW_CREDENTIALS = True

# Production Security Headers
if not DEBUG:
    SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
    SECURE_SSL_REDIRECT = os.getenv('SECURE_SSL_REDIRECT', 'False') == 'True'
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_BROWSER_XSS_FILTER = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
    X_FRAME_OPTIONS = 'DENY'

# Logging
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
            'class': 'logging.StreamHandler',
            'formatter': 'simple',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': os.getenv('DJANGO_LOG_LEVEL', 'INFO'),
    },
}
