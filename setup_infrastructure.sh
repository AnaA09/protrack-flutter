#!/bin/bash

# Configuration
STACK_NAME="protrack-stack"
REGION="us-east-1"
LAMBDA_FUNCTION_NAME="project-management"
API_NAME="protrack-api"
COGNITO_USER_POOL_NAME="protrack-user-pool"
COGNITO_CLIENT_NAME="protrack-client"

# Create DynamoDB tables
echo "Creating DynamoDB tables..."
python3 lambda/create_tables.py

# Create Cognito User Pool
echo "Creating Cognito User Pool..."
USER_POOL_ID=$(aws cognito-idp create-user-pool \
    --pool-name $COGNITO_USER_POOL_NAME \
    --policies '{
        "PasswordPolicy": {
            "MinimumLength": 8,
            "RequireUppercase": true,
            "RequireLowercase": true,
            "RequireNumbers": true,
            "RequireSymbols": true
        }
    }' \
    --schema '[
        {
            "Name": "email",
            "AttributeDataType": "String",
            "Required": true,
            "Mutable": true
        },
        {
            "Name": "name",
            "AttributeDataType": "String",
            "Required": true,
            "Mutable": true
        }
    ]' \
    --auto-verified-attributes '["email"]' \
    --query 'UserPool.Id' \
    --output text)

# Create Cognito App Client
echo "Creating Cognito App Client..."
CLIENT_ID=$(aws cognito-idp create-user-pool-client \
    --user-pool-id $USER_POOL_ID \
    --client-name $COGNITO_CLIENT_NAME \
    --no-generate-secret \
    --explicit-auth-flows "ALLOW_USER_SRP_AUTH" "ALLOW_REFRESH_TOKEN_AUTH" \
    --query 'UserPoolClient.ClientId' \
    --output text)

# Create IAM role for Lambda
echo "Creating IAM role for Lambda..."
ROLE_ARN=$(aws iam create-role \
    --role-name protrack-lambda-role \
    --assume-role-policy-document '{
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }]
    }' \
    --query 'Role.Arn' \
    --output text)

# Attach policies to Lambda role
echo "Attaching policies to Lambda role..."
aws iam attach-role-policy \
    --role-name protrack-lambda-role \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

aws iam attach-role-policy \
    --role-name protrack-lambda-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess

# Create Lambda function
echo "Creating Lambda function..."
# Create deployment package
cd lambda
zip -r ../function.zip .
cd ..

FUNCTION_ARN=$(aws lambda create-function \
    --function-name $LAMBDA_FUNCTION_NAME \
    --runtime python3.9 \
    --handler project_management.lambda_handler \
    --role $ROLE_ARN \
    --zip-file fileb://function.zip \
    --environment "Variables={
        PROJECTS_TABLE=Projects,
        TASKS_TABLE=Tasks,
        ACTIVITIES_TABLE=Activities,
        INSTRUMENTS_TABLE=Instruments
    }" \
    --query 'FunctionArn' \
    --output text)

# Create API Gateway
echo "Creating API Gateway..."
API_ID=$(aws apigateway create-rest-api \
    --name $API_NAME \
    --query 'id' \
    --output text)

# Get root resource ID
ROOT_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id $API_ID \
    --query 'items[?path==`/`].id' \
    --output text)

# Create resources
echo "Creating API Gateway resources..."

# Create /instruments resource
INSTRUMENTS_RESOURCE_ID=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $ROOT_RESOURCE_ID \
    --path-part "instruments" \
    --query 'id' \
    --output text)

# Create /projects resource
PROJECTS_RESOURCE_ID=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $ROOT_RESOURCE_ID \
    --path-part "projects" \
    --query 'id' \
    --output text)

# Create methods for /instruments
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $INSTRUMENTS_RESOURCE_ID \
    --http-method ANY \
    --authorization-type COGNITO_USER_POOLS \
    --authorizer-id $USER_POOL_ID

# Create methods for /projects
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $PROJECTS_RESOURCE_ID \
    --http-method ANY \
    --authorization-type COGNITO_USER_POOLS \
    --authorizer-id $USER_POOL_ID

# Create integration with Lambda
aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $INSTRUMENTS_RESOURCE_ID \
    --http-method ANY \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$FUNCTION_ARN/invocations

aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $PROJECTS_RESOURCE_ID \
    --http-method ANY \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$FUNCTION_ARN/invocations

# Deploy API
echo "Deploying API..."
DEPLOYMENT_ID=$(aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod \
    --query 'id' \
    --output text)

# Add Lambda permission for API Gateway
aws lambda add-permission \
    --function-name $LAMBDA_FUNCTION_NAME \
    --statement-id apigateway-prod \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:$REGION:$(aws sts get-caller-identity --query 'Account' --output text):$API_ID/*/*/*"

# Output configuration
echo "Setup completed successfully!"
echo "User Pool ID: $USER_POOL_ID"
echo "Client ID: $CLIENT_ID"
echo "API Gateway URL: https://$API_ID.execute-api.$REGION.amazonaws.com/prod"
echo "Lambda Function ARN: $FUNCTION_ARN"

# Clean up
rm function.zip 