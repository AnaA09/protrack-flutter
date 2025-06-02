import json
import boto3
from user_management import lambda_handler

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

if __name__ == "__main__":
    print("Testing Lambda locally:")
    test_local()
    
    print("\nTesting Lambda in production:")
 #   test_prod() 