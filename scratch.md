scratch.txt



# Create the Lambda function
aws lambda create-function \
    --function-name project-management \
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
FUNCTION_ARN=$(aws lambda get-function --function-name project-management --query 'Configuration.FunctionArn' --output text)

# Create the API
# API_ID=$(aws apigateway create-rest-api \
#    --name protrack-api \
#    --query 'id' \
#    --output text)

API_ID="acnpe7a49i"
USER_POOLID="us-east-1_oEvEdG7hY"


# Get the root resource ID
ROOT_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id $API_ID \
    --query 'items[?path==`/`].id' \
    --output text)

# Create /instruments resource
INSTRUMENTS_RESOURCE_ID=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $ROOT_RESOURCE_ID \
    --path-part "instruments" \
    --query 'id' \
    --output text)

# Create /projects resource
PROJECTS_RESOURCE_ID=$(aws apigateway create-resource \
    --parent-id $ROOT_RESOURCE_ID \
    --path-part "projects" \
    --rest-api-id $API_ID \
    --query 'id' \
    --output text)

    # Create methods for /instruments
    USER_POOL_ID="m2aj7f"
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

    # Create integration for /instruments

    REGION="us-east-1"
    FUNCTION_ARN="arn:aws:lambda:us-east-1:148761638889:function:project-management"
aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $INSTRUMENTS_RESOURCE_ID \
    --http-method ANY \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$FUNCTION_ARN/invocations

# Create integration for /projects
aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $PROJECTS_RESOURCE_ID \
    --http-method ANY \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$FUNCTION_ARN/invocations