import json
import boto3
import os
from datetime import datetime
from typing import Dict, Any, List
import uuid
from decimal import Decimal

# Custom JSON encoder to handle DynamoDB Decimal objects
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            # Convert decimal to int if it's a whole number, otherwise to float
            if obj % 1 == 0:
                return int(obj)
            else:
                return float(obj)
        return super(DecimalEncoder, self).default(obj)

dynamodb = boto3.resource('dynamodb')
projects_table = dynamodb.Table(os.environ['PROJECTS_TABLE'])
tasks_table = dynamodb.Table(os.environ['TASKS_TABLE'])
activities_table = dynamodb.Table(os.environ['ACTIVITIES_TABLE'])
instruments_table = dynamodb.Table(os.environ['INSTRUMENTS_TABLE'])

# CORS headers configuration
CORS_HEADERS = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token',
    'Access-Control-Allow-Credentials': 'true'
}

def create_response(status_code: int, body: Any) -> Dict[str, Any]:
    # Use custom encoder for JSON serialization
    if isinstance(body, str):
        json_body = body
    else:
        json_body = json.dumps(body, cls=DecimalEncoder)
    
    return {
        'statusCode': status_code,
        'headers': CORS_HEADERS,
        'body': json_body
    }

# Instrument Management Functions
def create_instrument(instrument_data: Dict[str, Any]) -> Dict[str, Any]:
    timestamp = datetime.utcnow().isoformat()
    instrument_id = str(uuid.uuid4())
    
    item = {
        'instrumentId': instrument_id,
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'status': 'AVAILABLE',  # AVAILABLE, IN_USE, MAINTENANCE, RETIRED
        **instrument_data
    }
    
    instruments_table.put_item(Item=item)
    return item

def get_instrument(instrument_id: str) -> Dict[str, Any]:
    response = instruments_table.get_item(Key={'instrumentId': instrument_id})
    return response.get('Item', {})

def update_instrument(instrument_id: str, instrument_data: Dict[str, Any]) -> Dict[str, Any]:
    timestamp = datetime.utcnow().isoformat()
    update_expr = 'SET updatedAt = :ts'
    expr_attrs = {':ts': timestamp}
    expr_names = {}
    
    # Filter out system fields that shouldn't be updated by the user
    system_fields = {'updatedAt', 'createdAt', 'instrumentId'}
    filtered_data = {k: v for k, v in instrument_data.items() if k not in system_fields}
    
    for key, value in filtered_data.items():
        update_expr += f', #{key} = :{key}'
        expr_attrs[f':{key}'] = value
        expr_names[f'#{key}'] = key
    
    response = instruments_table.update_item(
        Key={'instrumentId': instrument_id},
        UpdateExpression=update_expr,
        ExpressionAttributeValues=expr_attrs,
        ExpressionAttributeNames=expr_names,
        ReturnValues='ALL_NEW'
    )
    return response.get('Attributes', {})

def delete_instrument(instrument_id: str) -> None:
    instruments_table.delete_item(Key={'instrumentId': instrument_id})

def get_instruments_by_name(name: str) -> List[Dict[str, Any]]:
    response = instruments_table.query(
        IndexName='NameIndex',
        KeyConditionExpression='#name = :name',
        ExpressionAttributeNames={'#name': 'name'},
        ExpressionAttributeValues={':name': name}
    )
    return response.get('Items', [])

# Project Management Functions
def create_project(user_id: str, project_data: Dict[str, Any]) -> Dict[str, Any]:
    timestamp = datetime.utcnow().isoformat()
    project_id = str(uuid.uuid4())
    
    # Validate required instruments
    required_instruments = project_data.get('requiredInstruments', [])
    for instrument_id in required_instruments:
        instrument = get_instrument(instrument_id)
        if not instrument:
            raise ValueError(f"Instrument {instrument_id} not found")
    
    # Filter out system fields that should be server-generated
    system_fields = {'projectId', 'createdAt', 'updatedAt', 'createdBy'}
    filtered_data = {k: v for k, v in project_data.items() if k not in system_fields}
    
    item = {
        'projectId': project_id,
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'createdBy': user_id,
        'status': 'OPEN',
        'requiredInstruments': required_instruments,
        **filtered_data
    }
    
    projects_table.put_item(Item=item)
    return item

def normalize_project_data(item: Dict[str, Any]) -> Dict[str, Any]:
    """Normalize project data to ensure all required fields have proper defaults"""
    if not item:
        return item
    
    # Ensure all required fields have proper defaults
    if 'status' not in item or item['status'] is None:
        item['status'] = 'OPEN'
    
    if 'requiredInstruments' not in item:
        item['requiredInstruments'] = []
    
    if 'tags' not in item:
        item['tags'] = []
    
    # Ensure string fields are never null
    string_fields = ['name', 'description', 'priority', 'status', 'createdBy']
    for field in string_fields:
        if field in item and item[field] is None:
            item[field] = ''
    
    return item

