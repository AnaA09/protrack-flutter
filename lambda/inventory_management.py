import json
import boto3
import os
from datetime import datetime, timedelta
from typing import Dict, Any, List
import uuid
import logging
from decimal import Decimal

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

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

def create_response(status_code: int, body: Any) -> Dict[str, Any]:
    # Use custom encoder for JSON serialization
    if isinstance(body, str):
        json_body = body
    else:
        json_body = json.dumps(body, cls=DecimalEncoder)
    
    response = {
        'statusCode': status_code,
        'headers': CORS_HEADERS,
        'body': json_body
    }
    logger.info(f"Creating response: status={status_code}, body_length={len(json_body)}")
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

def update_lab(lab_id: str, lab_data: Dict[str, Any]) -> Dict[str, Any]:
    """Update a lab with new data"""
    timestamp = datetime.utcnow().isoformat() + 'Z'
    
    # Build update expression dynamically
    update_expression = "SET updatedAt = :updatedAt"
    expression_values = {":updatedAt": timestamp}
    expression_names = {}
    
    # Only allow updating certain fields
    allowed_fields = ['name', 'description', 'location', 'status']
    
    for key, value in lab_data.items():
        if key in allowed_fields:
            if key in ['name', 'status', 'location']:  # Reserved keywords
                update_expression += f", #{key} = :{key}"
                expression_names[f"#{key}"] = key
                expression_values[f":{key}"] = value
            else:
                update_expression += f", {key} = :{key}"
                expression_values[f":{key}"] = value
    
    kwargs = {
        'Key': {'instrumentId': lab_id},
        'UpdateExpression': update_expression,
        'ExpressionAttributeValues': expression_values,
        'ReturnValues': 'ALL_NEW'
    }
    
    if expression_names:
        kwargs['ExpressionAttributeNames'] = expression_names
    
    response = instruments_table.update_item(**kwargs)
    return response['Attributes']

def delete_lab(lab_id: str) -> None:
    """Delete a lab and all its associated categories and entries"""
    logger.info(f"Deleting lab: {lab_id}")
    
    # First, get all categories for this lab
    categories = get_categories_by_lab(lab_id)
    
    # Delete all entries in all categories of this lab
    for category in categories:
        entries = get_entries_by_category(category['categoryId'])
        for entry in entries:
            # Use the proper delete function that cleans up bookings
            delete_entry_with_bookings_cleanup(entry['instrumentId'])
        
        # Delete the category
        instruments_table.delete_item(Key={'instrumentId': category['instrumentId']})
        logger.info(f"Deleted category: {category['name']}")
    
    # Finally, delete the lab
    instruments_table.delete_item(Key={'instrumentId': lab_id})
    logger.info(f"Deleted lab: {lab_id}")

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
        FilterExpression='labId = :labId AND #type = :type',
        ExpressionAttributeNames={
            '#type': 'type'
        },
        ExpressionAttributeValues={
            ':labId': lab_id,
            ':type': 'CATEGORY'
        }
    )
    return response.get('Items', [])

def update_category(category_id: str, category_data: Dict[str, Any]) -> Dict[str, Any]:
    """Update a category with new data"""
    timestamp = datetime.utcnow().isoformat() + 'Z'
    
    # Build update expression dynamically
    update_expression = "SET updatedAt = :updatedAt"
    expression_values = {":updatedAt": timestamp}
    expression_names = {}
    
    # Only allow updating certain fields
    allowed_fields = ['name', 'categoryType', 'description', 'status']
    
    for key, value in category_data.items():
        if key in allowed_fields:
            if key in ['name', 'status']:  # Reserved keywords
                update_expression += f", #{key} = :{key}"
                expression_names[f"#{key}"] = key
                expression_values[f":{key}"] = value
            else:
                update_expression += f", {key} = :{key}"
                expression_values[f":{key}"] = value
    
    kwargs = {
        'Key': {'instrumentId': category_id},
        'UpdateExpression': update_expression,
        'ExpressionAttributeValues': expression_values,
        'ReturnValues': 'ALL_NEW'
    }
    
    if expression_names:
        kwargs['ExpressionAttributeNames'] = expression_names
    
    response = instruments_table.update_item(**kwargs)
    return response['Attributes']

