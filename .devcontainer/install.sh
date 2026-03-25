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
echo 'source /workspaces/tennis-data-pipeline/.devcontainer/auth.sh' >> ~/.bash_profile