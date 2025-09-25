#!/bin/bash

yum update -y
yum install -y awscli

BUCKET_NAME="${bucket_name}"
APP_LOG_PATH="/var/app/logs"
SYSTEM_LOG="/var/log/cloud-init.log"

# Create upload script
cat <<EOF > /opt/upload_logs_on_shutdown.sh
#!/bin/bash
aws s3 cp ${SYSTEM_LOG} s3://${bucket_name}/logs/cloud-init.log
aws s3 cp --recursive ${APP_LOG_PATH} s3://${bucket_name}/logs/app/
EOF

chmod +x /opt/upload_logs_on_shutdown.sh

# Create systemd service
cat <<EOF > /etc/systemd/system/log-upload-on-shutdown.service
[Unit]
Description=Upload logs to S3 on shutdown
DefaultDependencies=no
After=network.target

[Service]
Type=oneshot
ExecStart=/opt/upload_logs_on_shutdown.sh
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

systemctl enable log-upload-on-shutdown.service
