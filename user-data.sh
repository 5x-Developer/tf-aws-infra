#!/bin/bash

# This script runs when the EC2 instance first boots
# It configures the database and starts the application

set -e

echo "=========================================="
echo "EC2 Instance Initialization"
echo "=========================================="

# Database Configuration
DB_NAME="${db_name}"
DB_USER="${db_user}"
DB_PASSWORD="${db_password}"

# Create .env file with application secrets
echo "Creating environment configuration..."
cat > /opt/csye6225/.env << EOF
SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/$${DB_NAME}
SPRING_DATASOURCE_USERNAME=$${DB_USER}
SPRING_DATASOURCE_PASSWORD=$${DB_PASSWORD}
SERVER_PORT=8080
SPRING_JPA_HIBERNATE_DDL_AUTO=update
SPRING_JPA_SHOW_SQL=false
LOGGING_LEVEL_ROOT=INFO
LOGGING_FILE_NAME=/opt/csye6225/logs/application.log
EOF

# Set proper permissions
sudo chown csye6225:csye6225 /opt/csye6225/.env
sudo chmod 600 /opt/csye6225/.env

# Configure MySQL database
echo "Configuring MySQL database..."
sudo mysql -u root -ptemporary_password << MYSQL_EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$${DB_PASSWORD}';
CREATE DATABASE IF NOT EXISTS $${DB_NAME};
CREATE USER IF NOT EXISTS '$${DB_USER}'@'localhost' IDENTIFIED BY '$${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON $${DB_NAME}.* TO '$${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
MYSQL_EOF

# Wait for database to be ready
sleep 5

# Start the application
echo "Starting application service..."
sudo systemctl start csye6225.service

# Check if application started successfully
sleep 10
if sudo systemctl is-active --quiet csye6225.service; then
    echo "Application started successfully!"
else
    echo "Application failed to start!"
    sudo journalctl -u csye6225.service -n 50
    exit 1
fi

echo "=========================================="
echo "Instance Initialization Complete!"
echo "=========================================="