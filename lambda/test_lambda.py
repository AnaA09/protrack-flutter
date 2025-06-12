import json
import boto3
from user_management import lambda_handler
from project_management import lambda_handler as project_lambda_handler

def test_local():
    # Test event simulating API Gateway with Cognito authorizer
    test_event = {
        "requestContext": {
            "authorizer": {
                "claims": {
                    "sub": "test-user-123"
                }
            }
        },
        "httpMethod": "POST",
        "path": "/user",
        "body": json.dumps({
            "email": "test@example.com",
            "fullName": "Test User",
            "role": "Lab Assistant",
            "study": "BS Computer Science",
            "location": "San Francisco",
            "phone": "+1234567890"
        })
    }

    # Test all methods
    methods = ["GET", "POST", "PUT", "DELETE"]
    for method in methods:
        test_event["httpMethod"] = method
        print(f"\nTesting {method} method:")
        response = lambda_handler(test_event, None)
        print(f"Status Code: {response['statusCode']}")
        print(f"Response: {response['body']}")

def test_prod():
    # Initialize Lambda client
    lambda_client = boto3.client('lambda')
    
    # Test event
    test_event = {
        "requestContext": {
            "authorizer": {
                "claims": {
                    "sub": "test-user-123"
                }
            }
        },
        "httpMethod": "POST",
        "path": "/user",
        "body": json.dumps({
            "email": "test@example.com",
            "fullName": "Test User",
            "role": "Developer",
            "company": "Test Corp",
            "experience": 5,
            "education": "BS Computer Science",
            "location": "San Francisco",
            "phone": "+1234567890"
        })
    }

    # Test all methods
    methods = ["GET", "POST", "PUT", "DELETE"]
    for method in methods:
        test_event["httpMethod"] = method
        print(f"\nTesting {method} method in production:")
        response = lambda_client.invoke(
            FunctionName='UserMetadataManagement',
            Payload=json.dumps(test_event)
        )
        response_payload = json.loads(response['Payload'].read())
        print(f"Status Code: {response_payload['statusCode']}")
        print(f"Response: {response_payload['body']}")

def test_lambda_function():
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
        response = project_lambda_handler(event, context)
        print(f"✅ Lambda function succeeded!")
        print(f"Status Code: {response['statusCode']}")
        print(f"Headers: {json.dumps(response['headers'], indent=2)}")
        print(f"Body: {response['body']}")
        
    except Exception as e:
        print(f"❌ Lambda function failed: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    print("Testing Lambda locally:")
    test_local()
    
    print("\nTesting Lambda in production:")
 #   test_prod() 

    print("\nTesting Lambda function:")
    test_lambda_function() 