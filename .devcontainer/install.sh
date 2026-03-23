#!/bin/bash
set -e

# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install gcloud via apt
rm -f /tmp/cloud.google.gpg
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --yes --dearmor -o /tmp/cloud.google.gpg
cp /tmp/cloud.google.gpg /usr/share/keyrings/cloud.google.gpg
echo 'deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main' | tee /etc/apt/sources.list.d/google-cloud-sdk.list
apt-get update
apt-get install -y google-cloud-cli

# Authenticate with GCP
if [ -n "$GOOGLE_APPLICATION_CREDENTIALS_JSON" ]; then
    echo "$GOOGLE_APPLICATION_CREDENTIALS_JSON" > /tmp/gcp-key.json
    gcloud auth activate-service-account --key-file=/tmp/gcp-key.json
    gcloud config set project "$(echo "$GOOGLE_APPLICATION_CREDENTIALS_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['project_id'])")"
else
    echo "WARNING: GOOGLE_APPLICATION_CREDENTIALS_JSON secret not set. Skipping GCP authentication."
    echo "See README.md Step 4 for instructions."
fi