def delete_category(category_id: str) -> None:
    """Delete a category and all its associated entries"""
    logger.info(f"Deleting category: {category_id}")
    
    # First, get all entries in this category
    entries = get_entries_by_category(category_id)
    
    # Delete all entries in this category
    for entry in entries:
        # Use the proper delete function that cleans up bookings
        delete_entry_with_bookings_cleanup(entry['instrumentId'])
    
    # Delete the category
    instruments_table.delete_item(Key={'instrumentId': category_id})
    logger.info(f"Deleted category: {category_id}")

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
    
    entries = response.get('Items', [])
    
    # Update status for each entry based on current bookings
    for entry in entries:
        # Skip deleted entries
        if entry.get('status') == 'DELETED':
            continue
            
        actual_id = entry.get('instrumentId')
          # Check if the item is currently in use
        if is_currently_in_use(actual_id):
            entry['status'] = 'IN_USE'
        else:
            # If not in use but status is IN_USE, fix the database and show as AVAILABLE
            if entry.get('status') == 'IN_USE':
                # Fix the database entry
                fix_incorrect_in_use_status(actual_id)
                # Update the returned status
                entry['status'] = 'AVAILABLE'
    
    return entries

def get_entry(entry_id: str, update_status: bool = True) -> Dict[str, Any]:
    # First try to get by instrumentId (primary key) for backward compatibility
    response = instruments_table.get_item(Key={'instrumentId': entry_id})
    entry = response.get('Item')
    
    if not entry:
        # If not found, search by entryId field
        logger.info(f"Entry not found by instrumentId, searching by entryId: {entry_id}")
        response = instruments_table.scan(
            FilterExpression='entryId = :entryId AND #type = :type',
            ExpressionAttributeNames={'#type': 'type'},
            ExpressionAttributeValues={
                ':entryId': entry_id,
                ':type': 'ENTRY'
            }
        )
        
        # Check if we found any items from the scan
        items = response.get('Items', [])
        if items:
            entry = items[0]
            logger.info(f"Found entry by entryId: {entry.get('name', 'Unknown')}")
        else:
            logger.warning(f"Entry not found by either instrumentId or entryId: {entry_id}")
            return {}
    
    # Update status dynamically if requested (and not a lab)
    if update_status and entry.get('type') == 'ENTRY' and entry.get('status') != 'DELETED':
        actual_id = entry.get('instrumentId')
        
        # Check if the item is currently in use
        if is_currently_in_use(actual_id):
            # Only update the returned status, not the database
            entry['status'] = 'IN_USE'
        else:
            # If not in use but status is IN_USE, fix the database and show as AVAILABLE
            if entry.get('status') == 'IN_USE':
                # Fix the database entry
                fix_incorrect_in_use_status(actual_id)
                # Update the returned status
                entry['status'] = 'AVAILABLE'
    
    return entry

def update_entry(entry_id: str, entry_data: Dict[str, Any]) -> Dict[str, Any]:
    timestamp = datetime.utcnow().isoformat() + 'Z'
    
    # Build update expression dynamically
    update_expression = "SET updatedAt = :updatedAt"
    expression_values = {":updatedAt": timestamp}
    expression_names = {}
    
    # List of DynamoDB reserved keywords that need expression attribute names
    reserved_keywords = ['name', 'type', 'status', 'location', 'size', 'timestamp', 'data']
    
    for key, value in entry_data.items():
        if key not in ['instrumentId', 'createdAt']:  # Don't update these fields
            if key.lower() in reserved_keywords:
                # Use expression attribute name for reserved keywords
                update_expression += f", #{key} = :{key}"
                expression_names[f"#{key}"] = key
            else:
                # Use direct attribute name for non-reserved keywords
                update_expression += f", {key} = :{key}"
            expression_values[f":{key}"] = value
    
    kwargs = {
        'Key': {'instrumentId': entry_id},
        'UpdateExpression': update_expression,
        'ExpressionAttributeValues': expression_values,
        'ReturnValues': 'ALL_NEW'
    }
    
    if expression_names:
        kwargs['ExpressionAttributeNames'] = expression_names
    
    response = instruments_table.update_item(**kwargs)
    return response['Attributes']

