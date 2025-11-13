#!/bin/bash
# Script to create a placeholder Lambda function zip file
# This is just a placeholder - your actual Lambda will be in the serverless repo

echo "Creating placeholder Lambda function..."

# Create a temporary directory
mkdir -p /tmp/lambda-placeholder

# Create a simple placeholder Lambda function
cat > /tmp/lambda-placeholder/index.js << 'EOF'
exports.handler = async (event) => {
    console.log('Placeholder Lambda - Event received:', JSON.stringify(event, null, 2));
    
    // Parse SNS message
    const snsMessage = event.Records[0].Sns.Message;
    console.log('SNS Message:', snsMessage);
    
    return {
        statusCode: 200,
        body: JSON.stringify({
            message: 'Placeholder Lambda - will be replaced by CI/CD',
            timestamp: new Date().toISOString()
        })
    };
};
EOF

# Create the zip file
cd /tmp/lambda-placeholder
zip -r lambda_function.zip index.js

# Move to current directory or terraform directory
if [ -d "./terraform" ]; then
    mv lambda_function.zip ./terraform/
    echo "✓ Created lambda_function.zip in ./terraform/"
else
    mv lambda_function.zip ./
    echo "✓ Created lambda_function.zip in current directory"
fi

# Cleanup
rm -rf /tmp/lambda-placeholder

echo "Done! You can now run 'terraform apply'"
echo ""
echo "NOTE: This is just a placeholder. Your actual Lambda function"
echo "will be deployed from the serverless repository via CI/CD."