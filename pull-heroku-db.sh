#!/bin/bash
# Restore heroku postgres database to local database for development

heroku pgbackups:capture
curl -o latest.dump `heroku pgbackups:url`
pg_restore --verbose --clean --no-acl --no-owner -h localhost -U postgres -d southwest-checkin latest.dump
