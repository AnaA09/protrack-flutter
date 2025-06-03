import json
import boto3
import os
from datetime import datetime, timedelta
from typing import Dict, Any, List
import uuid
import logging

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource('dynamodb')

# Updated table structure for inventory management
instruments_table = dynamodb.Table(os.environ.get('INSTRUMENTS_TABLE', 'Instruments'))
bookings_table = dynamodb.Table(os.environ.get('BOOKINGS_TABLE', 'Bookings'))

# CORS headers configuration
CORS_HEADERS = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token',
    'Access-Control-Allow-Credentials': 'true'
}

def create_response(status_code: int, body: str) -> Dict[str, Any]:
    response = {
        'statusCode': status_code,
        'headers': CORS_HEADERS,
        'body': body
    }
    logger.info(f"Creating response: status={status_code}, body_length={len(body)}")
    return response

# Lab Management Functions
def create_lab(lab_data: Dict[str, Any]) -> Dict[str, Any]:
    timestamp = datetime.utcnow().isoformat()
    lab_id = str(uuid.uuid4())
    
    item = {
        'instrumentId': lab_id,  # Using existing table structure
        'type': 'LAB',
        'labId': lab_id,
        'name': lab_data.get('name'),
        'description': lab_data.get('description', ''),
        'location': lab_data.get('location', ''),
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'status': 'ACTIVE'
    }
    
    instruments_table.put_item(Item=item)
    return item

def get_labs() -> List[Dict[str, Any]]:
    logger.info("Getting all labs from database")
    try:
        response = instruments_table.scan(
            FilterExpression='#type = :type',
            ExpressionAttributeNames={'#type': 'type'},
            ExpressionAttributeValues={':type': 'LAB'}
        )
        labs = response.get('Items', [])
        logger.info(f"Found {len(labs)} labs")
        return labs
    except Exception as e:
        logger.error(f"Error getting labs: {str(e)}")
        raise

def get_lab(lab_id: str) -> Dict[str, Any]:
    response = instruments_table.get_item(Key={'instrumentId': lab_id})
    return response.get('Item', {})

# Category Management Functions
def create_category(lab_id: str, category_data: Dict[str, Any]) -> Dict[str, Any]:
    timestamp = datetime.utcnow().isoformat()
    category_id = str(uuid.uuid4())
    
    item = {
        'instrumentId': category_id,
        'type': 'CATEGORY',
        'labId': lab_id,
        'categoryId': category_id,
        'name': category_data.get('name'),
        'categoryType': category_data.get('categoryType'),  # 'INSTRUMENTS', 'CHEMICALS', 'CULTURES'
        'description': category_data.get('description', ''),
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'status': 'ACTIVE'
    }
    
    instruments_table.put_item(Item=item)
    return item

def get_categories_by_lab(lab_id: str) -> List[Dict[str, Any]]:
    response = instruments_table.scan(
        FilterExpression='#type = :type AND labId = :labId',
        ExpressionAttributeNames={'#type': 'type'},
        ExpressionAttributeValues={
            ':type': 'CATEGORY',
            ':labId': lab_id
        }
    )
    return response.get('Items', [])

# Entry Management Functions
def create_entry(category_id: str, entry_data: Dict[str, Any]) -> Dict[str, Any]:
    timestamp = datetime.utcnow().isoformat()
    entry_id = str(uuid.uuid4())
    
    item = {
        'instrumentId': entry_id,
        'type': 'ENTRY',
        'categoryId': category_id,
        'labId': entry_data.get('labId'),
        'entryId': entry_id,
        'name': entry_data.get('name'),
        'model': entry_data.get('model', ''),
        'manufacturer': entry_data.get('manufacturer', ''),
        'serialNumber': entry_data.get('serialNumber', ''),
        'description': entry_data.get('description', ''),
        'specifications': entry_data.get('specifications', {}),
        'quantity': entry_data.get('quantity', 1),
        'availableQuantity': entry_data.get('quantity', 1),
        'location': entry_data.get('location', ''),
        'calibrationDate': entry_data.get('calibrationDate'),
        'maintenanceSchedule': entry_data.get('maintenanceSchedule'),
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'status': 'AVAILABLE'  # AVAILABLE, IN_USE, MAINTENANCE, UNAVAILABLE
    }
    
    instruments_table.put_item(Item=item)
    return item

