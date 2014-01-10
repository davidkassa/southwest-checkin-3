# psql -d southwest_checkin
# heroku pg:psql
ALTER TABLE flight ADD COLUMN task_uuid text;