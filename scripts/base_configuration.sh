#! /bin/bash

# Base configuration
sudo sed -i 's/#Port 22/Port 42069/g' /etc/ssh/sshd_config
sudo systemctl restart sshd

sudo apt update
sudo apt install -y curl openssh-server ca-certificates tzdata perl


# Install GitLab Omnibus
curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash
sudo EXTERNAL_URL="${EXTERNAL_URL}" GITLAB_ROOT_PASSWORD="${GITLAB_ROOT_PASSWORD}" apt install gitlab-ee


# Install GitLab Runner
curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash
sudo apt install -y gitlab-runner


# Register GitLab Runner
REGISTRATION_TOKEN=$(sudo gitlab-rails runner -e production "puts Gitlab::CurrentSettings.current_application_settings.runners_registration_token")

sudo sed -i 's/concurrent.*/concurrent = 10/' /etc/gitlab-runner/config.toml
sudo gitlab-runner register --url "${EXTERNAL_URL}" \
    --registration-token "$REGISTRATION_TOKEN" \
    --non-interactive \
    --executor docker \
    --description "docker-runner" \
    --tag-list "shell,linux,xenial,ubuntu,docker" \
    --run-untagged \
    --locked="false" \
    --access-level="not_protected" \
    --docker-image "alpine:latest"

# Install Docker 
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg lsb-release
    
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker gitlab-runner
