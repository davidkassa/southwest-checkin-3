from settings import Config
config = Config()

CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_TIMEZONE = 'US/Central'
# CELERY_ENABLE_UTC = True

### Redis ###

if config["HEROKU_DB"]:
  import os
  url = os.environ.get('REDISCLOUD_URL')
else:
  url = 'redis://localhost:6379/0'

BROKER_URL = url
CELERY_RESULT_BACKEND = url

### Database ###

CELERY_RESULT_BACKEND = "database"
if config["HEROKU_DB"]:
  import os
  BROKER_URL          = 'sqla+postgresql://' + os.environ.get('DATABASE_URL')
  CELERY_RESULT_DBURI = 'postgresql://' + os.environ.get('DATABASE_URL')
# else:
  # BROKER_URL          = 'sqla+sqlite:///' + config["SQLITE_DB"]
  # CELERY_RESULT_DBURI = 'sqlite:///' + config["SQLITE_DB"]
#
# CELERY_RESULT_ENGINE_OPTIONS = {"echo": True}
