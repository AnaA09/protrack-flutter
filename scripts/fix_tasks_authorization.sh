#!/bin/bash

# Fix authorization for /projects/{id}/tasks endpoint
# Replace with your actual API Gateway ID and region

API_ID="acnpe7a49i"
REGION="us-east-1"
STAGE_NAME="prod"

echo "Fixing authorization configuration for /projects/{id}/tasks endpoint..."

# First, find the resource ID for /projects/{id}/tasks
echo "Finding resource IDs..."

# Get all resources and find the authorizer ID
aws apigateway get-resources --rest-api-id $API_ID --region $REGION > resources.json
aws apigateway get-authorizers --rest-api-id $API_ID --region $REGION > authorizers.json

echo "Resource structure:"
aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[].{Path:pathPart,ResourceId:id,ParentId:parentId}' --output table

echo ""
echo "Available authorizers:"
aws apigateway get-authorizers --rest-api-id $API_ID --region $REGION --query 'items[].{Name:name,Id:id,Type:type}' --output table

echo ""
echo "Please identify:"
echo "1. The resource ID for the 'tasks' resource under /projects/{id}/"
echo "2. The authorizer ID for the Cognito User Pool authorizer"
echo ""
echo "Then run the following commands with the correct IDs:"
echo ""

# Template commands (replace with actual resource and authorizer IDs)
cat << 'EOF'
# Replace these with the actual IDs
TASKS_RESOURCE_ID="REPLACE_WITH_TASKS_RESOURCE_ID"
COGNITO_AUTHORIZER_ID="REPLACE_WITH_COGNITO_AUTHORIZER_ID"

# Update the GET method authorization for tasks
aws apigateway update-method \
    --rest-api-id acnpe7a49i \
    --resource-id $TASKS_RESOURCE_ID \
    --http-method GET \
    --patch-ops op=replace,path=/authorizationType,value=COGNITO_USER_POOLS \
    --region us-east-1

aws apigateway update-method \
    --rest-api-id acnpe7a49i \
    --resource-id $TASKS_RESOURCE_ID \
    --http-method GET \
    --patch-ops op=replace,path=/authorizerId,value=$COGNITO_AUTHORIZER_ID \
    --region us-east-1

# Update the POST method authorization for tasks (if it exists)
aws apigateway update-method \
    --rest-api-id acnpe7a49i \
    --resource-id $TASKS_RESOURCE_ID \
    --http-method POST \
    --patch-ops op=replace,path=/authorizationType,value=COGNITO_USER_POOLS \
    --region us-east-1

aws apigateway update-method \
    --rest-api-id acnpe7a49i \
    --resource-id $TASKS_RESOURCE_ID \
    --http-method POST \
    --patch-ops op=replace,path=/authorizerId,value=$COGNITO_AUTHORIZER_ID \
    --region us-east-1

# Add OPTIONS method with no authorization (for CORS)
aws apigateway put-method \
    --rest-api-id acnpe7a49i \
    --resource-id $TASKS_RESOURCE_ID \
    --http-method OPTIONS \
    --authorization-type NONE \
    --region us-east-1

# Add method response for OPTIONS
aws apigateway put-method-response \
    --rest-api-id acnpe7a49i \
    --resource-id $TASKS_RESOURCE_ID \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters method.response.header.Access-Control-Allow-Headers=false,method.response.header.Access-Control-Allow-Methods=false,method.response.header.Access-Control-Allow-Origin=false \
    --region us-east-1

# Add integration for OPTIONS (MOCK)
aws apigateway put-integration \
    --rest-api-id acnpe7a49i \
    --resource-id $TASKS_RESOURCE_ID \
    --http-method OPTIONS \
    --type MOCK \
    --integration-http-method OPTIONS \
    --request-templates '{"application/json": "{\"statusCode\": 200}"}' \
    --region us-east-1

# Add integration response for OPTIONS
aws apigateway put-integration-response \
    --rest-api-id acnpe7a49i \
    --resource-id $TASKS_RESOURCE_ID \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{"method.response.header.Access-Control-Allow-Headers": "'\''Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token'\''","method.response.header.Access-Control-Allow-Methods": "'\''GET,POST,PUT,DELETE,OPTIONS'\''","method.response.header.Access-Control-Allow-Origin": "'\''*'\''"}'  \
    --region us-east-1

# Deploy the changes
aws apigateway create-deployment \
    --rest-api-id acnpe7a49i \
    --stage-name prod \
    --region us-east-1

echo "Authorization and CORS configuration updated for tasks endpoint. Deployment complete."
EOF

# Clean up
rm -f resources.json authorizers.json

echo ""
echo "Alternative: Check if the tasks endpoint should be using the same path pattern as projects:"
echo "The /projects endpoint works, so the tasks endpoint should use the same authorizer." 