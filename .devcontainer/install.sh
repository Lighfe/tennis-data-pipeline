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

# Run auth (also registers it to run on every Codespace login)
bash /workspaces/tennis-data-pipeline/.devcontainer/auth.sh
echo 'export DOCKER_API_VERSION=1.43' >> ~/.bashrc
echo 'export PATH="/workspaces/tennis-data-pipeline/.venv/bin:$PATH"' >> ~/.bashrc
if [ -n "$CODESPACE_NAME" ]; then
    echo "AIRFLOW__WEBSERVER__BASE_URL=https://${CODESPACE_NAME}-8080.app.github.dev" >> /workspaces/tennis-data-pipeline/airflow/.env
fi
echo 'source /workspaces/tennis-data-pipeline/.devcontainer/auth.sh' >> ~/.bashrc