def get_project(project_id: str) -> Dict[str, Any]:
    response = projects_table.get_item(Key={'projectId': project_id})
    item = response.get('Item', {})
    return normalize_project_data(item)

def update_project(project_id: str, project_data: Dict[str, Any]) -> Dict[str, Any]:
    print(f"Updating project {project_id} with data: {project_data}")
    
    # First check if project exists
    existing_project = get_project(project_id)
    if not existing_project:
        raise ValueError(f"Project {project_id} not found")
    
    timestamp = datetime.utcnow().isoformat()
    update_expr = 'SET updatedAt = :ts'
    expr_attrs = {':ts': timestamp}
    expr_names = {}
    
    # Filter out system fields that shouldn't be updated by the user
    system_fields = {'updatedAt', 'createdAt', 'projectId', 'createdBy'}
    filtered_data = {k: v for k, v in project_data.items() if k not in system_fields}
    
    # Ensure required fields have default values if missing
    if 'status' not in filtered_data and 'status' not in existing_project:
        filtered_data['status'] = 'OPEN'
    
    if 'requiredInstruments' not in filtered_data and 'requiredInstruments' not in existing_project:
        filtered_data['requiredInstruments'] = []
    
    if 'tags' not in filtered_data and 'tags' not in existing_project:
        filtered_data['tags'] = []
    
    # Ensure string fields are not null
    string_fields = ['name', 'description', 'priority', 'status']
    for field in string_fields:
        if field in filtered_data and filtered_data[field] is None:
            filtered_data[field] = ''
    
    for key, value in filtered_data.items():
        update_expr += f', #{key} = :{key}'
        expr_attrs[f':{key}'] = value
        expr_names[f'#{key}'] = key
    
    print(f"Update expression: {update_expr}")
    print(f"Expression attribute values: {expr_attrs}")
    print(f"Expression attribute names: {expr_names}")
    
    try:
        response = projects_table.update_item(
            Key={'projectId': project_id},
            UpdateExpression=update_expr,
            ExpressionAttributeValues=expr_attrs,
            ExpressionAttributeNames=expr_names,
            ReturnValues='ALL_NEW'
        )
        updated_item = response.get('Attributes', {})
        
        # Ensure the returned item has all required fields with proper defaults
        if 'createdAt' not in updated_item:
            updated_item['createdAt'] = existing_project.get('createdAt', timestamp)
        
        if 'createdBy' not in updated_item:
            updated_item['createdBy'] = existing_project.get('createdBy', '')
        
        return normalize_project_data(updated_item)
    except Exception as e:
        print(f"Error updating project: {str(e)}")
        raise

def delete_project(project_id: str) -> None:
    # First, delete all tasks and activities associated with the project
    tasks = tasks_table.query(
        IndexName='ProjectIdIndex',
        KeyConditionExpression='projectId = :pid',
        ExpressionAttributeValues={':pid': project_id}
    )
    
    for task in tasks.get('Items', []):
        task_id = task['taskId']
        # Delete activities for this task using TaskIdIndex GSI
        activities = activities_table.query(
            IndexName='TaskIdIndex',
            KeyConditionExpression='taskId = :tid',
            ExpressionAttributeValues={':tid': task_id}
        )
        for activity in activities.get('Items', []):
            activities_table.delete_item(
                Key={
                    'activityId': activity['activityId'],
                    'taskId': task_id
                }
            )
        # Delete the task
        tasks_table.delete_item(
            Key={
                'taskId': task_id,
                'projectId': project_id
            }
        )
    
    # Finally, delete the project
    projects_table.delete_item(Key={'projectId': project_id})

# Task Management Functions
def create_task(project_id: str, task_data: Dict[str, Any]) -> Dict[str, Any]:
    timestamp = datetime.utcnow().isoformat()
    task_id = str(uuid.uuid4())
    
    # Validate required instruments
    required_instruments = task_data.get('requiredInstruments', [])
    for instrument_id in required_instruments:
        instrument = get_instrument(instrument_id)
        if not instrument:
            raise ValueError(f"Instrument {instrument_id} not found")
    
    # Filter out system fields that should be server-generated
    system_fields = {'taskId', 'projectId', 'createdAt', 'updatedAt'}
    filtered_data = {k: v for k, v in task_data.items() if k not in system_fields}
    
    item = {
        'taskId': task_id,
        'projectId': project_id,
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'status': 'OPEN',
        'requiredInstruments': required_instruments,
        **filtered_data
    }
    
    tasks_table.put_item(Item=item)
    return item

