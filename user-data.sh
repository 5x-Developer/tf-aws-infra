#!/bin/bash

# This script runs when the EC2 instance first boots
# It configures the database and starts the application

set -e

echo "=========================================="
echo "EC2 Instance Initialization" - "RDS Configuration"
echo "=========================================="

# Database Configuration
DB_ENDPOINT="${db_endpoint}"
DB_NAME="${db_name}"
DB_USER="${db_user}"
DB_PASSWORD="${db_password}"
S3_BUCKET_NAME="${s3_bucket_name}"

# Create .env file with application secrets
echo "Creating environment configuration for RDS..."
cat > /opt/csye6225/.env << EOF
SPRING_DATASOURCE_URL=jdbc:mysql://$${DB_ENDPOINT}:3306/$${DB_NAME}
SPRING_DATASOURCE_USERNAME=$${DB_USER}
SPRING_DATASOURCE_PASSWORD=$${DB_PASSWORD}
SERVER_PORT=8080
SPRING_JPA_HIBERNATE_DDL_AUTO=update
SPRING_JPA_SHOW_SQL=false
LOGGING_LEVEL_ROOT=INFO
LOGGING_FILE_NAME=/opt/csye6225/logs/application.log
AWS_S3_BUCKET_NAME=$${S3_BUCKET_NAME}
EOF

# Set proper permissions
sudo chown csye6225:csye6225 /opt/csye6225/.env
sudo chmod 600 /opt/csye6225/.env

echo "Environment file created with RDS connection details"

# Restart the application service to pick up new configuration
echo "Restarting application service..."
systemctl restart csye6225.service

# Wait a bit for service to start
sleep 10

# Check if application started successfully
if systemctl is-active --quiet csye6225.service; then
    echo "Application started successfully and connected to RDS!"
else
    echo "Application failed to start!"
    journalctl -u csye6225.service -n 50
    exit 1
fi

echo "=========================================="
echo "Instance Initialization Complete!"
echo "=========================================="