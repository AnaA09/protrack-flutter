"UserPoolId": "us-east-1_oEvEdG7hY",
"ClientName": "ProTrackClient",
"ClientId": "112eapunjrouch2koprr5kf5hd",

"IdentityPoolId": "us-east-1:b534c259-e111-454a-9ebd-d759e2ea4394",
"IdentityPoolName": "ProTrackIdentityPool",
    "CognitoIdentityProviders": [
        {
            "ProviderName": "cognito-idp.us-east-1.amazonaws.com/us-east-1_oEvEdG7hY",
            "ClientId": "112eapunjrouch2koprr5kf5hd",
        }
    ],

"RoleName": "Cognito_ProTrackAuth_Role",
        "RoleId": "AROASFIXCO7UWKIHM64AS",
        "Arn": "arn:aws:iam::148761638889:role/Cognito_ProTrackAuth_Role",

"RoleName": "Cognito_ProTrackUnauth_Role",
        "RoleId": "AROASFIXCO7UWGJOJTS4L",
        "Arn": "arn:aws:iam::148761638889:role/Cognito_ProTrackUnauth_Role",

 aws cognito-identity update-identity-pool \
  --identity-pool-id us-east-1:b534c259-e111-454a-9ebd-d759e2ea4394 \
  --identity-pool-name ProTrackIdentityPool \
  --allow-unauthenticated-identities \
  --cognito-identity-providers ProviderName="cognito-idp.us-east-1.amazonaws.com/us-east-1_oEvEdG7hY",ClientId="112eapunjrouch2koprr5kf5hd",ServerSideTokenCheck=true \
   --role-mappings '{"authenticated":"arn:aws:iam::148761638889:role/Cognito_ProTrackAuth_Role","unauthenticated":"arn:aws:iam::148761638889:role/Cognito_ProTrackUnauth_Role"}'

  aws cognito-identity update-identity-pool \
  --identity-pool-id YOUR_IDENTITY_POOL_ID \
  --identity-pool-name ProTrackIdentityPool \
  --allow-unauthenticated-identities \
  --cognito-identity-providers ProviderName="cognito-idp.YOUR_REGION.amazonaws.com/YOUR_USER_POOL_ID",ClientId="YOUR_CLIENT_ID",ServerSideTokenCheck=true \
  --role-mappings '{
    "authenticated": "arn:aws:iam::148761638889:role/Cognito_ProTrackAuth_Role",
    "unauthenticated": "arn:aws:iam::148761638889:role/Cognito_ProTrackUnauth_Role"
  }'

brew install awscli
aws configure
aws cognito-idp create-user-pool \
  --pool-name ProTrackUserPool \
  --policies '{"PasswordPolicy":{"MinimumLength":8,"RequireUppercase":true,"RequireLowercase":true,"RequireNumbers":true,"RequireSymbols":true}}' \
  --schema '[{"Name":"email","Required":true,"Mutable":true},{"Name":"name","Required":true,"Mutable":true},{"Name":"phone_number","Required":false,"Mutable":true}]' \
  --auto-verified-attributes email \
  --mfa-configuration OFF \
  --account-recovery-setting '{"RecoveryMechanisms": [{"Priority": 1, "Name": "verified_email"}]}'

  aws cognito-idp create-user-pool-client \
  --user-pool-id YOUR_USER_POOL_ID \
  --client-name ProTrackClient \
  --no-generate-secret \
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH ALLOW_USER_SRP_AUTH


aws cognito-identity create-identity-pool \
  --identity-pool-name ProTrackIdentityPool \
  --allow-unauthenticated-identities \
  --cognito-identity-providers ProviderName="cognito-idp.us-east-1.amazonaws.com/us-east-1_oEvEdG7hY",ClientId="112eapunjrouch2koprr5kf5hd",ServerSideTokenCheck=true

 
  aws iam create-role \
  --role-name Cognito_ProTrackAuth_Role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Federated":"cognito-identity.amazonaws.com"},"Action":"sts:AssumeRoleWithWebIdentity","Condition":{"StringEquals":{"cognito-identity.amazonaws.com:aud":"us-east-1:b534c259-e111-454a-9ebd-d759e2ea4394"},"ForAnyValue:StringLike":{"cognito-identity.amazonaws.com:amr":"authenticated"}}}]}'

