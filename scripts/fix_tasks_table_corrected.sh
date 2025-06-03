#!/bin/bash

# Fix Tasks table by adding GSI for projectId queries (corrected version)
REGION="us-east-1"
TABLE_NAME="Tasks"

echo "Adding Global Secondary Index to Tasks table for projectId queries..."

# Add GSI with projectId as partition key (without invalid BillingMode parameter)
aws dynamodb update-table \
    --region $REGION \
    --table-name $TABLE_NAME \
    --attribute-definitions \
        AttributeName=projectId,AttributeType=S \
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
                }
            }
        }]'

if [ $? -eq 0 ]; then
    echo "✅ GSI creation initiated successfully!"
    
    echo "Waiting for GSI to become active (this may take a few minutes)..."
    
    # Poll for GSI status
    while true; do
        STATUS=$(aws dynamodb describe-table --table-name $TABLE_NAME --region $REGION --query 'Table.GlobalSecondaryIndexes[0].IndexStatus' --output text 2>/dev/null)
        
        if [ "$STATUS" = "ACTIVE" ]; then
            echo "✅ GSI is now ACTIVE!"
            break
        elif [ "$STATUS" = "CREATING" ]; then
            echo "   GSI status: CREATING... (waiting 10 seconds)"
            sleep 10
        elif [ "$STATUS" = "None" ] || [ "$STATUS" = "null" ]; then
            echo "   GSI not found yet... (waiting 5 seconds)"
            sleep 5
        else
            echo "   GSI status: $STATUS (waiting 10 seconds)"
            sleep 10
        fi
    done
    
    echo ""
    echo "Final GSI status:"
    aws dynamodb describe-table --table-name $TABLE_NAME --region $REGION --query 'Table.GlobalSecondaryIndexes[0]'
    
else
    echo "❌ Failed to create GSI"
    exit 1
fi

echo ""
echo "✅ Global Secondary Index 'ProjectIdIndex' is ready!"
echo "The Lambda function can now query tasks by projectId." 