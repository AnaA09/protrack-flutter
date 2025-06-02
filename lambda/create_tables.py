import boto3
import os

dynamodb = boto3.resource('dynamodb')

def create_tables():
    # Create Instruments table
    instruments_table = dynamodb.create_table(
        TableName='Instruments',
        KeySchema=[
            {
                'AttributeName': 'instrumentId',
                'KeyType': 'HASH'  # Partition key
            }
        ],
        AttributeDefinitions=[
            {
                'AttributeName': 'instrumentId',
                'AttributeType': 'S'
            },
            {
                'AttributeName': 'name',
                'AttributeType': 'S'
            }
        ],
        GlobalSecondaryIndexes=[
            {
                'IndexName': 'NameIndex',
                'KeySchema': [
                    {
                        'AttributeName': 'name',
                        'KeyType': 'HASH'
                    }
                ],
                'Projection': {
                    'ProjectionType': 'ALL'
                }
            }
        ],
        BillingMode='PAY_PER_REQUEST',
        Tags=[
            {
                'Key': 'Project',
                'Value': 'Protrack'
            }
        ]
    )

    # Create Projects table
    projects_table = dynamodb.create_table(
        TableName='Projects',
        KeySchema=[
            {
                'AttributeName': 'projectId',
                'KeyType': 'HASH'  # Partition key
            }
        ],
        AttributeDefinitions=[
            {
                'AttributeName': 'projectId',
                'AttributeType': 'S'
            }
        ],
        BillingMode='PAY_PER_REQUEST',
        Tags=[
            {
                'Key': 'Project',
                'Value': 'Protrack'
            }
        ]
    )

    # Create Tasks table
    tasks_table = dynamodb.create_table(
        TableName='Tasks',
        KeySchema=[
            {
                'AttributeName': 'taskId',
                'KeyType': 'HASH'  # Partition key
            },
            {
                'AttributeName': 'projectId',
                'KeyType': 'RANGE'  # Sort key
            }
        ],
        AttributeDefinitions=[
            {
                'AttributeName': 'taskId',
                'AttributeType': 'S'
            },
            {
                'AttributeName': 'projectId',
                'AttributeType': 'S'
            }
        ],
        BillingMode='PAY_PER_REQUEST',
        Tags=[
            {
                'Key': 'Project',
                'Value': 'Protrack'
            }
        ]
    )

    # Create Activities table
    activities_table = dynamodb.create_table(
        TableName='Activities',
        KeySchema=[
            {
                'AttributeName': 'activityId',
                'KeyType': 'HASH'  # Partition key
            },
            {
                'AttributeName': 'taskId',
                'KeyType': 'RANGE'  # Sort key
            }
        ],
        AttributeDefinitions=[
            {
                'AttributeName': 'activityId',
                'AttributeType': 'S'
            },
            {
                'AttributeName': 'taskId',
                'AttributeType': 'S'
            },
            {
                'AttributeName': 'projectId',
                'AttributeType': 'S'
            }
        ],
        GlobalSecondaryIndexes=[
            {
                'IndexName': 'ProjectIdIndex',
                'KeySchema': [
                    {
                        'AttributeName': 'projectId',
                        'KeyType': 'HASH'
                    }
                ],
                'Projection': {
                    'ProjectionType': 'ALL'
                }
            }
        ],
        BillingMode='PAY_PER_REQUEST',
        Tags=[
            {
                'Key': 'Project',
                'Value': 'Protrack'
            }
        ]
    )

    # Wait for tables to be created
    instruments_table.meta.client.get_waiter('table_exists').wait(TableName='Instruments')
    projects_table.meta.client.get_waiter('table_exists').wait(TableName='Projects')
    tasks_table.meta.client.get_waiter('table_exists').wait(TableName='Tasks')
    activities_table.meta.client.get_waiter('table_exists').wait(TableName='Activities')

    print("Tables created successfully!")

if __name__ == '__main__':
    create_tables() 