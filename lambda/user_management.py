import json
import boto3
import os
from datetime import datetime
from typing import Dict, Any

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['USER_METADATA_TABLE'])

# CORS headers configuration
CORS_HEADERS = {
    'Access-Control-Allow-Origin': '*',  # In production, replace with your specific domain
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token',
    'Access-Control-Allow-Credentials': 'true'
}

def get_user_metadata(user_id: str) -> Dict[str, Any]:
    response = table.get_item(Key={'userId': user_id})
    return response.get('Item', {})

def create_user_metadata(user_id: str, user_data: Dict[str, Any]) -> Dict[str, Any]:
    timestamp = datetime.utcnow().isoformat()
    item = {
        'userId': user_id,
        'createdAt': timestamp,
        'updatedAt': timestamp,
        **user_data
    }
    table.put_item(Item=item)
    return item

def update_user_metadata(user_id: str, user_data: Dict[str, Any]) -> Dict[str, Any]:
    timestamp = datetime.utcnow().isoformat()
    update_expr = 'SET updatedAt = :ts'
    expr_attrs = {':ts': timestamp}
    expr_names = {}
    
    for key, value in user_data.items():
        update_expr += f', #{key} = :{key}'
        expr_attrs[f':{key}'] = value
        expr_names[f'#{key}'] = key
    
    response = table.update_item(
        Key={'userId': user_id},
        UpdateExpression=update_expr,
        ExpressionAttributeValues=expr_attrs,
        ExpressionAttributeNames=expr_names,
        ReturnValues='ALL_NEW'
    )
    return response.get('Attributes', {})

def delete_user_metadata(user_id: str) -> None:
    table.delete_item(Key={'userId': user_id})

def create_response(status_code: int, body: str) -> Dict[str, Any]:
    return {
        'statusCode': status_code,
        'headers': CORS_HEADERS,
        'body': body
    }

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    try:
        # Handle OPTIONS request for CORS preflight
        if event['httpMethod'] == 'OPTIONS':
            return create_response(200, '')

        # Get user ID from Cognito authorizer
        user_id = event['requestContext']['authorizer']['claims']['sub']
        
        # Get HTTP method and path
        http_method = event['httpMethod']
        path = event['path']
        
        if http_method == 'GET':
            user_data = get_user_metadata(user_id)
            return create_response(200, json.dumps(user_data))
            
        elif http_method == 'POST':
            body = json.loads(event['body'])
            user_data = create_user_metadata(user_id, body)
            return create_response(201, json.dumps(user_data))
            
        elif http_method == 'PUT':
            body = json.loads(event['body'])
            user_data = update_user_metadata(user_id, body)
            return create_response(200, json.dumps(user_data))
            
        elif http_method == 'DELETE':
            delete_user_metadata(user_id)
            return create_response(204, '')
            
        else:
            return create_response(400, json.dumps({'error': 'Invalid HTTP method'}))
            
    except Exception as e:
        return create_response(500, json.dumps({'error': str(e)})) 