aws iam create-role \
  --role-name Cognito_ProTrackUnauth_Role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Federated":"cognito-identity.amazonaws.com"},"Action":"sts:AssumeRoleWithWebIdentity","Condition":{"StringEquals":{"cognito-identity.amazonaws.com:aud":"us-east-1:b534c259-e111-454a-9ebd-d759e2ea4394"},"ForAnyValue:StringLike":{"cognito-identity.amazonaws.com:amr":"unauthenticated"}}}]}'

  -----

  aws iam put-role-policy \
  --role-name Cognito_ProTrackAuth_Role \
  --policy-name Cognito_ProTrackAuth_Policy \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["mobileanalytics:PutEvents","cognito-sync:*","cognito-identity:*"],"Resource":["*"]}]}'

aws iam put-role-policy \
  --role-name Cognito_ProTrackUnauth_Role \
  --policy-name Cognito_ProTrackUnauth_Policy \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["mobileanalytics:PutEvents","cognito-sync:*"],"Resource":["*"]}]}'

  aws cognito-identity update-identity-pool \
  --identity-pool-id YOUR_IDENTITY_POOL_ID \
  --identity-pool-name ProTrackIdentityPool \
  --allow-unauthenticated-identities \
  --cognito-identity-providers ProviderName="cognito-idp.YOUR_REGION.amazonaws.com/YOUR_USER_POOL_ID",ClientId="YOUR_CLIENT_ID",ServerSideTokenCheck=true \
  --roles authenticated="arn:aws:iam::YOUR_ACCOUNT_ID:role/Cognito_ProTrackAuth_Role",unauthenticated="arn:aws:iam::YOUR_ACCOUNT_ID:role/Cognito_ProTrackUnauth_Role"

  Set up Google OAuth:
Go to the Google Cloud Console
Create a new project
Enable the Google+ API
Create OAuth 2.0 credentials
Add the authorized redirect URIs from Cognito

aws cognito-idp create-identity-provider \
  --user-pool-id YOUR_USER_POOL_ID \
  --provider-name Google \
  --provider-type Google \
  --provider-details '{"client_id":"YOUR_GOOGLE_CLIENT_ID","client_secret":"YOUR_GOOGLE_CLIENT_SECRET","authorize_scopes":"email profile openid"}' \
  --attribute-mapping '{"email":"email","username":"sub"}'

  After completing these steps, update the CognitoService class with your actual values:
_userPoolId
_clientId
_identityPoolId
_region


# Create DynamoDB table for user metadata
aws dynamodb create-table \
    --table-name UserMetadata \
    --attribute-definitions \
        AttributeName=userId,AttributeType=S \
    --key-schema \
        AttributeName=userId,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --tags Key=Project,Value=Protrack



# Create the IAM role with trust policy
aws iam create-role \
    --role-name lambda-dynamodb-role \
    --assume-role-policy-document '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": "lambda.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }'

# Attach necessary policies
aws iam attach-role-policy \
    --role-name lambda-dynamodb-role \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

aws iam attach-role-policy \
    --role-name lambda-dynamodb-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess

aws iam attach-role-policy \
    --role-name lambda-dynamodb-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# Wait for role propagation (important!)
sleep 10

# Now create the Lambda function
aws lambda create-function \
    --function-name UserMetadataManagement \
    --runtime python3.9 \
    --handler user_management.lambda_handler \
    --role arn:aws:iam::148761638889:role/lambda-dynamodb-role \
    --code S3Bucket=protrack-scripts,S3Key=lambda/user_management.zip \
    --environment Variables={USER_METADATA_TABLE=UserMetadata}

# Create API Gateway


"UserPoolId": "us-east-1_oEvEdG7hY",
"ClientName": "ProTrackClient",
"ClientId": "112eapunjrouch2koprr5kf5hd",

"IdentityPoolId": "us-east-1:b534c259-e111-454a-9ebd-d759e2ea4394",
"IdentityPoolName": "ProTrackIdentityPool",

API_NAME="User Metadata API"
USER_POOL_ID="us-east-1_oEvEdG7h"
REGION="us-east-1"
ACCOUNT_ID="148761638889"

aws apigateway create-rest-api \
    --name "User Metadata API" \
    --description "API for managing user metadata"

    "id": "acnpe7a49i",
    "name": "User Metadata API",
    "description": "API for managing user metadata",

