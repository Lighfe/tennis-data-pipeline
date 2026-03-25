#!/bin/bash
# Run this after a Codespace restart (not needed after a full rebuild)

echo "$GOOGLE_APPLICATION_CREDENTIALS_JSON" > /tmp/gcp-key.json
export GOOGLE_APPLICATION_CREDENTIALS=/tmp/gcp-key.json
gcloud auth activate-service-account --key-file=/tmp/gcp-key.json
gcloud config set project "$(echo "$GOOGLE_APPLICATION_CREDENTIALS_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['project_id'])")"
echo "GCP authentication complete."