def get_entries_by_category(category_id: str) -> List[Dict[str, Any]]:
    response = instruments_table.scan(
        FilterExpression='#type = :type AND categoryId = :categoryId',
        ExpressionAttributeNames={'#type': 'type'},
        ExpressionAttributeValues={
            ':type': 'ENTRY',
            ':categoryId': category_id
        }
    )
    return response.get('Items', [])

def get_entry(entry_id: str) -> Dict[str, Any]:
    response = instruments_table.get_item(Key={'instrumentId': entry_id})
    return response.get('Item', {})

def update_entry(entry_id: str, entry_data: Dict[str, Any]) -> Dict[str, Any]:
    timestamp = datetime.utcnow().isoformat()
    update_expr = 'SET updatedAt = :ts'
    expr_attrs = {':ts': timestamp}
    expr_names = {}
    
    for key, value in entry_data.items():
        if key != 'instrumentId':  # Don't update the primary key
            update_expr += f', #{key} = :{key}'
            expr_attrs[f':{key}'] = value
            expr_names[f'#{key}'] = key
    
    response = instruments_table.update_item(
        Key={'instrumentId': entry_id},
        UpdateExpression=update_expr,
        ExpressionAttributeValues=expr_attrs,
        ExpressionAttributeNames=expr_names,
        ReturnValues='ALL_NEW'
    )
    return response.get('Attributes', {})

# Booking Management Functions
def create_booking(entry_id: str, booking_data: Dict[str, Any]) -> Dict[str, Any]:
    timestamp = datetime.utcnow().isoformat()
    booking_id = str(uuid.uuid4())
    
    # Check if entry is available
    entry = get_entry(entry_id)
    if not entry or entry.get('status') != 'AVAILABLE':
        raise ValueError("Entry is not available for booking")
    
    # Check availability for the requested dates
    start_date = booking_data.get('startDate')
    end_date = booking_data.get('endDate')
    
    if not is_available(entry_id, start_date, end_date):
        raise ValueError("Entry is not available for the requested dates")
    
    item = {
        'bookingId': booking_id,
        'entryId': entry_id,
        'userId': booking_data.get('userId'),
        'startDate': start_date,
        'endDate': end_date,
        'startTime': booking_data.get('startTime'),
        'endTime': booking_data.get('endTime'),
        'purpose': booking_data.get('purpose', ''),
        'notes': booking_data.get('notes', ''),
        'status': 'CONFIRMED',  # CONFIRMED, CANCELLED, COMPLETED
        'createdAt': timestamp,
        'updatedAt': timestamp
    }
    
    # Create booking in bookings table
    bookings_table.put_item(Item=item)
    
    # Update entry availability if needed
    available_qty = entry.get('availableQuantity', 1) - 1
    if available_qty <= 0:
        update_entry(entry_id, {'status': 'IN_USE', 'availableQuantity': 0})
    else:
        update_entry(entry_id, {'availableQuantity': available_qty})
    
    return item

def get_bookings_by_entry(entry_id: str) -> List[Dict[str, Any]]:
    response = bookings_table.scan(
        FilterExpression='entryId = :entryId',
        ExpressionAttributeValues={':entryId': entry_id}
    )
    return response.get('Items', [])

def get_available_dates(entry_id: str, start_date: str, end_date: str) -> List[str]:
    """Get available dates for booking within the specified range"""
    bookings = get_bookings_by_entry(entry_id)
    
    start = datetime.fromisoformat(start_date.replace('Z', '+00:00'))
    end = datetime.fromisoformat(end_date.replace('Z', '+00:00'))
    
    available_dates = []
    current_date = start
    
    while current_date <= end:
        date_str = current_date.date().isoformat()
        is_date_available = True
        
        for booking in bookings:
            booking_start = datetime.fromisoformat(booking['startDate'].replace('Z', '+00:00')).date()
            booking_end = datetime.fromisoformat(booking['endDate'].replace('Z', '+00:00')).date()
            
            if booking_start <= current_date.date() <= booking_end:
                is_date_available = False
                break
        
        if is_date_available:
            available_dates.append(date_str)
        
        current_date += timedelta(days=1)
    
    return available_dates

