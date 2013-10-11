celery: celery -A tasks worker --loglevel=info
flower: celery flower --broker=$BROKER_URL
web: newrelic-admin run-program gunicorn -b "0.0.0.0:$PORT" server:app