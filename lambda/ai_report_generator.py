import json
import boto3
import os
import logging
from datetime import datetime
from botocore.exceptions import ClientError, NoCredentialsError

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')
bedrock_runtime = boto3.client('bedrock-runtime', region_name=os.environ.get('AWS_REGION', 'us-east-1'))

# DynamoDB table names from environment variables
PROJECTS_TABLE = os.environ.get('PROJECTS_TABLE', 'Projects')
TASKS_TABLE = os.environ.get('TASKS_TABLE', 'Tasks')
ACTIVITIES_TABLE = os.environ.get('ACTIVITIES_TABLE', 'Activities')

# Bedrock model configuration
BEDROCK_MODEL_ID = os.environ.get('BEDROCK_MODEL_ID', 'meta.llama2-70b-chat-v1')

# CORS headers configuration
CORS_HEADERS = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token',
    'Access-Control-Allow-Credentials': 'true'
}

def create_response(status_code, body):
    """Create a standardized API response with CORS headers"""
    if isinstance(body, str):
        json_body = body
    else:
        json_body = json.dumps(body)
    
    response = {
        'statusCode': status_code,
        'headers': CORS_HEADERS,
        'body': json_body
    }
    return response

def get_activity_from_dynamodb(project_id, task_id, activity_id, user_id):
    """Retrieve activity details from DynamoDB"""
    try:
        table = dynamodb.Table(ACTIVITIES_TABLE)
        response = table.get_item(
            Key={
                'activityId': activity_id,
                'taskId': task_id
            }
        )
        
        activity = response.get('Item')
        if not activity:
            return None
            
        # Check if the activity belongs to the correct project and user (optional validation)
        if activity.get('projectId') != project_id:
            return None
            
        return activity
        
    except ClientError as e:
        logger.error(f"Error retrieving activity from DynamoDB: {str(e)}")
        raise

def get_activities_for_task(project_id, task_id, user_id):
    """Retrieve all activities for a task from DynamoDB"""
    try:
        table = dynamodb.Table(ACTIVITIES_TABLE)
        response = table.query(
            IndexName='TaskIdIndex',  # Using the actual GSI name from existing code
            KeyConditionExpression='taskId = :task_id',
            FilterExpression='projectId = :project_id',
            ExpressionAttributeValues={
                ':task_id': task_id,
                ':project_id': project_id
            }
        )
        return response.get('Items', [])
        
    except ClientError as e:
        logger.error(f"Error retrieving activities for task: {str(e)}")
        raise

def get_tasks_for_project(project_id, user_id):
    """Retrieve all tasks for a project from DynamoDB"""
    try:
        table = dynamodb.Table(TASKS_TABLE)
        response = table.query(
            IndexName='ProjectIdIndex',  # Using the actual GSI name from existing code
            KeyConditionExpression='projectId = :project_id',
            ExpressionAttributeValues={
                ':project_id': project_id
            }
        )
        return response.get('Items', [])
        
    except ClientError as e:
        logger.error(f"Error retrieving tasks for project: {str(e)}")
        raise

def call_bedrock_llama(prompt, max_tokens=2048):
    """Call AWS Bedrock with Llama model to generate text"""
    try:
        # Prepare the request body for Llama model
        request_body = {
            "prompt": f"[INST] {prompt} [/INST]",
            "max_gen_len": max_tokens,
            "temperature": 0.7,
            "top_p": 0.9
        }
        
        # Call Bedrock
        response = bedrock_runtime.invoke_model(
            modelId=BEDROCK_MODEL_ID,
            body=json.dumps(request_body),
            contentType='application/json',
            accept='application/json'
        )
        
        # Parse response
        response_body = json.loads(response['body'].read())
        generated_text = response_body.get('generation', '').strip()
        
        return {
            'success': True,
            'text': generated_text
        }
        
    except NoCredentialsError:
        return {
            'success': False,
            'error': 'AWS credentials not found or insufficient permissions for Bedrock'
        }
    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'AccessDeniedException':
            return {
                'success': False,
                'error': 'Access denied to AWS Bedrock. Please check IAM permissions'
            }
        elif error_code == 'ValidationException':
            return {
                'success': False,
                'error': 'Invalid request to Bedrock model'
            }
        else:
            return {
                'success': False,
                'error': f'Bedrock API error: {str(e)}'
            }
    except Exception as e:
        return {
            'success': False,
            'error': f'Unexpected error calling Bedrock: {str(e)}'
        }

def update_activity_ai_report(activity_id, task_id, ai_report):
    """Update activity record with AI report in DynamoDB"""
    try:
        table = dynamodb.Table(ACTIVITIES_TABLE)
        table.update_item(
            Key={
                'activityId': activity_id,
                'taskId': task_id
            },
            UpdateExpression='SET AI_report = :ai_report, updatedAt = :updated_at',
            ExpressionAttributeValues={
                ':ai_report': ai_report,
                ':updated_at': datetime.utcnow().isoformat()
            }
        )
        return True
    except ClientError as e:
        logger.error(f"Error updating activity AI report: {str(e)}")
        return False

