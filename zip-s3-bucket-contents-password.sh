#!/bin/bash

BUCKET_NAME="childrens-health-care-results"
PREFIX=""               # Optional: set to a folder/prefix, e.g., "reports/"
ZIP_NAME="s3_backup_$(date +%Y%m%d_%H%M%S).zip"
DOWNLOAD_DIR="./s3_download"

mkdir -p "$DOWNLOAD_DIR"
echo "📥 Downloading files from s3://$BUCKET_NAME/$PREFIX..."
aws s3 cp "s3://$BUCKET_NAME/$PREFIX" "$DOWNLOAD_DIR" --recursive

echo "🔐 Creating password-protected ZIP archive: $ZIP_NAME"
zip -re "$ZIP_NAME" "$DOWNLOAD_DIR"

echo "✅ Done! Password-protected ZIP file created: $ZIP_NAME"