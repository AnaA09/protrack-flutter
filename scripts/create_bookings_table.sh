#!/bin/bash

# Create Bookings table for inventory management
REGION="us-east-1"
TABLE_NAME="Bookings"

echo "Creating Bookings table..."

aws dynamodb create-table \
    --region $REGION \
    --table-name $TABLE_NAME \
    --attribute-definitions \
        AttributeName=bookingId,AttributeType=S \
        AttributeName=entryId,AttributeType=S \
        AttributeName=userId,AttributeType=S \
    --key-schema \
        AttributeName=bookingId,KeyType=HASH \
    --global-secondary-indexes \
        '[{
            "IndexName": "EntryIdIndex",
            "KeySchema": [
                {
                    "AttributeName": "entryId",
                    "KeyType": "HASH"
                }
            ],
            "Projection": {
                "ProjectionType": "ALL"
            }
        },
        {
            "IndexName": "UserIdIndex", 
            "KeySchema": [
                {
                    "AttributeName": "userId",
                    "KeyType": "HASH"
                }
            ],
            "Projection": {
                "ProjectionType": "ALL"
            }
        }]' \
    --billing-mode PAY_PER_REQUEST

echo "Waiting for table to become active..."
aws dynamodb wait table-exists --table-name $TABLE_NAME --region $REGION

echo "✅ Bookings table created successfully!"

# Show table description
echo "Table details:"
aws dynamodb describe-table --table-name $TABLE_NAME --region $REGION --query 'Table.{TableName:TableName,Status:TableStatus,GSI:GlobalSecondaryIndexes[].{IndexName:IndexName,Status:IndexStatus}}' 