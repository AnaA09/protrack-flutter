#!/bin/bash

# Fix Tasks table by adding GSI for projectId queries
REGION="us-east-1"
TABLE_NAME="Tasks"

echo "Adding Global Secondary Index to Tasks table for projectId queries..."

# Add GSI with projectId as partition key
aws dynamodb update-table \
    --region $REGION \
    --table-name $TABLE_NAME \
    --attribute-definitions \
        AttributeName=projectId,AttributeType=S \
        AttributeName=taskId,AttributeType=S \
    --global-secondary-index-updates \
        '[{
            "Create": {
                "IndexName": "ProjectIdIndex",
                "KeySchema": [
                    {
                        "AttributeName": "projectId",
                        "KeyType": "HASH"
                    }
                ],
                "Projection": {
                    "ProjectionType": "ALL"
                },
                "BillingMode": "PAY_PER_REQUEST"
            }
        }]'

echo "GSI creation initiated. This may take a few minutes..."

# Wait for the GSI to be active
echo "Waiting for GSI to become active..."
aws dynamodb wait table-exists --table-name $TABLE_NAME --region $REGION

# Check the table status
echo "Checking table status:"
aws dynamodb describe-table --table-name $TABLE_NAME --region $REGION --query 'Table.GlobalSecondaryIndexes[0].IndexStatus'

echo "✅ Global Secondary Index added successfully!"
echo "You can now query tasks by projectId using the ProjectIdIndex." 