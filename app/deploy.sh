#!/bin/bash
set -e

APP_DIR="/opt/devops-app"
SERVICE_NAME="devops-webapp"

echo "=== [1/5] Updating packages and installing prerequisites ==="
sudo apt-get update -y
sudo apt-get install -y python3 python3-pip python3-venv

echo "=== [2/5] Setting up target application directory: ${APP_DIR} ==="
sudo mkdir -p ${APP_DIR}
sudo chown -R $USER:$USER ${APP_DIR}

# Copy newly uploaded app files into target directory
cp -r ./* ${APP_DIR}/

echo "=== [3/5] Setting up Python virtual environment ==="
cd ${APP_DIR}
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo "=== [4/5] Creating / updating systemd service ==="
sudo bash -c "cat <<EOF > /etc/systemd/system/${SERVICE_NAME}.service
[Unit]
Description=Gunicorn instance to serve DevOps Flask Web App
After=network.target

[Service]
User=root
WorkingDirectory=${APP_DIR}
Environment=\"PATH=${APP_DIR}/venv/bin\"
Environment=\"PORT=80\"
Environment=\"APP_ENV=Production-Azure\"
ExecStart=${APP_DIR}/venv/bin/gunicorn --workers 3 --bind 0.0.0.0:80 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF"

echo "=== [5/5] Reloading and restarting systemd service ==="
sudo systemctl daemon-reload
sudo systemctl enable ${SERVICE_NAME}
sudo systemctl restart ${SERVICE_NAME}

echo "=== Deployment Completed Successfully! ==="
sudo systemctl status ${SERVICE_NAME} --no-pager
