#!/bin/bash

# Setup API Gateway for inventory management
REGION="us-east-1"
API_ID="acnpe7a49i"  # Existing API Gateway ID
LAMBDA_FUNCTION="inventory-management"
AUTHORIZER_ID="m2aj7f"  # Existing Cognito authorizer

echo "🚀 Setting up inventory API endpoints..."

# Get Lambda function ARN
LAMBDA_ARN=$(aws lambda get-function --function-name $LAMBDA_FUNCTION --query 'Configuration.FunctionArn' --output text)
echo "Lambda ARN: $LAMBDA_ARN"

# Create inventory resource
echo "Creating /inventory resource..."
INVENTORY_RESOURCE_ID=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $(aws apigateway get-resources --rest-api-id $API_ID --query 'items[?path==`/`].id' --output text) \
    --path-part inventory \
    --query 'id' --output text)

echo "Inventory resource ID: $INVENTORY_RESOURCE_ID"

# Create labs resource under inventory
echo "Creating /inventory/labs resource..."
LABS_RESOURCE_ID=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $INVENTORY_RESOURCE_ID \
    --path-part labs \
    --query 'id' --output text)

# Add OPTIONS method to labs resource
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $LABS_RESOURCE_ID \
    --http-method OPTIONS \
    --authorization-type NONE

# Add GET method to labs resource
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $LABS_RESOURCE_ID \
    --http-method GET \
    --authorization-type COGNITO_USER_POOLS \
    --authorizer-id $AUTHORIZER_ID

# Add POST method to labs resource
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $LABS_RESOURCE_ID \
    --http-method POST \
    --authorization-type COGNITO_USER_POOLS \
    --authorizer-id $AUTHORIZER_ID

# Set up integrations for labs resource
for METHOD in OPTIONS GET POST; do
    aws apigateway put-integration \
        --rest-api-id $API_ID \
        --resource-id $LABS_RESOURCE_ID \
        --http-method $METHOD \
        --type AWS_PROXY \
        --integration-http-method POST \
        --uri "arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$LAMBDA_ARN/invocations"
done

# Create {labId} resource under labs
echo "Creating /inventory/labs/{labId} resource..."
LAB_ID_RESOURCE_ID=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $LABS_RESOURCE_ID \
    --path-part '{labId}' \
    --query 'id' --output text)

# Add methods to {labId} resource
for METHOD in OPTIONS GET; do
    if [ "$METHOD" = "OPTIONS" ]; then
        AUTH_TYPE="NONE"
        AUTHORIZER=""
    else
        AUTH_TYPE="COGNITO_USER_POOLS"
        AUTHORIZER="--authorizer-id $AUTHORIZER_ID"
    fi
    
    aws apigateway put-method \
        --rest-api-id $API_ID \
        --resource-id $LAB_ID_RESOURCE_ID \
        --http-method $METHOD \
        --authorization-type $AUTH_TYPE \
        $AUTHORIZER
        
    aws apigateway put-integration \
        --rest-api-id $API_ID \
        --resource-id $LAB_ID_RESOURCE_ID \
        --http-method $METHOD \
        --type AWS_PROXY \
        --integration-http-method POST \
        --uri "arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$LAMBDA_ARN/invocations"
done

# Create categories resource under {labId}
echo "Creating /inventory/labs/{labId}/categories resource..."
CATEGORIES_RESOURCE_ID=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $LAB_ID_RESOURCE_ID \
    --path-part categories \
    --query 'id' --output text)

# Add methods to categories resource
for METHOD in OPTIONS GET POST; do
    if [ "$METHOD" = "OPTIONS" ]; then
        AUTH_TYPE="NONE"
        AUTHORIZER=""
    else
        AUTH_TYPE="COGNITO_USER_POOLS"
        AUTHORIZER="--authorizer-id $AUTHORIZER_ID"
    fi
    
    aws apigateway put-method \
        --rest-api-id $API_ID \
        --resource-id $CATEGORIES_RESOURCE_ID \
        --http-method $METHOD \
        --authorization-type $AUTH_TYPE \
        $AUTHORIZER
        
    aws apigateway put-integration \
        --rest-api-id $API_ID \
        --resource-id $CATEGORIES_RESOURCE_ID \
        --http-method $METHOD \
        --type AWS_PROXY \
        --integration-http-method POST \
        --uri "arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$LAMBDA_ARN/invocations"
done

# Grant API Gateway permission to invoke Lambda
aws lambda add-permission \
    --function-name $LAMBDA_FUNCTION \
    --statement-id inventory-api-gateway-invoke \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:$REGION:*:$API_ID/*/*" \
    --region $REGION

# Deploy the API
echo "Deploying API..."
aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod

echo "✅ Inventory API setup complete!"
echo "🌐 API URL: https://$API_ID.execute-api.$REGION.amazonaws.com/prod/inventory/labs" 