#!/bin/bash

# Exit on error
set -e

# Function to check if a command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo "Error: $1 is required but not installed."
        exit 1
    fi
}

# Function to check if AWS CLI is configured
check_aws_config() {
    if ! aws sts get-caller-identity &> /dev/null; then
        echo "Error: AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi
}

# Function to validate required variables
validate_variables() {
    local required_vars=("ROLE_ARN" "REGION" "USER_POOL_ID")
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            echo "Error: $var is not set"
            exit 1
        fi
    done
}

# Check prerequisites
check_command aws
check_aws_config

# Set variables
REGION=${REGION:-"us-east-1"}
ROLE_ARN=${ROLE_ARN:-""}  # Must be provided
USER_POOL_ID=${USER_POOL_ID:-""}  # Must be provided
API_NAME="protrack-api"
FUNCTION_NAME="project-management"

echo "Starting AWS infrastructure setup..."

# Create Lambda function
echo "Creating Lambda function..."
aws lambda create-function \
    --function-name $FUNCTION_NAME \
    --runtime python3.9 \
    --handler project_management.lambda_handler \
    --role $ROLE_ARN \
    --code S3Bucket=protrack-scripts,S3Key=lambda/project_management.zip \
    --environment "Variables={
        PROJECTS_TABLE=Projects,
        TASKS_TABLE=Tasks,
        ACTIVITIES_TABLE=Activities,
        INSTRUMENTS_TABLE=Instruments
    }" \
    --timeout 30 \
    --memory-size 256

# Get the function ARN
FUNCTION_ARN=$(aws lambda get-function --function-name $FUNCTION_NAME --query 'Configuration.FunctionArn' --output text)
echo "Lambda function created with ARN: $FUNCTION_ARN"

# Create API Gateway
echo "Creating API Gateway..."
API_ID=$(aws apigateway create-rest-api \
    --name $API_NAME \
    --query 'id' \
    --output text)
echo "API Gateway created with ID: $API_ID"

# Get the root resource ID
ROOT_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id $API_ID \
    --query 'items[?path==`/`].id' \
    --output text)

# Create /instruments resource
echo "Creating /instruments resource..."
INSTRUMENTS_RESOURCE_ID=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $ROOT_RESOURCE_ID \
    --path-part "instruments" \
    --query 'id' \
    --output text)

# Create /projects resource
echo "Creating /projects resource..."
PROJECTS_RESOURCE_ID=$(aws apigateway create-resource \
    --parent-id $ROOT_RESOURCE_ID \
    --path-part "projects" \
    --rest-api-id $API_ID \
    --query 'id' \
    --output text)

# Create methods for /instruments
echo "Setting up /instruments methods..."
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $INSTRUMENTS_RESOURCE_ID \
    --http-method ANY \
    --authorization-type COGNITO_USER_POOLS \
    --authorizer-id $USER_POOL_ID

# Create methods for /projects
echo "Setting up /projects methods..."
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $PROJECTS_RESOURCE_ID \
    --http-method ANY \
    --authorization-type COGNITO_USER_POOLS \
    --authorizer-id $USER_POOL_ID

# Create integration for /instruments
echo "Setting up /instruments integration..."
aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $INSTRUMENTS_RESOURCE_ID \
    --http-method ANY \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$FUNCTION_ARN/invocations

# Create integration for /projects
echo "Setting up /projects integration..."
aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $PROJECTS_RESOURCE_ID \
    --http-method ANY \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$FUNCTION_ARN/invocations

# Add Lambda permission for API Gateway
echo "Adding Lambda permission for API Gateway..."
aws lambda add-permission \
    --function-name $FUNCTION_NAME \
    --statement-id apigateway-invoke \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:$REGION:*:$API_ID/*/*/*"

# Enable CORS for the API
echo "Enabling CORS for the API..."
aws apigateway update-rest-api \
    --rest-api-id $API_ID \
    --patch-operations \
        op=add,path=/corsConfiguration,value='{"allowOrigins":["*"],"allowMethods":["GET","POST","PUT","DELETE","OPTIONS"],"allowHeaders":["Content-Type","Authorization"]}'

# Deploy the API
echo "Deploying the API..."
DEPLOYMENT_ID=$(aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod \
    --query 'id' \
    --output text)

echo "Setup completed successfully!"
echo "API Gateway ID: $API_ID"
echo "Lambda Function ARN: $FUNCTION_ARN"
echo "API Deployment ID: $DEPLOYMENT_ID"
echo "API Endpoint: https://$API_ID.execute-api.$REGION.amazonaws.com/prod" 