def get_task(task_id: str, project_id: str) -> Dict[str, Any]:
    response = tasks_table.get_item(
        Key={
            'taskId': task_id,
            'projectId': project_id
        }
    )
    return response.get('Item', {})

def update_task(task_id: str, project_id: str, task_data: Dict[str, Any]) -> Dict[str, Any]:
    timestamp = datetime.utcnow().isoformat()
    update_expr = 'SET updatedAt = :ts'
    expr_attrs = {':ts': timestamp}
    expr_names = {}
    
    # Filter out system fields that shouldn't be updated by the user
    system_fields = {'updatedAt', 'createdAt', 'taskId', 'projectId'}
    filtered_data = {k: v for k, v in task_data.items() if k not in system_fields}
    
    for key, value in filtered_data.items():
        update_expr += f', #{key} = :{key}'
        expr_attrs[f':{key}'] = value
        expr_names[f'#{key}'] = key
    
    response = tasks_table.update_item(
        Key={
            'taskId': task_id,
            'projectId': project_id
        },
        UpdateExpression=update_expr,
        ExpressionAttributeValues=expr_attrs,
        ExpressionAttributeNames=expr_names,
        ReturnValues='ALL_NEW'
    )
    return response.get('Attributes', {})

def delete_task(task_id: str, project_id: str) -> None:
    # First, delete all activities associated with the task using TaskIdIndex GSI
    activities = activities_table.query(
        IndexName='TaskIdIndex',
        KeyConditionExpression='taskId = :tid',
        ExpressionAttributeValues={':tid': task_id}
    )
    for activity in activities.get('Items', []):
        activities_table.delete_item(
            Key={
                'activityId': activity['activityId'],
                'taskId': task_id
            }
        )
    
    # Then delete the task
    tasks_table.delete_item(
        Key={
            'taskId': task_id,
            'projectId': project_id
        }
    )

# Activity Management Functions
def create_activity(task_id: str, project_id: str, activity_data: Dict[str, Any]) -> Dict[str, Any]:
    timestamp = datetime.utcnow().isoformat()
    activity_id = str(uuid.uuid4())
    
    # Validate used instruments
    used_instruments = activity_data.get('usedInstruments', [])
    for instrument_id in used_instruments:
        instrument = get_instrument(instrument_id)
        if not instrument:
            raise ValueError(f"Instrument {instrument_id} not found")
        if instrument['status'] != 'AVAILABLE':
            raise ValueError(f"Instrument {instrument_id} is not available")
    
    # Filter out system fields that should be server-generated
    system_fields = {'activityId', 'taskId', 'projectId', 'createdAt', 'updatedAt'}
    filtered_data = {k: v for k, v in activity_data.items() if k not in system_fields}
    
    item = {
        'activityId': activity_id,
        'taskId': task_id,
        'projectId': project_id,
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'status': 'IN_PROGRESS',
        'usedInstruments': used_instruments,
        **filtered_data
    }
    
    # Update instrument status to IN_USE
    for instrument_id in used_instruments:
        update_instrument(instrument_id, {'status': 'IN_USE'})
    
    activities_table.put_item(Item=item)
    return item

def get_activity(activity_id: str, task_id: str) -> Dict[str, Any]:
    response = activities_table.get_item(
        Key={
            'activityId': activity_id,
            'taskId': task_id
        }
    )
    return response.get('Item', {})

def update_activity(activity_id: str, task_id: str, activity_data: Dict[str, Any]) -> Dict[str, Any]:
    timestamp = datetime.utcnow().isoformat()
    update_expr = 'SET updatedAt = :ts'
    expr_attrs = {':ts': timestamp}
    expr_names = {}
    
    # Handle instrument status updates
    if 'status' in activity_data and activity_data['status'] in ['COMPLETED', 'FAILED']:
        # Get current activity to check used instruments
        current_activity = get_activity(activity_id, task_id)
        if current_activity:
            # Release all instruments
            for instrument_id in current_activity.get('usedInstruments', []):
                update_instrument(instrument_id, {'status': 'AVAILABLE'})
    
    # Filter out system fields that shouldn't be updated by the user
    system_fields = {'updatedAt', 'createdAt', 'activityId', 'taskId', 'projectId'}
    filtered_data = {k: v for k, v in activity_data.items() if k not in system_fields}
    
    for key, value in filtered_data.items():
        update_expr += f', #{key} = :{key}'
        expr_attrs[f':{key}'] = value
        expr_names[f'#{key}'] = key
    
    response = activities_table.update_item(
        Key={
            'activityId': activity_id,
            'taskId': task_id
        },
        UpdateExpression=update_expr,
        ExpressionAttributeValues=expr_attrs,
        ExpressionAttributeNames=expr_names,
        ReturnValues='ALL_NEW'
    )
    return response.get('Attributes', {})

