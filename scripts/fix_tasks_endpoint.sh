#!/bin/bash

# Fix /projects/{id}/tasks endpoint by adding missing methods and CORS
API_ID="acnpe7a49i"
REGION="us-east-1"
TASKS_RESOURCE_ID="4qje3j"
COGNITO_AUTHORIZER_ID="m2aj7f"

echo "Fixing tasks endpoint with Resource ID: $TASKS_RESOURCE_ID and Authorizer ID: $COGNITO_AUTHORIZER_ID"

# First, let's check what methods currently exist
echo "Current methods on tasks resource:"
aws apigateway get-resource --rest-api-id $API_ID --resource-id $TASKS_RESOURCE_ID --region $REGION

echo ""
echo "Adding GET method with Cognito authorization..."

# Add GET method
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $TASKS_RESOURCE_ID \
    --http-method GET \
    --authorization-type COGNITO_USER_POOLS \
    --authorizer-id $COGNITO_AUTHORIZER_ID \
    --region $REGION

# Add method response for GET
aws apigateway put-method-response \
    --rest-api-id $API_ID \
    --resource-id $TASKS_RESOURCE_ID \
    --http-method GET \
    --status-code 200 \
    --response-parameters method.response.header.Access-Control-Allow-Origin=false \
    --region $REGION

# Add integration for GET (Lambda proxy)
aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $TASKS_RESOURCE_ID \
    --http-method GET \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/arn:aws:lambda:$REGION:905418471058:function:project-management/invocations" \
    --region $REGION

echo "Adding POST method with Cognito authorization..."

# Add POST method
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $TASKS_RESOURCE_ID \
    --http-method POST \
    --authorization-type COGNITO_USER_POOLS \
    --authorizer-id $COGNITO_AUTHORIZER_ID \
    --region $REGION

# Add method response for POST
aws apigateway put-method-response \
    --rest-api-id $API_ID \
    --resource-id $TASKS_RESOURCE_ID \
    --http-method POST \
    --status-code 201 \
    --response-parameters method.response.header.Access-Control-Allow-Origin=false \
    --region $REGION

# Add integration for POST (Lambda proxy)
aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $TASKS_RESOURCE_ID \
    --http-method POST \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/arn:aws:lambda:$REGION:905418471058:function:project-management/invocations" \
    --region $REGION

echo "Adding OPTIONS method for CORS..."

# Add OPTIONS method (no authorization for CORS preflight)
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $TASKS_RESOURCE_ID \
    --http-method OPTIONS \
    --authorization-type NONE \
    --region $REGION

# Add method response for OPTIONS
aws apigateway put-method-response \
    --rest-api-id $API_ID \
    --resource-id $TASKS_RESOURCE_ID \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters method.response.header.Access-Control-Allow-Headers=false,method.response.header.Access-Control-Allow-Methods=false,method.response.header.Access-Control-Allow-Origin=false \
    --region $REGION

# Add integration for OPTIONS (MOCK)
aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $TASKS_RESOURCE_ID \
    --http-method OPTIONS \
    --type MOCK \
    --request-templates '{"application/json": "{\"statusCode\": 200}"}' \
    --region $REGION

# Add integration response for OPTIONS
aws apigateway put-integration-response \
    --rest-api-id $API_ID \
    --resource-id $TASKS_RESOURCE_ID \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{"method.response.header.Access-Control-Allow-Headers": "'\''Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token'\''","method.response.header.Access-Control-Allow-Methods": "'\''GET,POST,PUT,DELETE,OPTIONS'\''","method.response.header.Access-Control-Allow-Origin": "'\''*'\''"}'  \
    --region $REGION

echo "Deploying changes to prod stage..."

# Deploy the changes
aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod \
    --region $REGION

echo "✅ Tasks endpoint configuration completed!"
echo "The /projects/{projectId}/tasks endpoint should now work with proper authorization and CORS." 