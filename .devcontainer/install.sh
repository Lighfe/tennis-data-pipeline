#!/bin/bash
set -e

# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install gcloud via apt
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /tmp/cloud.google.gpg
sudo cp /tmp/cloud.google.gpg /usr/share/keyrings/cloud.google.gpg
echo 'deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main' | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
sudo apt-get update
sudo apt-get install -y google-cloud-cli