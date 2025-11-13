#!/bin/bash

# This script runs when the EC2 instance first boots
# It configures the database and starts the application

set -e

echo "=========================================="
echo "EC2 Instance Initialization" - "RDS Configuration"
echo "=========================================="

# Fetch database credentials from Secrets Manager instead of template variables
DB_SECRET_ARN="${db_secret_arn}"
S3_BUCKET_NAME="${s3_bucket_name}"
REGION="${aws_region}"
SNS_TOPIC_ARN="${sns_topic_arn}"
LOG_GROUP_NAME="${log_group_name}"

echo "Region: $REGION"
echo "S3 Bucket: $S3_BUCKET_NAME"
echo "SNS Topic: $SNS_TOPIC_ARN"
echo "Fetching database credentials from Secrets Manager..."

# Install jq for JSON parsing if not already installed
if ! command -v jq &> /dev/null; then
    echo "Installing jq..."
    sudo apt-get update
    sudo apt-get install -y jq
fi

# Fetch and parse database credentials from Secrets Manager
DB_SECRET=$(aws secretsmanager get-secret-value \
    --region $REGION \
    --secret-id $DB_SECRET_ARN \
    --query SecretString \
    --output text)

# Parse the JSON secret
DB_ENDPOINT=$(echo $DB_SECRET | jq -r '.host')
DB_PORT=$(echo $DB_SECRET | jq -r '.port')
DB_NAME=$(echo $DB_SECRET | jq -r '.dbname')
DB_USER=$(echo $DB_SECRET | jq -r '.username')
DB_PASSWORD=$(echo $DB_SECRET | jq -r '.password')

echo "✓ Database credentials retrieved from Secrets Manager"
echo "DB Endpoint: $DB_ENDPOINT"
echo "DB Port: $DB_PORT"
echo "DB Name: $DB_NAME"

# Create .env file with application secrets
echo "Creating environment configuration for RDS..."
cat > /opt/csye6225/.env << EOF
SPRING_DATASOURCE_URL=jdbc:mysql://$${DB_ENDPOINT}:$${DB_PORT}/$${DB_NAME}
SPRING_DATASOURCE_USERNAME=$${DB_USER}
SPRING_DATASOURCE_PASSWORD=$${DB_PASSWORD}
SERVER_PORT=8080
SPRING_JPA_HIBERNATE_DDL_AUTO=update
SPRING_JPA_SHOW_SQL=false
LOGGING_LEVEL_ROOT=INFO
LOGGING_FILE_NAME=/opt/csye6225/logs/application.log
AWS_S3_BUCKET_NAME=$${S3_BUCKET_NAME}
AWS_REGION=$${REGION}
AWS_SNS_TOPIC_ARN=$${SNS_TOPIC_ARN}
APP_DOMAIN=${domain_name}
EOF

# Set proper permissions
sudo chown csye6225:csye6225 /opt/csye6225/.env
sudo chmod 600 /opt/csye6225/.env

echo "✓ Environment file created with RDS connection details and SNS topic"

# Configure CloudWatch Agent
echo "Configuring CloudWatch Agent..."

INSTANCE_ID=$(ec2-metadata --instance-id | cut -d " " -f 2)
REGION="${aws_region}"

echo "Instance ID: $INSTANCE_ID"
echo "Region: $REGION"

# Create CloudWatch Agent configuration
sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json > /dev/null <<EOF
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "cwagent",
    "region": "$REGION"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/opt/csye6225/logs/application.log",
            "log_group_name": "$LOG_GROUP_NAME",
            "log_stream_name": "{instance_id}-application",
            "retention_in_days": 7,
            "timezone": "UTC"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "CSYE6225/Application",
    "metrics_collected": {
      "mem": {
        "measurement": [
          {
            "name": "mem_used_percent",
            "rename": "MemoryUtilization",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          {
            "name": "used_percent",
            "rename": "DiskUtilization",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      },
      "statsd": {
        "service_address": ":8125",
        "metrics_collection_interval": 60,
        "metrics_aggregation_interval": 60
      }
    }
  }
}
EOF

echo "✓ CloudWatch Agent configuration created"

# Start CloudWatch Agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

sleep 5

# Verify agent started
if sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a status -m ec2 -c default | grep -q "running"; then
  echo "✓ CloudWatch Agent started successfully"
else
  echo "✗ CloudWatch Agent failed to start"
  echo "Agent status:"
  sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status -m ec2 -c default
  echo "Recent agent logs:"
  sudo tail -50 /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log
  exit 1
fi


# Restart the application service to pick up new configuration
echo "Restarting application service..."
sudo systemctl restart csye6225.service

# Wait a bit for service to start
sleep 10

# Check if application started successfully
if systemctl is-active --quiet csye6225.service; then
    echo "✓ Application started successfully and connected to RDS!"
else
    echo "✗ Application failed to start!"
    journalctl -u csye6225.service -n 50
    exit 1
fi

echo "=========================================="
echo "Instance Initialization Complete!"
echo "=========================================="