# Get API ID and root resource ID
API_ID=$(aws apigateway get-rest-apis --query "items[?name=='User Metadata API'].id" --output text)
ROOT_RESOURCE_ID=$(aws apigateway get-resources --rest-api-id $API_ID --query "items[?path=='/'].id" --output text)

# Create resource
aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $ROOT_RESOURCE_ID \
    --path-part "user"

"id": "cvu781",
    "parentId": "tilsll8qq5",

# Create methods
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method GET \
    --authorization-type COGNITO_USER_POOLS \
    --authorizer-id $COGNITO_AUTHORIZER_ID

aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method POST \
    --authorization-type COGNITO_USER_POOLS \
    --authorizer-id $COGNITO_AUTHORIZER_ID

aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method PUT \
    --authorization-type COGNITO_USER_POOLS \
    --authorizer-id $COGNITO_AUTHORIZER_ID

aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method DELETE \
    --authorization-type COGNITO_USER_POOLS \
    --authorizer-id $COGNITO_AUTHORIZER_ID

# Create the Cognito Authorizer
aws apigateway create-authorizer \
    --rest-api-id $API_ID \
    --name "CognitoUserPoolAuthorizer" \
    --type COGNITO_USER_POOLS \
    --provider-arns "arn:aws:cognito-idp:us-east-1:148761638889:userpool/us-east-1_oEvEdG7hY" \
    --identity-source "method.request.header.Authorization"

 "id": "gs0hyc",
    "name": "CognitoUserPoolAuthorizer",
    "type": "COGNITO_USER_POOLS",
    "providerARNs": [
        "arn:aws:cognito-idp:us-east-1:148761638889:userpool/us-east-1_oEvEdG7hY"
    ],
    
# Get the Authorizer ID
COGNITO_AUTHORIZER_ID=$(aws apigateway get-authorizers \
    --rest-api-id $API_ID \
    --query "items[?name=='CognitoUserPoolAuthorizer'].id" \
    --output text)

API_NAME="User Metadata API"
USER_POOL_ID="your-user-pool-id"
REGION="your-region"
ACCOUNT_ID="your-account-id"

# Update the zip file
cd lambda
zip -r user_management.zip user_management.py requirements.txt


# Update Lambda function
aws lambda update-function-code \
    --function-name UserMetadataManagement \
    --s3-bucket protrack-scripts \
    --s3-key lambda/user_management.zip

aws iam attach-role-policy \
    --role-name lambda-dynamodb-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# Get Lambda function ARN
LAMBDA_ARN=$(aws lambda get-function --function-name UserMetadataManagement --query 'Configuration.FunctionArn' --output text)

# GET method integration
aws apigateway put-integration \
    --rest-api-id acnpe7a49i \
    --resource-id cvu781 \
    --http-method GET \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations

# POST method integration
aws apigateway put-integration \
    --rest-api-id acnpe7a49i \
    --resource-id cvu781 \
    --http-method POST \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations

# PUT method integration
aws apigateway put-integration \
    --rest-api-id acnpe7a49i \
    --resource-id cvu781 \
    --http-method PUT \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations

# DELETE method integration
aws apigateway put-integration \
    --rest-api-id acnpe7a49i \
    --resource-id cvu781 \
    --http-method DELETE \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations

# Grant API Gateway permission to invoke Lambda
aws lambda add-permission \
    --function-name UserMetadataManagement \
    --statement-id apigateway-prod \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:us-east-1:148761638889:acnpe7a49i/*/*/*"

# Now create the deployment
aws apigateway create-deployment \
    --rest-api-id acnpe7a49i \
    --stage-name prod

# Enable CORS for the stage
aws apigateway update-resource \
    --rest-api-id acnpe7a49i \
    --resource-id cvu781 \
    --patch-operations op=add,path=/cors,value=true

# Add CORS configuration
aws apigateway put-method-response \
    --rest-api-id acnpe7a49i \
    --resource-id cvu781 \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Headers": true,
        "method.response.header.Access-Control-Allow-Methods": true,
        "method.response.header.Access-Control-Allow-Origin": true,
        "method.response.header.Access-Control-Max-Age": true
    }'

