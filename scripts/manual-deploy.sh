#!/usr/bin/env bash
# PART 1: manual deployment as the 'ubuntu' user (before Jenkins takes over).
# Edit the two repo URLs first.
set -euo pipefail

FLASK_REPO="https://github.com/azhar9983/flask-backend.git"
EXPRESS_REPO="https://github.com/azhar9983/express-frontend.git"

mkdir -p ~/apps && cd ~/apps
git clone "$FLASK_REPO" flask-backend
git clone "$EXPRESS_REPO" express-frontend

# Flask
cd ~/apps/flask-backend
python3 -m venv venv
venv/bin/pip install -r requirements.txt
pm2 start ecosystem.config.js

# Express
cd ~/apps/express-frontend
npm install
pm2 start ecosystem.config.js

pm2 save
pm2 status
echo "Flask:   http://<EC2-PUBLIC-IP>:5000/health"
echo "Express: http://<EC2-PUBLIC-IP>:3000"
