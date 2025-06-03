import json
import boto3
import os
from datetime import datetime

# This script will help debug the tasks endpoint issue

def debug_tasks():
    print("=== Debugging Tasks Endpoint ===")
    
    # Check environment variables
    print("\n1. Environment Variables:")
    required_vars = ['PROJECTS_TABLE', 'TASKS_TABLE', 'ACTIVITIES_TABLE', 'INSTRUMENTS_TABLE']
    for var in required_vars:
        value = os.environ.get(var)
        print(f"   {var}: {value}")
        if not value:
            print(f"   ❌ {var} is not set!")
    
    # Check DynamoDB connection
    print("\n2. DynamoDB Connection Test:")
    try:
        dynamodb = boto3.resource('dynamodb')
        
        # Check tasks table
        tasks_table_name = os.environ.get('TASKS_TABLE', 'protrack-tasks')
        print(f"   Testing tasks table: {tasks_table_name}")
        
        tasks_table = dynamodb.Table(tasks_table_name)
        
        # Try to describe the table
        table_description = tasks_table.meta.client.describe_table(TableName=tasks_table_name)
        print(f"   ✅ Tasks table exists")
        print(f"   Table status: {table_description['Table']['TableStatus']}")
        print(f"   Key schema: {table_description['Table']['KeySchema']}")
        
        # Try a scan to see if there's any data
        response = tasks_table.scan(Limit=1)
        print(f"   Items in table: {response['Count']}")
        
    except Exception as e:
        print(f"   ❌ Error accessing tasks table: {str(e)}")
    
    # Test query with the specific project ID
    print("\n3. Testing Query for Project ID: fa93a931-42b4-4cbc-982a-425e04766577")
    try:
        project_id = "fa93a931-42b4-4cbc-982a-425e04766577"
        response = tasks_table.query(
            KeyConditionExpression='projectId = :pid',
            ExpressionAttributeValues={':pid': project_id}
        )
        print(f"   ✅ Query successful")
        print(f"   Items found: {response['Count']}")
        if response['Items']:
            print(f"   Sample item: {response['Items'][0]}")
        else:
            print("   No tasks found for this project")
            
    except Exception as e:
        print(f"   ❌ Error querying tasks: {str(e)}")
    
    # Test lambda handler simulation
    print("\n4. Simulating Lambda Handler:")
    try:
        # Simulate the event that would come from API Gateway
        test_event = {
            'httpMethod': 'GET',
            'path': '/projects/fa93a931-42b4-4cbc-982a-425e04766577/tasks',
            'requestContext': {
                'authorizer': {
                    'claims': {
                        'sub': 'test-user-id'
                    }
                }
            },
            'body': None
        }
        
        # Simulate the handler logic
        path_parts = test_event['path'].strip('/').split('/')
        print(f"   Path parts: {path_parts}")
        print(f"   Should match: len=3, part[0]='projects', part[2]='tasks'")
        print(f"   Actual: len={len(path_parts)}, part[0]='{path_parts[0]}', part[2]='{path_parts[2] if len(path_parts) > 2 else 'N/A'}'")
        
        if len(path_parts) == 3 and path_parts[2] == 'tasks':
            print("   ✅ Path routing should work")
            project_id = path_parts[1]
            print(f"   Project ID extracted: {project_id}")
        else:
            print("   ❌ Path routing issue")
            
    except Exception as e:
        print(f"   ❌ Error simulating handler: {str(e)}")

if __name__ == "__main__":
    debug_tasks() 