def delete_activity(activity_id: str, task_id: str) -> None:
    activities_table.delete_item(
        Key={
            'activityId': activity_id,
            'taskId': task_id
        }
    )

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
        path_parts = path.strip('/').split('/')
        
        # Parse request body if present
        request_body = event.get('body') or '{}'
        body = json.loads(request_body)
        
        # Route the request based on the path
        if path_parts[0] == 'instruments':
            if len(path_parts) == 1:  # /instruments
                if http_method == 'GET':
                    # List all instruments
                    response = instruments_table.scan()
                    return create_response(200, response.get('Items', []))
                elif http_method == 'POST':
                    # Create new instrument
                    instrument = create_instrument(body)
                    return create_response(201, instrument)
            
            elif len(path_parts) == 2:  # /instruments/{instrumentId}
                instrument_id = path_parts[1]
                if http_method == 'GET':
                    instrument = get_instrument(instrument_id)
                    return create_response(200, instrument)
                elif http_method == 'PUT':
                    instrument = update_instrument(instrument_id, body)
                    return create_response(200, instrument)
                elif http_method == 'DELETE':
                    delete_instrument(instrument_id)
                    return create_response(204, '')
            
            elif len(path_parts) == 3 and path_parts[1] == 'search':  # /instruments/search/{name}
                name = path_parts[2]
                instruments = get_instruments_by_name(name)
                return create_response(200, instruments)
        
        elif path_parts[0] == 'projects':
            if len(path_parts) == 1:  # /projects
                if http_method == 'GET':
                    # List all projects
                    response = projects_table.scan()
                    projects = response.get('Items', [])
                    # Normalize all project data
                    normalized_projects = [normalize_project_data(project) for project in projects]
                    return create_response(200, normalized_projects)
                elif http_method == 'POST':
                    # Create new project
                    project = create_project(user_id, body)
                    return create_response(201, project)
            
            elif len(path_parts) == 2:  # /projects/{projectId}
                project_id = path_parts[1]
                if http_method == 'GET':
                    project = get_project(project_id)
                    return create_response(200, project)
                elif http_method == 'PUT':
                    project = update_project(project_id, body)
                    return create_response(200, project)
                elif http_method == 'DELETE':
                    delete_project(project_id)
                    return create_response(204, '')
            
            elif len(path_parts) == 3 and path_parts[2] == 'tasks':  # /projects/{projectId}/tasks
                project_id = path_parts[1]
                if http_method == 'GET':
                    # List all tasks for project using GSI
                    response = tasks_table.query(
                        IndexName='ProjectIdIndex',
                        KeyConditionExpression='projectId = :pid',
                        ExpressionAttributeValues={':pid': project_id}
                    )
                    return create_response(200, response.get('Items', []))
                elif http_method == 'POST':
                    # Create new task
                    task = create_task(project_id, body)
                    return create_response(201, task)
            
            elif len(path_parts) == 4 and path_parts[2] == 'tasks':  # /projects/{projectId}/tasks/{taskId}
                project_id = path_parts[1]
                task_id = path_parts[3]
                if http_method == 'GET':
                    task = get_task(task_id, project_id)
                    return create_response(200, task)
                elif http_method == 'PUT':
                    task = update_task(task_id, project_id, body)
                    return create_response(200, task)
                elif http_method == 'DELETE':
                    delete_task(task_id, project_id)
                    return create_response(204, '')
            
            elif len(path_parts) == 5 and path_parts[2] == 'tasks' and path_parts[4] == 'activities':  # /projects/{projectId}/tasks/{taskId}/activities
                project_id = path_parts[1]
                task_id = path_parts[3]
                if http_method == 'GET':
                    # List all activities for task using TaskIdIndex GSI
                    response = activities_table.query(
                        IndexName='TaskIdIndex',
                        KeyConditionExpression='taskId = :tid',
                        ExpressionAttributeValues={':tid': task_id}
                    )
                    return create_response(200, response.get('Items', []))
                elif http_method == 'POST':
                    # Create new activity
                    activity = create_activity(task_id, project_id, body)
                    return create_response(201, activity)
            
            elif len(path_parts) == 6 and path_parts[2] == 'tasks' and path_parts[4] == 'activities':  # /projects/{projectId}/tasks/{taskId}/activities/{activityId}
                project_id = path_parts[1]
                task_id = path_parts[3]
                activity_id = path_parts[5]
                if http_method == 'GET':
                    activity = get_activity(activity_id, task_id)
                    return create_response(200, activity)
                elif http_method == 'PUT':
                    activity = update_activity(activity_id, task_id, body)
                    return create_response(200, activity)
                elif http_method == 'DELETE':
                    delete_activity(activity_id, task_id)
                    return create_response(204, '')
        
        return create_response(400, {'error': 'Invalid path'})
            
    except Exception as e:
        return create_response(500, {'error': str(e)}) 