def is_available(entry_id: str, start_date: str, end_date: str) -> bool:
    """Check if entry is available for the specified date range"""
    bookings = get_bookings_by_entry(entry_id)
    
    start = datetime.fromisoformat(start_date.replace('Z', '+00:00'))
    end = datetime.fromisoformat(end_date.replace('Z', '+00:00'))
    
    for booking in bookings:
        if booking['status'] != 'CONFIRMED':
            continue
            
        booking_start = datetime.fromisoformat(booking['startDate'].replace('Z', '+00:00'))
        booking_end = datetime.fromisoformat(booking['endDate'].replace('Z', '+00:00'))
        
        # Check for overlap
        if not (end < booking_start or start > booking_end):
            return False
    
    return True

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    logger.info("=== Lambda function started ===")
    logger.info(f"Event: {json.dumps(event)}")
    logger.info(f"Environment variables: INSTRUMENTS_TABLE={os.environ.get('INSTRUMENTS_TABLE')}, BOOKINGS_TABLE={os.environ.get('BOOKINGS_TABLE')}")
    
    try:
        # Handle OPTIONS request for CORS preflight
        if event['httpMethod'] == 'OPTIONS':
            logger.info("Handling OPTIONS request")
            return create_response(200, '')

        # Get user ID from Cognito authorizer
        logger.info("Extracting user ID from Cognito authorizer")
        user_id = event['requestContext']['authorizer']['claims']['sub']
        logger.info(f"User ID: {user_id}")
        
        # Get HTTP method and path
        http_method = event['httpMethod']
        path = event['path']
        path_parts = path.strip('/').split('/')
        logger.info(f"HTTP Method: {http_method}, Path: {path}, Path parts: {path_parts}")
        
        # Parse request body if present
        body = json.loads(event['body']) if event.get('body') else {}
        logger.info(f"Request body: {json.dumps(body)}")
        
        # Route the request based on the path
        if path_parts[0] == 'inventory':
            logger.info("Processing inventory endpoint")
            
            # Labs endpoints
            if len(path_parts) == 2 and path_parts[1] == 'labs':  # /inventory/labs
                logger.info("Processing /inventory/labs endpoint")
                if http_method == 'GET':
                    logger.info("Getting all labs")
                    labs = get_labs()
                    logger.info(f"Returning {len(labs)} labs")
                    return create_response(200, json.dumps(labs))
                elif http_method == 'POST':
                    logger.info("Creating new lab")
                    lab = create_lab(body)
                    logger.info(f"Created lab: {lab.get('name')}")
                    return create_response(201, json.dumps(lab))
            
            elif len(path_parts) == 3 and path_parts[1] == 'labs':  # /inventory/labs/{labId}
                lab_id = path_parts[2] 
                logger.info(f"Processing /inventory/labs/{lab_id} endpoint")
                if http_method == 'GET':
                    logger.info(f"Getting lab: {lab_id}")
                    lab = get_lab(lab_id)
                    logger.info(f"Found lab: {lab.get('name', 'Not found')}")
                    return create_response(200, json.dumps(lab))
            
            # Categories endpoints
            elif len(path_parts) == 4 and path_parts[1] == 'labs' and path_parts[3] == 'categories':  # /inventory/labs/{labId}/categories
                lab_id = path_parts[2]
                logger.info(f"Processing /inventory/labs/{lab_id}/categories endpoint")
                if http_method == 'GET':
                    logger.info(f"Getting categories for lab: {lab_id}")
                    categories = get_categories_by_lab(lab_id)
                    logger.info(f"Found {len(categories)} categories")
                    return create_response(200, json.dumps(categories))
                elif http_method == 'POST':
                    logger.info(f"Creating category for lab: {lab_id}")
                    body['labId'] = lab_id
                    category = create_category(lab_id, body)
                    logger.info(f"Created category: {category.get('name')}")
                    return create_response(201, json.dumps(category))
            
            # Entries endpoints
            elif len(path_parts) == 4 and path_parts[1] == 'categories' and path_parts[3] == 'entries':  # /inventory/categories/{categoryId}/entries
                category_id = path_parts[2]
                logger.info(f"Processing /inventory/categories/{category_id}/entries endpoint")
                if http_method == 'GET':
                    logger.info(f"Getting entries for category: {category_id}")
                    entries = get_entries_by_category(category_id)
                    logger.info(f"Found {len(entries)} entries")
                    return create_response(200, json.dumps(entries))
                elif http_method == 'POST':
                    logger.info(f"Creating entry for category: {category_id}")
                    entry = create_entry(category_id, body)
                    logger.info(f"Created entry: {entry.get('name')}")
                    return create_response(201, json.dumps(entry))
            
            elif len(path_parts) == 3 and path_parts[1] == 'entries':  # /inventory/entries/{entryId}
                entry_id = path_parts[2]
                logger.info(f"Processing /inventory/entries/{entry_id} endpoint")
                if http_method == 'GET':
                    logger.info(f"Getting entry: {entry_id}")
                    entry = get_entry(entry_id)
                    logger.info(f"Found entry: {entry.get('name', 'Not found')}")
                    return create_response(200, json.dumps(entry))
                elif http_method == 'PUT':
                    logger.info(f"Updating entry: {entry_id}")
                    entry = update_entry(entry_id, body)
                    logger.info(f"Updated entry: {entry.get('name')}")
                    return create_response(200, json.dumps(entry))
            
            # Booking endpoints
            elif len(path_parts) == 4 and path_parts[1] == 'entries' and path_parts[3] == 'book':  # /inventory/entries/{entryId}/book
                entry_id = path_parts[2]
                logger.info(f"Processing /inventory/entries/{entry_id}/book endpoint")
                if http_method == 'POST':
                    logger.info(f"Creating booking for entry: {entry_id}")
                    body['userId'] = user_id
                    booking = create_booking(entry_id, body)
                    logger.info(f"Created booking: {booking.get('bookingId')}")
                    return create_response(201, json.dumps(booking))
            
            elif len(path_parts) == 5 and path_parts[1] == 'entries' and path_parts[3] == 'availability':  # /inventory/entries/{entryId}/availability/{start_date}/{end_date}
                entry_id = path_parts[2]
                start_date = path_parts[4]
                end_date = event['queryStringParameters'].get('end_date') if event.get('queryStringParameters') else None
                logger.info(f"Processing availability check for entry: {entry_id}, dates: {start_date} to {end_date}")
                
                if http_method == 'GET' and end_date:
                    available_dates = get_available_dates(entry_id, start_date, end_date)
                    logger.info(f"Found {len(available_dates)} available dates")
                    return create_response(200, json.dumps({'availableDates': available_dates}))
            
            elif len(path_parts) == 4 and path_parts[1] == 'entries' and path_parts[3] == 'bookings':  # /inventory/entries/{entryId}/bookings
                entry_id = path_parts[2]
                logger.info(f"Processing /inventory/entries/{entry_id}/bookings endpoint")
                if http_method == 'GET':
                    logger.info(f"Getting bookings for entry: {entry_id}")
                    bookings = get_bookings_by_entry(entry_id)
                    logger.info(f"Found {len(bookings)} bookings")
                    return create_response(200, json.dumps(bookings))
        
        logger.warning(f"Invalid path requested: {path}")
        return create_response(400, json.dumps({'error': 'Invalid path'}))
            
    except Exception as e:
        logger.error(f"=== Lambda function error ===")
        logger.error(f"Error type: {type(e).__name__}")
        logger.error(f"Error message: {str(e)}")
        logger.error(f"Event that caused error: {json.dumps(event)}")
        import traceback
        logger.error(f"Full traceback: {traceback.format_exc()}")
        return create_response(500, json.dumps({'error': str(e), 'type': type(e).__name__})) 