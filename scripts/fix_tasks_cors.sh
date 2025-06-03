#!/bin/bash

# Fix CORS for /projects/{id}/tasks endpoint
# Replace with your actual API Gateway ID and region

API_ID="acnpe7a49i"
REGION="us-east-1"
STAGE_NAME="prod"

echo "Adding CORS configuration for /projects/{id}/tasks endpoint..."

# First, find the resource ID for /projects/{id}/tasks
echo "Finding resource IDs..."

# Get all resources
aws apigateway get-resources --rest-api-id $API_ID --region $REGION > resources.json

# Extract resource IDs (you'll need to manually identify the correct resource ID for /projects/{id}/tasks)
echo "Resource structure:"
aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[].{Path:pathPart,ResourceId:id,ParentId:parentId}' --output table

echo ""
echo "Please identify the resource ID for the 'tasks' resource under /projects/{id}/"
echo "Then run the following commands with the correct RESOURCE_ID:"
echo ""

# Template commands (replace TASKS_RESOURCE_ID with the actual resource ID)
cat << 'EOF'
# Replace TASKS_RESOURCE_ID with the actual resource ID for the tasks resource

TASKS_RESOURCE_ID="REPLACE_WITH_ACTUAL_RESOURCE_ID"

# Add OPTIONS method to the tasks resource
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

echo "CORS configuration added for tasks endpoint. Deployment complete."
EOF

# Clean up
rm -f resources.json 