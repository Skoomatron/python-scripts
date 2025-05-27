#!/bin/bash

BUCKET_NAME="childrens-health-care-results"
SUB_DIRECTORY="AllZipped"
FILE_NAME="s3_backup_20250328_102026.zip"
REGION="us-east-1"

aws s3 presign s3://$BUCKET_NAME/$SUB_DIRECTORY/$FILE_NAME --region $REGION --expires-in 21600
