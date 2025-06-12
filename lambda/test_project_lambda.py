import json
import os

# Set environment variables that the Lambda function expects
os.environ['PROJECTS_TABLE'] = 'Projects'
os.environ['TASKS_TABLE'] = 'Tasks'
os.environ['ACTIVITIES_TABLE'] = 'Activities'
os.environ['INSTRUMENTS_TABLE'] = 'Instruments'

from project_management import lambda_handler

def test_project_get():
    # Simulate the exact event that would come from API Gateway
    event = {
        'httpMethod': 'GET',
        'path': '/projects/fa93a931-42b4-4cbc-982a-425e04766577',
        'requestContext': {
            'authorizer': {
                'claims': {
                    'sub': 'test-user-id'
                }
            }
        },
        'body': None
    }
    
    context = {}  # Mock context
    
    try:
        response = lambda_handler(event, context)
        print(f"✅ Lambda function succeeded!")
        print(f"Status Code: {response['statusCode']}")
        print(f"Headers: {json.dumps(response['headers'], indent=2)}")
        print(f"Body: {response['body']}")
        
    except Exception as e:
        print(f"❌ Lambda function failed: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    test_project_get() 