def delete_entry(entry_id: str) -> None:
    """Delete an entry and all its associated bookings"""
    logger.info(f"Deleting entry: {entry_id}")
    
    # First, delete all bookings for this entry
    bookings = get_bookings_by_entry(entry_id)
    for booking in bookings:
        bookings_table.delete_item(Key={'bookingId': booking['bookingId']})
        logger.info(f"Deleted booking: {booking['bookingId']}")
    
    # Then delete the entry
    instruments_table.delete_item(Key={'instrumentId': entry_id})
    logger.info(f"Deleted entry: {entry_id}")

def delete_entry_with_bookings_cleanup(entry_id: str) -> None:
    """Helper function to delete entry with booking cleanup - used internally"""
    # Delete all bookings for this entry
    bookings = get_bookings_by_entry(entry_id)
    for booking in bookings:
        bookings_table.delete_item(Key={'bookingId': booking['bookingId']})
        logger.info(f"Deleted booking: {booking['bookingId']}")
    
    # Delete the entry
    instruments_table.delete_item(Key={'instrumentId': entry_id})
    logger.info(f"Deleted entry: {entry_id}")

# Booking Management Functions
def create_booking(entry_id: str, booking_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Create a booking for an item. Bookings are allowed if there are no booking conflicts,
    regardless of the item's current status (except for permanently unavailable items).
    The item's status is only used for display purposes and does not affect booking availability.
    """
    timestamp = datetime.utcnow().isoformat()
    booking_id = str(uuid.uuid4())
    available_qty = 1  # Default value
    
    try:
        logger.info(f"Creating booking for entry: {entry_id}")
        logger.info(f"Booking data: {json.dumps(booking_data, cls=DecimalEncoder)}")
        
        # Check if entry exists
        entry = get_entry(entry_id, update_status=False)
        if not entry:
            logger.error(f"Entry not found: {entry_id}")
            raise ValueError("Entry not found")
            
        logger.info(f"Entry found: {entry.get('name', 'Unknown')}")
            
        # Only check if the entry is permanently unavailable
        entry_status = entry.get('status', '').upper()
        logger.info(f"Entry status: {entry_status}")
        permanently_unavailable_statuses = ['DELETED', 'RETIRED', 'DAMAGED']
        
        if entry_status in permanently_unavailable_statuses:
            logger.error(f"Entry status '{entry_status}' is not bookable. Permanently unavailable statuses: {permanently_unavailable_statuses}")
            raise ValueError(f"Entry cannot be booked because it is {entry_status.lower()}")
        
        # Get quantity info but don't block booking based on it
        available_qty = entry.get('availableQuantity', entry.get('quantity', 1))
        logger.info(f"Current available quantity: {available_qty}")
        
        # Log the current quantity but don't block booking
        if available_qty <= 0:
            logger.warning(f"Entry has availableQuantity={available_qty}, but proceeding with booking anyway since we're only checking for conflicts")
        
        # Check availability for the requested dates
        start_date = booking_data.get('startDate')
        end_date = booking_data.get('endDate')
        
        logger.info(f"Checking availability for dates: {start_date} to {end_date}")
        
        if not start_date or not end_date:
            logger.error("Missing start date or end date")
            raise ValueError("Start date and end date are required")
        
        if not is_available(entry_id, start_date, end_date):
            logger.error(f"Entry is not available for the requested dates: {start_date} to {end_date}")
            
            # Get more details about the conflict for a better error message
            bookings = get_bookings_by_entry(entry_id)
            conflicting_bookings = []
            
            try:
                # Parse the requested dates
                if 'T' in start_date or 'Z' in start_date:
                    req_start = datetime.fromisoformat(start_date.replace('Z', '+00:00'))
                    req_end = datetime.fromisoformat(end_date.replace('Z', '+00:00'))
                else:
                    req_start = datetime.fromisoformat(start_date + 'T00:00:00')
                    req_end = datetime.fromisoformat(end_date + 'T23:59:59')
                
                # Find conflicting bookings
                for booking in bookings:
                    if booking['status'] != 'CONFIRMED':
                        continue
                        
                    try:
                        booking_start_str = booking['startDate']
                        booking_end_str = booking['endDate']
                        
                        if 'T' in booking_start_str or 'Z' in booking_start_str:
                            booking_start = datetime.fromisoformat(booking_start_str.replace('Z', '+00:00'))
                            booking_end = datetime.fromisoformat(booking_end_str.replace('Z', '+00:00'))
                        else:
                            booking_start = datetime.fromisoformat(booking_start_str + 'T00:00:00')
                            booking_end = datetime.fromisoformat(booking_end_str + 'T23:59:59')
                        
                        # Check for overlap
                        if not (req_end < booking_start or req_start > booking_end):
                            conflicting_bookings.append({
                                'startDate': booking['startDate'],
                                'endDate': booking['endDate'],
                                'purpose': booking.get('purpose', 'No purpose specified')
                            })
                    except Exception as e:
                        logger.error(f"Error parsing booking dates: {e}")
                        continue
                
                # Create a detailed error message
                if conflicting_bookings:
                    conflict_details = []
                    for conflict in conflicting_bookings:
                        conflict_details.append(f"{conflict['startDate']} to {conflict['endDate']} (Purpose: {conflict['purpose']})")
                    
                    error_msg = f"Booking conflict detected. The requested dates ({start_date} to {end_date}) overlap with existing booking(s): {'; '.join(conflict_details)}. Please choose different dates."
                else:
                    error_msg = f"The requested dates ({start_date} to {end_date}) are not available for booking. Please choose different dates."
                    
            except Exception as e:
                logger.error(f"Error creating detailed conflict message: {e}")
                error_msg = f"The requested dates ({start_date} to {end_date}) conflict with an existing booking. Please choose different dates."
            
            raise ValueError(error_msg)
        
        # Create the booking item
        item = {
            'bookingId': booking_id,
            'entryId': entry.get('instrumentId'),  # Use the actual instrumentId for consistency
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
        
        logger.info(f"Creating booking item: {json.dumps(item, cls=DecimalEncoder)}")
        
        # Create booking in bookings table
        bookings_table.put_item(Item=item)
        logger.info(f"Successfully created booking: {booking_id}")
        
        # Update entry for visual indication only - this doesn't affect future booking availability
        actual_entry_id = entry.get('instrumentId')
        if is_currently_in_use(actual_entry_id):
            # Item has active bookings at the current time - mark as IN_USE
            logger.info(f"Setting entry status to IN_USE (visual indication only)")
            update_entry(actual_entry_id, {'status': 'IN_USE'})
        else:
            # Item doesn't have active bookings at the current time - keep or set as AVAILABLE 
            if entry.get('status', '').upper() == 'IN_USE':
                logger.info(f"Setting entry status to AVAILABLE as there are no current active bookings")
                update_entry(actual_entry_id, {'status': 'AVAILABLE'})
        
        # Still update the available quantity for inventory tracking
        new_available_qty = max(0, available_qty - 1)  # Ensure we don't go below 0
        logger.info(f"Updating available quantity to: {new_available_qty}")
        update_entry(actual_entry_id, {'availableQuantity': new_available_qty})
        
        return item
        
    except ValueError as e:
        # Pass through ValueError with specific message
        logger.error(f"Validation error in create_booking: {str(e)}")
        raise
    except Exception as e:
        # Catch any other errors
        logger.error(f"Unexpected error in create_booking: {str(e)}")
        logger.exception("Exception details:")
        raise ValueError(f"Failed to create booking: {str(e)}")

def get_bookings_by_entry(entry_id: str) -> List[Dict[str, Any]]:
    # Get the entry first to determine the correct ID to use for bookings
    entry = get_entry(entry_id, update_status=False)
    if not entry:
        logger.warning(f"Entry not found for bookings lookup: {entry_id}")
        return []
    
    # Use the instrumentId (primary key) for booking lookups
    actual_entry_id = entry.get('instrumentId', entry_id)
    logger.info(f"Looking up bookings for entry: {actual_entry_id}")
    
    response = bookings_table.scan(
        FilterExpression='entryId = :entryId',
        ExpressionAttributeValues={':entryId': actual_entry_id}
    )
    return response.get('Items', [])

def get_available_dates(entry_id: str, start_date: str, end_date: str) -> List[str]:
    """Get available dates for booking within the specified range"""
    bookings = get_bookings_by_entry(entry_id)
    
    # Parse dates - handle both date-only and datetime formats
    try:
        if 'T' in start_date or 'Z' in start_date:
            # Full datetime format
            start = datetime.fromisoformat(start_date.replace('Z', '+00:00'))
            end = datetime.fromisoformat(end_date.replace('Z', '+00:00'))
        else:
            # Date-only format (e.g., "2024-12-02")
            start = datetime.fromisoformat(start_date + 'T00:00:00')
            end = datetime.fromisoformat(end_date + 'T23:59:59')
    except Exception as e:
        logger.error(f"Error parsing dates in get_available_dates: {e}")
        return []
    
    available_dates = []
    current_date = start
    
    while current_date <= end:
        date_str = current_date.date().isoformat()
        is_date_available = True
        
        for booking in bookings:
            if booking['status'] != 'CONFIRMED':
                continue
                
            try:
                booking_start_str = booking['startDate']
                booking_end_str = booking['endDate']
                
                # Parse booking dates - handle both formats
                if 'T' in booking_start_str or 'Z' in booking_start_str:
                    booking_start = datetime.fromisoformat(booking_start_str.replace('Z', '+00:00')).date()
                    booking_end = datetime.fromisoformat(booking_end_str.replace('Z', '+00:00')).date()
                else:
                    booking_start = datetime.fromisoformat(booking_start_str + 'T00:00:00').date()
                    booking_end = datetime.fromisoformat(booking_end_str + 'T23:59:59').date()
                
                if booking_start <= current_date.date() <= booking_end:
                    is_date_available = False
                    break
            except Exception as e:
                logger.error(f"Error parsing booking dates in get_available_dates: {e}")
                continue
        
        if is_date_available:
            available_dates.append(date_str)
        
        current_date += timedelta(days=1)
    
    return available_dates

def is_available(entry_id: str, start_date: str, end_date: str) -> bool:
    """
    Check if entry is available for the specified date range.
    This ONLY checks for booking conflicts and ignores the item's status.
    An item is considered available if there are no booking conflicts,
    regardless of its status.
    """
    logger.info(f"Checking availability for entry {entry_id}, dates: {start_date} to {end_date}")
    
    bookings = get_bookings_by_entry(entry_id)
    logger.info(f"Found {len(bookings)} existing bookings for entry")
    
    # Parse dates - handle both date-only and datetime formats
    try:
        if 'T' in start_date or 'Z' in start_date:
            # Full datetime format
            start = datetime.fromisoformat(start_date.replace('Z', '+00:00'))
            end = datetime.fromisoformat(end_date.replace('Z', '+00:00'))
        else:
            # Date-only format (e.g., "2024-12-02")
            start = datetime.fromisoformat(start_date + 'T00:00:00')
            end = datetime.fromisoformat(end_date + 'T23:59:59')
        
        logger.info(f"Parsed dates - start: {start}, end: {end}")
    except Exception as e:
        logger.error(f"Error parsing dates: {e}")
        return False
    
    for booking in bookings:
        if booking['status'] != 'CONFIRMED':
            logger.info(f"Skipping booking {booking.get('bookingId')} with status: {booking['status']}")
            continue
        
        try:
            booking_start_str = booking['startDate']
            booking_end_str = booking['endDate']
            
            # Parse booking dates - handle both formats
            if 'T' in booking_start_str or 'Z' in booking_start_str:
                booking_start = datetime.fromisoformat(booking_start_str.replace('Z', '+00:00'))
                booking_end = datetime.fromisoformat(booking_end_str.replace('Z', '+00:00'))
            else:
                booking_start = datetime.fromisoformat(booking_start_str + 'T00:00:00')
                booking_end = datetime.fromisoformat(booking_end_str + 'T23:59:59')
            
            logger.info(f"Checking overlap with booking {booking.get('bookingId')}: {booking_start} to {booking_end}")
            
            # Check for overlap: two date ranges overlap if NOT (end1 < start2 OR start1 > end2)
            if not (end < booking_start or start > booking_end):
                logger.info(f"Date overlap detected with booking {booking.get('bookingId')}")
                return False
                
        except Exception as e:
            logger.error(f"Error parsing booking dates: {e}")
            continue
    
    logger.info("No date conflicts found - entry is available")
    return True

def is_currently_in_use(entry_id: str) -> bool:
    """
    Check if an item is currently in use based on active bookings.
    Returns True if there's an active booking at the current date and time.
    """
    bookings = get_bookings_by_entry(entry_id)
    if not bookings:
        return False
        
    current_time = datetime.utcnow()
    logger.info(f"Checking if entry {entry_id} is currently in use at {current_time.isoformat()}")
    
    for booking in bookings:
        if booking['status'] != 'CONFIRMED':
            continue
            
        try:
            booking_start_str = booking['startDate']
            booking_end_str = booking['endDate']
            
            # Parse booking dates - handle both formats
            if 'T' in booking_start_str or 'Z' in booking_start_str:
                booking_start = datetime.fromisoformat(booking_start_str.replace('Z', '+00:00'))
                booking_end = datetime.fromisoformat(booking_end_str.replace('Z', '+00:00'))
            else:
                booking_start = datetime.fromisoformat(booking_start_str + 'T00:00:00')
                booking_end = datetime.fromisoformat(booking_end_str + 'T23:59:59')
            
            # Check if current time falls within the booking period
            if booking_start <= current_time <= booking_end:
                logger.info(f"Entry {entry_id} is currently in use: booking {booking.get('bookingId')} is active")
                return True
                
        except Exception as e:
            logger.error(f"Error parsing booking dates for current use check: {e}")
            continue
    
    logger.info(f"Entry {entry_id} is not currently in use")
    return False

def fix_incorrect_in_use_status(entry_id: str) -> bool:
    """
    Check if an entry has IN_USE status but no active bookings, and fix it in the database.
    Returns True if a fix was applied, False otherwise.
    """
    # Get the entry with the raw database status (not the dynamically updated one)
    response = instruments_table.get_item(Key={'instrumentId': entry_id})
    entry = response.get('Item')
    
    if not entry or entry.get('type') != 'ENTRY':
        return False
        
    # If the status is IN_USE, check if it's actually in use
    if entry.get('status') == 'IN_USE' and not is_currently_in_use(entry_id):
        logger.info(f"Fixing incorrect IN_USE status for entry {entry_id}")
        
        # Update the entry in the database to AVAILABLE
        update_expression = "SET #status = :status, updatedAt = :updatedAt"
        expression_values = {
            ":status": "AVAILABLE",
            ":updatedAt": datetime.utcnow().isoformat() + 'Z'
        }
        
        instruments_table.update_item(
            Key={'instrumentId': entry_id},
            UpdateExpression=update_expression,
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues=expression_values
        )
        
        logger.info(f"Fixed status for entry {entry_id}: changed from IN_USE to AVAILABLE")
        return True
    
    return False

def fix_all_entries_with_incorrect_status():
    """
    Find all entries with status IN_USE but no active bookings, and fix them.
    """
    logger.info("Fixing all entries with incorrect IN_USE status...")
    
    # Find all entries with IN_USE status
    response = instruments_table.scan(
        FilterExpression='#type = :type AND #status = :status',
        ExpressionAttributeNames={
            '#type': 'type',
            '#status': 'status'
        },
        ExpressionAttributeValues={
            ':type': 'ENTRY',
            ':status': 'IN_USE'
        }
    )
    
    entries = response.get('Items', [])
    logger.info(f"Found {len(entries)} entries with IN_USE status")
    
    fixed_count = 0
    for entry in entries:
        entry_id = entry.get('instrumentId')
        if entry_id and not is_currently_in_use(entry_id):
            if fix_incorrect_in_use_status(entry_id):
                fixed_count += 1
    
    logger.info(f"Fixed {fixed_count} entries with incorrect IN_USE status")
    return fixed_count

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    logger.info("=== Lambda function started ===")
    logger.info(f"Event: {json.dumps(event)}")
    logger.info(f"Event keys: {list(event.keys())}")
    logger.info(f"Environment variables: INSTRUMENTS_TABLE={os.environ.get('INSTRUMENTS_TABLE')}")
    
    http_method = event.get('httpMethod')
    path = event.get('path', '')
    body = event.get('body', {})
    user_id = event['requestContext']['authorizer']['claims']['sub']
    
    logger.info(f"HTTP Method: {http_method}")
    logger.info(f"Path: {path}")
    logger.info(f"Body: {json.dumps(body)}")
    logger.info(f"User ID: {user_id}")
    
    # Split the path by '/' and filter out empty segments
    path_parts = list(filter(bool, path.split('/')))
    logger.info(f"Path parts: {path_parts}")
    
    # Handle different HTTP methods and paths
    if http_method == 'OPTIONS':
        return create_response(200, '')
    elif len(path_parts) == 2 and path_parts[0] == 'inventory' and path_parts[1] == 'labs':  # /inventory/labs
        if http_method == 'GET':
            labs = get_labs()
            return create_response(200, labs)
        elif http_method == 'POST':
            lab_data = json.loads(body) if body else {}
            lab = create_lab(lab_data)
            return create_response(201, lab)
    elif len(path_parts) == 3 and path_parts[0] == 'inventory' and path_parts[1] == 'labs':  # /inventory/labs/{labId}
        lab_id = path_parts[2]
        if http_method == 'GET':
            lab = get_lab(lab_id)
            if lab:
                return create_response(200, lab)
            else:
                return create_response(404, {'error': 'Lab not found'})
        elif http_method == 'PUT':
            lab_data = json.loads(body) if body else {}
            lab = update_lab(lab_id, lab_data)
            return create_response(200, lab)
        elif http_method == 'DELETE':
            delete_lab(lab_id)
            return create_response(204, '')
    elif len(path_parts) == 4 and path_parts[0] == 'inventory' and path_parts[1] == 'labs' and path_parts[3] == 'categories':  # /inventory/labs/{labId}/categories
        lab_id = path_parts[2]
        if http_method == 'GET':
            categories = get_categories_by_lab(lab_id)
            return create_response(200, categories)
        elif http_method == 'POST':
            category_data = json.loads(body) if body else {}
            category = create_category(lab_id, category_data)
            return create_response(201, category)
    elif len(path_parts) == 3 and path_parts[0] == 'inventory' and path_parts[1] == 'categories':  # /inventory/categories/{categoryId}
        category_id = path_parts[2]
        if http_method == 'GET':
            category = instruments_table.get_item(Key={'instrumentId': category_id})
            if category and category.get('Item'):
                return create_response(200, category['Item'])
            else:
                return create_response(404, {'error': 'Category not found'})
        elif http_method == 'PUT':
            category_data = json.loads(body) if body else {}
            category = update_category(category_id, category_data)
            return create_response(200, category)
        elif http_method == 'DELETE':
            delete_category(category_id)
            return create_response(204, '')
    elif len(path_parts) == 4 and path_parts[0] == 'inventory' and path_parts[1] == 'categories' and path_parts[3] == 'entries':  # /inventory/categories/{categoryId}/entries
        category_id = path_parts[2]
        if http_method == 'GET':
            # Uses the updated get_entries_by_category function that dynamically updates statuses
            entries = get_entries_by_category(category_id)
            return create_response(200, entries)
        elif http_method == 'POST':
            entry_data = json.loads(body) if body else {}
            entry = create_entry(category_id, entry_data)
            return create_response(201, entry)
    elif len(path_parts) == 3 and path_parts[0] == 'inventory' and path_parts[1] == 'entries':  # /inventory/entries/{entryId}
        entry_id = path_parts[2]
        if http_method == 'GET':
            # Use dynamic status update for GET requests
            entry = get_entry(entry_id, update_status=True)
            if entry:
                return create_response(200, entry)
            else:
                return create_response(404, {'error': 'Entry not found'})
        elif http_method == 'PUT':
            entry_data = json.loads(body) if body else {}
            entry = update_entry(entry_id, entry_data)
            return create_response(200, entry)
        elif http_method == 'DELETE':
            delete_entry(entry_id)
            return create_response(204, '')
            
    elif len(path_parts) == 4 and path_parts[0] == 'inventory' and path_parts[1] == 'entries' and path_parts[3] == 'book':  # /inventory/entries/{entryId}/book
        entry_id = path_parts[2]
        if http_method == 'POST':
            try:
                # Log detailed information about the booking request
                logger.info(f"Processing booking request for entry_id: {entry_id}")
                logger.info(f"Request path parts: {path_parts}")
                
                booking_data = json.loads(body) if body else {}
                booking_data['userId'] = user_id  # Add user ID from auth context
                
                logger.info(f"Parsed booking data: {json.dumps(booking_data, cls=DecimalEncoder)}")
                
                # Validate required fields
                if not booking_data.get('startDate'):
                    return create_response(400, {"error": "startDate is required"})
                if not booking_data.get('endDate'):
                    return create_response(400, {"error": "endDate is required"})
                
                # First check if the entry exists
                test_entry = get_entry(entry_id, update_status=False)
                if not test_entry:
                    error_msg = f"Entry with ID '{entry_id}' does not exist"
                    logger.error(error_msg)
                    return create_response(404, {"error": error_msg, "entryId": entry_id})
                
                # Create booking with better error handling
                booking = create_booking(entry_id, booking_data)
                return create_response(201, booking)
            except ValueError as e:
                # Handle validation errors with a 400 status
                logger.error(f"Validation error in booking endpoint: {str(e)}")
                return create_response(400, {"error": str(e)})
            except Exception as e:
                # Handle unexpected errors
                logger.error(f"Unexpected error in booking endpoint: {str(e)}")
                logger.exception("Exception details:")
                return create_response(500, {"error": f"Failed to create booking: {str(e)}"})
    elif len(path_parts) == 4 and path_parts[0] == 'inventory' and path_parts[1] == 'entries' and path_parts[3] == 'bookings':  # /inventory/entries/{entryId}/bookings
        entry_id = path_parts[2]
        logger.info(f"Processing /inventory/entries/{entry_id}/bookings endpoint")
        if http_method == 'GET':
            logger.info(f"Getting bookings for entry: {entry_id}")
            bookings = get_bookings_by_entry(entry_id)
            logger.info(f"Found {len(bookings)} bookings")
            
            # If there are no bookings, fix any incorrect IN_USE status
            if not bookings:
                logger.info(f"No bookings found for entry {entry_id}, checking status")
                fix_incorrect_in_use_status(entry_id)
                
            return create_response(200, bookings)
        elif http_method == 'DELETE':
            # bookingId can be in query params or body
            booking_id = None
            if event.get('queryStringParameters') and event['queryStringParameters'].get('bookingId'):
                booking_id = event['queryStringParameters']['bookingId']
            elif body and body.get('bookingId'):
                booking_id = body['bookingId']
            if not booking_id:
                return create_response(400, {'error': 'Missing bookingId for deletion'})
            
            logger.info(f"Attempting to delete booking: {booking_id}")
            logger.info(f"Current user ID: {user_id}")
            
            response = bookings_table.get_item(Key={'bookingId': booking_id})
            booking = response.get('Item')
            if not booking:
                return create_response(404, {'error': 'Booking not found'})
            
            logger.info(f"Found booking: {json.dumps(booking, cls=DecimalEncoder)}")
            logger.info(f"Booking user ID: {booking.get('userId')}")
            logger.info(f"User ID match: {booking.get('userId') == user_id}")
            
            if booking.get('userId') != user_id:
                logger.warning(f"Authorization failed - booking userId: {booking.get('userId')}, current userId: {user_id}")
                return create_response(403, {'error': 'You are not authorized to cancel this booking.'})
            
            bookings_table.delete_item(Key={'bookingId': booking_id})
            logger.info(f"Successfully deleted booking: {booking_id}")
            return create_response(204, '')
    elif len(path_parts) == 5 and path_parts[0] == 'inventory' and path_parts[1] == 'entries' and path_parts[3] == 'availability':  # /inventory/entries/{entryId}/availability/{startDate}
        entry_id = path_parts[2]
        start_date = path_parts[4]
        if http_method == 'GET':
            end_date = event.get('queryStringParameters', {}).get('end_date') if event.get('queryStringParameters') else None
            if not end_date:
                return create_response(400, {'error': 'Missing end_date parameter'})
            available_dates = get_available_dates(entry_id, start_date, end_date)
            return create_response(200, {'availableDates': available_dates})
    elif len(path_parts) == 3 and path_parts[0] == 'inventory' and path_parts[1] == 'maintenance' and path_parts[2] == 'fix-status':  # /inventory/maintenance/fix-status
        # This is a special maintenance endpoint to fix all entries with incorrect IN_USE status
        if http_method == 'POST':
            fixed_count = fix_all_entries_with_incorrect_status()
            return create_response(200, {
                'message': f"Fixed {fixed_count} entries with incorrect IN_USE status",
                'fixedCount': fixed_count
            })
    elif len(path_parts) == 4 and path_parts[0] == 'inventory' and path_parts[1] == 'entries' and path_parts[3] == 'fix-status':  # /inventory/entries/{entryId}/fix-status
        entry_id = path_parts[2]
        if http_method == 'POST':
            was_fixed = fix_incorrect_in_use_status(entry_id)
            if was_fixed:
                return create_response(200, {'message': f"Fixed status for entry {entry_id}"})
            else:
                return create_response(200, {'message': f"No fix needed for entry {entry_id}"})

    return create_response(404, {'error': 'Not Found'})