def update_task_ai_report(task_id, project_id, ai_report):
    """Update task record with AI report in DynamoDB"""
    try:
        table = dynamodb.Table(TASKS_TABLE)
        table.update_item(
            Key={
                'taskId': task_id,
                'projectId': project_id
            },
            UpdateExpression='SET AI_report = :ai_report, updatedAt = :updated_at',
            ExpressionAttributeValues={
                ':ai_report': ai_report,
                ':updated_at': datetime.utcnow().isoformat()
            }
        )
        return True
    except ClientError as e:
        logger.error(f"Error updating task AI report: {str(e)}")
        return False

def update_project_ai_report(project_id, ai_report):
    """Update project record with AI report in DynamoDB"""
    try:
        table = dynamodb.Table(PROJECTS_TABLE)
        table.update_item(
            Key={
                'projectId': project_id
            },
            UpdateExpression='SET AI_report = :ai_report, updatedAt = :updated_at',
            ExpressionAttributeValues={
                ':ai_report': ai_report,
                ':updated_at': datetime.utcnow().isoformat()
            }
        )
        return True
    except ClientError as e:
        logger.error(f"Error updating project AI report: {str(e)}")
        return False

def generate_project_report(project_id, user_id):
    """Generate a report for a project"""
    logger.info(f"Generating project report for project: {project_id}, user: {user_id}")
    
    try:
        # Get all tasks for the project
        tasks = get_tasks_for_project(project_id, user_id)
        
        if not tasks:
            return {
                "status": "no_data",
                "message": "No tasks found for this project"
            }
        
        # Prepare context for LLM
        tasks_context = []
        for task in tasks:
            task_info = {
                'name': task.get('Name', 'Unnamed Task'),
                'description': task.get('Description', ''),
                'status': task.get('Status', ''),
                'priority': task.get('Priority', ''),
                'ai_report': task.get('AI_report', 'No AI report available')
            }
            tasks_context.append(task_info)
        
        # Create prompt for project report
        prompt = f"""
        Generate a comprehensive project report summary based on the following tasks data:
        
        Project Tasks:
        {json.dumps(tasks_context, indent=2)}
        
        Please provide:
        1. Overall project progress summary
        2. Key achievements and milestones
        3. Current status overview
        4. Priority areas requiring attention
        5. Recommendations for next steps
        
        Keep the report concise but informative, focusing on actionable insights.
        """
        
        # Call Bedrock
        bedrock_response = call_bedrock_llama(prompt)
        
        if not bedrock_response['success']:
            return {
                "status": "error",
                "message": bedrock_response['error']
            }
        
        ai_report = bedrock_response['text']
        
        # Store the report back to DynamoDB
        if update_project_ai_report(project_id, ai_report):
            return {
                "status": "success",
                "message": "Project report generated and stored successfully",
                "report": ai_report
            }
        else:
            return {
                "status": "partial_success",
                "message": "Project report generated but failed to store in database",
                "report": ai_report
            }
            
    except Exception as e:
        logger.error(f"Error generating project report: {str(e)}")
        return {
            "status": "error",
            "message": f"Failed to generate project report: {str(e)}"
        }

def generate_task_report(project_id, task_id, user_id):
    """Generate a report for a task"""
    logger.info(f"Generating task report for project: {project_id}, task: {task_id}, user: {user_id}")
    
    try:
        # Get all activities for the task
        activities = get_activities_for_task(project_id, task_id, user_id)
        
        if not activities:
            return {
                "status": "no_data",
                "message": "No activities found for this task"
            }
        
        # Prepare context for LLM
        activities_context = []
        for activity in activities:
            activity_info = {
                'name': activity.get('Name', 'Unnamed Activity'),
                'description': activity.get('Description', ''),
                'status': activity.get('Status', ''),
                'time_spent': activity.get('TimeSpent', 0),
                'ai_report': activity.get('AI_report', 'No AI summary available')
            }
            activities_context.append(activity_info)
        
        # Create prompt for task report
        prompt = f"""
        Generate a comprehensive task report based on the following activities data:
        
        Task Activities:
        {json.dumps(activities_context, indent=2)}
        
        Please provide:
        1. Task completion summary
        2. Time analysis and effort breakdown
        3. Key accomplishments from activities
        4. Current progress status
        5. Identified challenges or blockers
        6. Recommendations for task completion
        
        Focus on providing actionable insights and clear progress indicators.
        """
        
        # Call Bedrock
        bedrock_response = call_bedrock_llama(prompt)
        
        if not bedrock_response['success']:
            return {
                "status": "error",
                "message": bedrock_response['error']
            }
        
        ai_report = bedrock_response['text']
        
        # Store the report back to DynamoDB
        if update_task_ai_report(task_id, project_id, ai_report):
            return {
                "status": "success",
                "message": "Task report generated and stored successfully",
                "report": ai_report
            }
        else:
            return {
                "status": "partial_success",
                "message": "Task report generated but failed to store in database",
                "report": ai_report
            }
            
    except Exception as e:
        logger.error(f"Error generating task report: {str(e)}")
        return {
            "status": "error",
            "message": f"Failed to generate task report: {str(e)}"
        }

