#to be installed on EC2 instance
#either run this script or run the commands manually


#!/usr/bin/env bash
# One-time EC2 setup (Ubuntu 26.04). Run as the default 'ubuntu' user:
#   chmod +x setup-ec2.sh && ./setup-ec2.sh
set -euo pipefail

echo "==> Updating packages"
sudo apt update
sudo apt install -y python3 python3-venv python3-pip git curl rsync ca-certificates gnupg -y 

echo "==> Installing Node.js 26 and pm2"
# Download and install nvm:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.41.0/install.sh | bash

# in lieu of restarting the shell
\. "$HOME/.nvm/nvm.sh"

# Download and install Node.js:
nvm install 26

# Verify the Node.js version:
node -v # Should print "v26.13.1".

# Verify npm version:
npm -v # Should print "11.20.0".

npm install -g pm2

sudo apt update
sudo apt install fontconfig openjdk-21-jre -y
java -version

sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install jenkins -y
sudo systemctl enable --now jenkins


# Make Node.js and PM2 available to the Jenkins service account.
sudo ln -sf "$(command -v node)" /usr/local/bin/node
sudo ln -sf "$(command -v pm2)" /usr/local/bin/pm2

sudo chmod o+x /home/ubuntu
sudo chmod -R o+rX /home/ubuntu/.nvm
sudo ln -sf /home/ubuntu/.nvm/versions/node/v26.13.1/bin/node /usr/local/bin/node
sudo ln -sf /home/ubuntu/.nvm/versions/node/v26.13.1/bin/npm  /usr/local/bin/npm
sudo ln -sf /home/ubuntu/.nvm/versions/node/v26.13.1/bin/pm2   /usr/local/bin/pm2
sudo systemctl restart jenkins





echo "==> Creating deploy directory owned by jenkins"
sudo mkdir -p /opt/apps
sudo chown -R jenkins:jenkins /opt/apps

echo
echo "Done. Jenkins initial admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
echo "Open http://<ec2-PUBLIC_IP>:8080 (allow port 8080 in the security group)."
