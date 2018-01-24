#!/bin/bash

# terminate script as soon as any command fails
set -e

if [[ -z "$APP" ]]; then
  echo "Missing APP variable which must be set to the name of your app where the db is located"
  exit 1
fi

if [[ -z "$DATABASE" ]]; then
  echo "Missing DATABASE variable which must be set to the name of the DATABASE you would like to backup"
  exit 1
fi

if [[ -z "$S3_BUCKET_PATH" ]]; then
  echo "Missing S3_BUCKET_PATH variable which must be set the directory in s3 where you would like to store your database backups"
  exit 1
fi

if [[ -z "$SKIP_RUN_BACKUP" ]]; then
	heroku pg:backups capture $DATABASE --app $APP
fi

BACKUP_SOURCE_URL=`heroku pg:backups:url --app $APP`
BACKUP_DATE_TIME="$(echo $BACKUP_SOURCE_URL | cut -d/ -f5 | perl -pe 's/%3A/-/g')"

BACKUP_FILE_NAME="$BACKUP_DATE_TIME.dump"

curl -o $BACKUP_FILE_NAME $BACKUP_SOURCE_URL
FINAL_FILE_NAME=$BACKUP_FILE_NAME

if [[ -z "$NOGZIP" ]]; then
  gzip $BACKUP_FILE_NAME
  FINAL_FILE_NAME=$BACKUP_FILE_NAME.gz
fi

aws s3 cp $FINAL_FILE_NAME s3://$S3_BUCKET_PATH/$APP/$DATABASE/$FINAL_FILE_NAME

# no need to worry about deleting the local datbase backup file - the dyno (and its storage) will be destroyed on completion

echo "backup $FINAL_FILE_NAME complete"