# Add CORS headers
aws apigateway put-integration-response \
    --rest-api-id acnpe7a49i \
    --resource-id cvu781 \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Headers": "'\''Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'\''",
        "method.response.header.Access-Control-Allow-Methods": "'\''GET,POST,PUT,DELETE,OPTIONS'\''",
        "method.response.header.Access-Control-Allow-Origin": "'\''*'\''",
        "method.response.header.Access-Control-Max-Age": "'\''7200'\''"
    }'

aws apigateway put-method \
    --rest-api-id acnpe7a49i \
    --resource-id cvu781 \
    --http-method OPTIONS \
    --authorization-type NONE

aws apigateway put-integration \
    --rest-api-id acnpe7a49i \
    --resource-id cvu781 \
    --http-method OPTIONS \
    --type MOCK \
    --request-templates '{"application/json":"{\"statusCode\": 200}"}'

# For GET method
aws apigateway put-method-response \
    --rest-api-id acnpe7a49i \
    --resource-id cvu781 \
    --http-method GET \
    --status-code 200 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Origin": true
    }'

aws apigateway put-integration-response \
    --rest-api-id acnpe7a49i \
    --resource-id cvu781 \
    --http-method GET \
    --status-code 200 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Origin": "'\''*'\''"
    }'

# For GET method
aws apigateway put-method-response \
    --rest-api-id acnpe7a49i \
    --resource-id cvu781 \
    --http-method DELETE \
    --status-code 200 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Origin": true
    }'

aws apigateway put-integration-response \
    --rest-api-id acnpe7a49i \
    --resource-id cvu781 \
    --http-method DELETE \
    --status-code 200 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Origin": "'\''*'\''"
    }'
https://acnpe7a49i.execute-api.us-east-1.amazonaws.com/prod/user

----
tmp
----


# Test the authorizer with explicit Bearer format
aws apigateway test-invoke-authorizer \
    --rest-api-id acnpe7a49i \
    --authorizer-id m2aj7f\
    --headers "Authorization=Bearer eyJraWQiOiJaRVVnaFlWZ2t1Ym0xNnBXYWdYSElnVE5qSXE5YjNXa1JjT2hoN2F0cU1zPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiIzNDc4MDRjOC01MDcxLTcwYzYtMmFkZS0xMDkwYWM4NjczYTYiLCJpc3MiOiJodHRwczpcL1wvY29nbml0by1pZHAudXMtZWFzdC0xLmFtYXpvbmF3cy5jb21cL3VzLWVhc3QtMV9vRXZFZEc3aFkiLCJjbGllbnRfaWQiOiIxMTJlYXB1bmpyb3VjaDJrb3BycjVrZjVoZCIsIm9yaWdpbl9qdGkiOiIwYjJmZmZkZi0xMTNjLTRmNjEtOWQyZi1jNmYzZjFiOTI1MDAiLCJldmVudF9pZCI6ImIxMWJjMjI4LTNhYzUtNDg4OC05ZmY4LTIyNDllMTkxNGQyOSIsInRva2VuX3VzZSI6ImFjY2VzcyIsInNjb3BlIjoiYXdzLmNvZ25pdG8uc2lnbmluLnVzZXIuYWRtaW4iLCJhdXRoX3RpbWUiOjE3NDc1Mzk0MzIsImV4cCI6MTc0NzU0MzAzMiwiaWF0IjoxNzQ3NTM5NDMyLCJqdGkiOiI1ZGYxY2RkOC05NmUxLTQ3MTMtYmEyYy02YzJjZWViNWEzMzQiLCJ1c2VybmFtZSI6InRlc3QifQ.0Tib3LhceRzp7d80wb7YiHTTQCj9rY2l7RBKRmQry6oBGvZSjFPcnMEtft02lsoZaZ2W-55Ya3NCyifFiWn9miDpUkU7kcPsp8eMZ0gDuxm4HDJhyody23R_kmNH1ADY6hi8Isn8Z8qfR8w-5NjEqFGIe8OhC-wLFfVxYX6cCmQbYND1otxsn4MF77d488xTNNEUNwbW6eoFCwTqpr-J79EpBejOSgQUDJvw3WLIGi3BCL-M1TzlXwHkRF5zA5Df-5xJ3wcip4186wuW_iZU9NaxXMlSVIC4c31Y8AmCNdtpzpsuW6f6khANYZLEcuKkRA7QoALtw6K1P5D0V6Y1fQ"