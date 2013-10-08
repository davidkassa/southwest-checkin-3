from tasks import *
from datetime import datetime, timedelta

tomorrow = datetime.now() + timedelta(days=1)
test_celery.apply_async([2], eta=tomorrow)

