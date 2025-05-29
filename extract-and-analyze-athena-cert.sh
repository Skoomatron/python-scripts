#!/bin/bash

# Usage: ./analyze-cert.sh "BASE64_STRING" [filename.cer]

CERT_BODY=""
OUTPUT_FILE="${2:-cert-extracted.cer}"  # default name

if [ -z "$CERT_BODY" ]; then
  echo "❌ Error: No certificate body provided."
  echo "Usage: $0 \"<base64-cert-string>\" [output_file.cer]"
  exit 1
fi

# Format and write the certificate
{
  echo "-----BEGIN CERTIFICATE-----"
  echo "$CERT_BODY" | fold -w 64
  echo "-----END CERTIFICATE-----"
} > "$OUTPUT_FILE"

# Extract minimal info from cert
echo "🔍 Certificate Info: $OUTPUT_FILE"
keytool -printcert -file "$OUTPUT_FILE" | grep -E "Owner:|Issuer:|Valid from:"