def generate_activity_summary(project_id, task_id, activity_id, user_id):
    """Generate a summary for an activity"""
    logger.info(f"Generating activity summary for project: {project_id}, task: {task_id}, activity: {activity_id}, user: {user_id}")
    
    try:
        # Get activity details from DynamoDB
        activity = get_activity_from_dynamodb(project_id, task_id, activity_id, user_id)
        
        if not activity:
            return {
                "status": "not_found",
                "message": "Activity not found or access denied"
            }
        
        # Prepare context for LLM
        activity_context = {
            'name': activity.get('Name', 'Unnamed Activity'),
            'description': activity.get('Description', ''),
            'status': activity.get('Status', ''),
            'time_spent': activity.get('TimeSpent', 0),
            'start_time': activity.get('StartTime', ''),
            'end_time': activity.get('EndTime', ''),
            'notes': activity.get('Notes', ''),
            'tags': activity.get('Tags', [])
        }
        
        # Create prompt for activity summary
        prompt = f"""
        Generate a concise but comprehensive summary for the following activity:
        
        Activity Details:
        {json.dumps(activity_context, indent=2)}
        
        Please provide:
        1. Brief overview of what was accomplished
        2. Time efficiency analysis
        3. Key outcomes or deliverables
        4. Notable challenges or insights
        5. Impact on overall progress
        
        Keep the summary focused and actionable, highlighting the most important aspects.
        """
        
        # Call Bedrock
        bedrock_response = call_bedrock_llama(prompt, max_tokens=1024)
        
        if not bedrock_response['success']:
            return {
                "status": "error",
                "message": bedrock_response['error']
            }
        
        ai_summary = bedrock_response['text']
        
        # Store the summary back to DynamoDB
        if update_activity_ai_report(activity_id, task_id, ai_summary):
            return {
                "status": "success",
                "message": "Activity summary generated and stored successfully",
                "summary": ai_summary
            }
        else:
            return {
                "status": "partial_success",
                "message": "Activity summary generated but failed to store in database",
                "summary": ai_summary
            }
            
    except Exception as e:
        logger.error(f"Error generating activity summary: {str(e)}")
        return {
            "status": "error",
            "message": f"Failed to generate activity summary: {str(e)}"
        }

def lambda_handler(event, context):
    """Main handler for AI report generation requests"""
    logger.info(f"Received event: {json.dumps(event)}")
    
    http_method = event.get('httpMethod')
    path = event.get('path', '')
    
    # Handle OPTIONS requests (for CORS)
    if http_method == 'OPTIONS':
        return create_response(200, '')
        
    # Extract user ID from authorization context
    user_id = event['requestContext']['authorizer']['claims']['sub']
    
    # Parse request body if present
    body = {}
    if event.get('body'):
        try:
            body = json.loads(event['body'])
        except json.JSONDecodeError:
            return create_response(400, {"error": "Invalid JSON in request body"})
    
    # Extract path components
    path_parts = list(filter(None, path.split('/')))
    
    try:
        # Handle AI report generation endpoints
        if len(path_parts) >= 3 and path_parts[0] == 'ai' and http_method == 'POST':
            
            # Project report: /ai/projects/{projectId}/report
            if path_parts[1] == 'projects' and len(path_parts) == 4 and path_parts[3] == 'report':
                project_id = path_parts[2]
                result = generate_project_report(project_id, user_id)
                return create_response(200, result)
                
            # Task report: /ai/projects/{projectId}/tasks/{taskId}/report
            elif path_parts[1] == 'projects' and path_parts[3] == 'tasks' and len(path_parts) == 6 and path_parts[5] == 'report':
                project_id = path_parts[2]
                task_id = path_parts[4]
                result = generate_task_report(project_id, task_id, user_id)
                return create_response(200, result)
                
            # Activity summary: /ai/projects/{projectId}/tasks/{taskId}/activities/{activityId}/summary
            elif path_parts[1] == 'projects' and path_parts[3] == 'tasks' and path_parts[5] == 'activities' and len(path_parts) == 8 and path_parts[7] == 'summary':
                project_id = path_parts[2]
                task_id = path_parts[4]
                activity_id = path_parts[6]
                result = generate_activity_summary(project_id, task_id, activity_id, user_id)
                return create_response(200, result)
        
        # If we get here, the endpoint wasn't found
        return create_response(404, {"error": "Not Found"})
        
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return create_response(500, {"error": f"Internal Server Error: {str(e)}"})
