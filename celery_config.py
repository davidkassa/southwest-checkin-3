from settings import Config
config = Config()

CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_TIMEZONE = 'US/Central'
CELERY_REDIS_MAX_CONNECTIONS=2

if config["HEROKU_DB"]:
  import os
  url = os.environ.get('BROKER_URL')
else:
  url = 'redis://localhost:6379/0'

BROKER_URL = url
CELERY_RESULT_BACKEND = url

