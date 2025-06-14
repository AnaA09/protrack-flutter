import json
import boto3
import os
import logging
from datetime import datetime

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

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

def generate_project_report(project_id, user_id):
    """Generate a report for a project"""
    logger.info(f"Generating project report for project: {project_id}, user: {user_id}")
    
    # This is a placeholder for future AI-based report generation
    # In a real implementation, this would connect to a language model API
    
    return {
        "status": "not_implemented",
        "message": "AI report generation is currently disabled"
    }

def generate_task_report(project_id, task_id, user_id):
    """Generate a report for a task"""
    logger.info(f"Generating task report for project: {project_id}, task: {task_id}, user: {user_id}")
    
    # This is a placeholder for future AI-based report generation
    
    return {
        "status": "not_implemented",
        "message": "AI report generation is currently disabled"
    }

def generate_activity_summary(project_id, task_id, activity_id, user_id):
    """Generate a summary for an activity"""
    logger.info(f"Generating activity summary for project: {project_id}, task: {task_id}, activity: {activity_id}, user: {user_id}")
    
    # This is a placeholder for future AI-based summary generation
    
    return {
        "status": "not_implemented",
        "message": "AI summary generation is currently disabled"
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
