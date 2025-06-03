#!/bin/bash

# Deploy inventory management Lambda function
REGION="us-east-1"
FUNCTION_NAME="inventory-management"
ZIP_FILE="inventory-management-deployment.zip"

echo "📦 Creating deployment package..."

# Remove old deployment package if it exists
rm -f $ZIP_FILE

# Create a temporary directory for the deployment package
mkdir -p deployment_temp
cp lambda/inventory_management.py deployment_temp/

# Create the zip file
cd deployment_temp
zip -r ../$ZIP_FILE .
cd ..
rm -rf deployment_temp

echo "✅ Deployment package created: $ZIP_FILE"

# Get the role from existing project-management function
LAMBDA_ROLE=$(aws lambda get-function --function-name project-management --query 'Configuration.Role' --output text)

# Check if function exists
if aws lambda get-function --function-name $FUNCTION_NAME --region $REGION >/dev/null 2>&1; then
    echo "📝 Updating existing Lambda function..."
    
    # Update function code
    aws lambda update-function-code \
        --region $REGION \
        --function-name $FUNCTION_NAME \
        --zip-file fileb://$ZIP_FILE
    
    # Update environment variables
    aws lambda update-function-configuration \
        --region $REGION \
        --function-name $FUNCTION_NAME \
        --environment Variables="{INSTRUMENTS_TABLE=Instruments,BOOKINGS_TABLE=Bookings}"
        
    echo "✅ Lambda function updated successfully!"
else
    echo "🚀 Creating new Lambda function..."
    
    # Create new function
    aws lambda create-function \
        --region $REGION \
        --function-name $FUNCTION_NAME \
        --runtime python3.9 \
        --role $LAMBDA_ROLE \
        --handler inventory_management.lambda_handler \
        --zip-file fileb://$ZIP_FILE \
        --environment Variables="{INSTRUMENTS_TABLE=Instruments,BOOKINGS_TABLE=Bookings}" \
        --timeout 30 \
        --memory-size 256
        
    echo "✅ Lambda function created successfully!"
fi

# Clean up
rm $ZIP_FILE

echo "🎉 Deployment complete!" 