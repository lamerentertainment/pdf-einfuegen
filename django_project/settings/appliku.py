"""
Production Settings for Appliku
"""


# If using in your own project, update the project namespace below
from django_project.settings.base import *
import environ

env = environ.Env(
    # set casting, default value
    DEBUG=(bool, False)
)

DJANGO_SETTINGS_MODULE = env("DJANGO_SETTINGS_MODULE")

DEBUG = env.bool("DJANGO_DEBUG", False)
# Allowed Hosts Definition
if DEBUG:
    # If Debug is True, allow all.
    ALLOWED_HOSTS = ['*']
else:
    ALLOWED_HOSTS = env.list('DJANGO_ALLOWED_HOSTS', default=['.applikuapps.com', 'einfuegen.ch', 'text.einfuegen.ch'])

SECRET_KEY = env('DJANGO_SECRET_KEY')

# False if not in os.environ
DEBUG = env('DEBUG')


# Parse database connection url strings like psql://user:pass@127.0.0.1:8458/db
DATABASES = {
    # read os.environ['DATABASE_URL'] and raises ImproperlyConfigured exception if not found
    'default': env.db(),
}

# hinzugefügt für whitenoise
STATIC_ROOT = BASE_DIR / 'staticfiles'