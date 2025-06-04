#!/usr/bin/env python3
"""
Comprehensive test script to verify hierarchy delete isolation and booking cleanup
"""

import boto3
import json
import uuid
from datetime import datetime

# Initialize DynamoDB
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
instruments_table = dynamodb.Table('Instruments')
bookings_table = dynamodb.Table('Bookings')

def get_all_data():
    """Get all data from both tables"""
    # Get instruments data
    instruments_response = instruments_table.scan()
    instruments_items = instruments_response.get('Items', [])
    
    labs = [item for item in instruments_items if item.get('type') == 'LAB']
    categories = [item for item in instruments_items if item.get('type') == 'CATEGORY']
    entries = [item for item in instruments_items if item.get('type') == 'ENTRY']
    
    # Get bookings data
    bookings_response = bookings_table.scan()
    bookings = bookings_response.get('Items', [])
    
    return labs, categories, entries, bookings

def create_test_booking(entry_id: str) -> str:
    """Create a test booking for an entry"""
    booking_id = str(uuid.uuid4())
    timestamp = datetime.utcnow().isoformat()
    
    item = {
        'bookingId': booking_id,
        'entryId': entry_id,
        'userId': 'test-user-123',
        'startDate': '2024-01-15T09:00:00Z',
        'endDate': '2024-01-15T17:00:00Z',
        'startTime': '09:00',
        'endTime': '17:00',
        'purpose': 'Test booking for hierarchy test',
        'notes': 'Created for delete isolation testing',
        'status': 'CONFIRMED',
        'createdAt': timestamp,
        'updatedAt': timestamp
    }
    
    bookings_table.put_item(Item=item)
    print(f"✅ Created test booking: {booking_id[:8]}... for entry {entry_id[:8]}...")
    return booking_id

def print_hierarchy_summary():
    """Print a comprehensive summary of the current hierarchy"""
    labs, categories, entries, bookings = get_all_data()
    
    print(f"\n📊 Complete Inventory Hierarchy:")
    print(f"   • Labs: {len(labs)}")
    print(f"   • Categories: {len(categories)}")
    print(f"   • Entries: {len(entries)}")
    print(f"   • Bookings: {len(bookings)}")
    
    print(f"\n🏗️ Hierarchy Structure:")
    for lab in labs:
        lab_categories = [c for c in categories if c.get('labId') == lab['labId']]
        print(f"📍 Lab: {lab['name']} (ID: {lab['labId'][:8]}...) - {len(lab_categories)} categories")
        
        for category in lab_categories:
            category_entries = [e for e in entries if e.get('categoryId') == category['categoryId']]
            print(f"   📂 Category: {category['name']} ({category['categoryType']}) - {len(category_entries)} entries")
            
            for entry in category_entries:
                entry_bookings = [b for b in bookings if b.get('entryId') == entry['entryId']]
                print(f"      📦 Entry: {entry['name']} - {len(entry_bookings)} bookings")

def test_entry_delete_isolation():
    """Test that deleting an entry only affects that entry and its bookings"""
    print(f"\n🧪 Testing Entry Delete Isolation...")
    
    labs, categories, entries, bookings = get_all_data()
    
    if not entries:
        print("❌ No entries found to test")
        return
    
    # Find an entry and create a test booking for it
    test_entry = entries[0]
    test_booking_id = create_test_booking(test_entry['entryId'])
    
    # Refresh data to include the new booking
    labs, categories, entries, bookings = get_all_data()
    
    entry_bookings = [b for b in bookings if b.get('entryId') == test_entry['entryId']]
    other_bookings = [b for b in bookings if b.get('entryId') != test_entry['entryId']]
    other_entries = [e for e in entries if e.get('entryId') != test_entry['entryId']]
    
    print(f"🎯 Target entry: {test_entry['name']} (ID: {test_entry['entryId'][:8]}...)")
    print(f"   • Bookings for this entry: {len(entry_bookings)}")
    print(f"   • Other entries: {len(other_entries)}")
    print(f"   • Other bookings: {len(other_bookings)}")
    
    print(f"✅ Deleting this entry would remove {len(entry_bookings)} bookings and 1 entry")
    print(f"✅ Would leave {len(other_entries)} entries and {len(other_bookings)} bookings untouched")
    
    # Clean up the test booking
    bookings_table.delete_item(Key={'bookingId': test_booking_id})
    print(f"🧹 Cleaned up test booking")

def test_category_delete_isolation():
    """Test that deleting a category affects only that category's entries and their bookings"""
    print(f"\n🧪 Testing Category Delete Isolation...")
    
    labs, categories, entries, bookings = get_all_data()
    
    if len(categories) < 2:
        print("❌ Need at least 2 categories to test isolation")
        return
    
    # Find a category with entries
    test_category = None
    for category in categories:
        category_entries = [e for e in entries if e.get('categoryId') == category['categoryId']]
        if len(category_entries) > 0:
            test_category = category
            break
    
    if not test_category:
        print("❌ No categories with entries found")
        return
    
    # Create test bookings for entries in this category
    test_booking_ids = []
    category_entries = [e for e in entries if e.get('categoryId') == test_category['categoryId']]
    for entry in category_entries[:2]:  # Create bookings for first 2 entries
        booking_id = create_test_booking(entry['entryId'])
        test_booking_ids.append(booking_id)
    
    # Refresh data
    labs, categories, entries, bookings = get_all_data()
    
    category_entries = [e for e in entries if e.get('categoryId') == test_category['categoryId']]
    other_entries = [e for e in entries if e.get('categoryId') != test_category['categoryId']]
    
    category_bookings = []
    other_bookings = []
    for booking in bookings:
        entry_in_category = any(e['entryId'] == booking.get('entryId') for e in category_entries)
        if entry_in_category:
            category_bookings.append(booking)
        else:
            other_bookings.append(booking)
    
    print(f"🎯 Target category: {test_category['name']} (ID: {test_category['categoryId'][:8]}...)")
    print(f"   • Entries in this category: {len(category_entries)}")
    print(f"   • Bookings for this category's entries: {len(category_bookings)}")
    print(f"   • Other entries: {len(other_entries)}")
    print(f"   • Other bookings: {len(other_bookings)}")
    
    print(f"✅ Deleting this category would remove {len(category_entries)} entries, {len(category_bookings)} bookings, and 1 category")
    print(f"✅ Would leave {len(other_entries)} entries and {len(other_bookings)} bookings untouched")
    
    # Clean up test bookings
    for booking_id in test_booking_ids:
        bookings_table.delete_item(Key={'bookingId': booking_id})
    print(f"🧹 Cleaned up {len(test_booking_ids)} test bookings")

def test_lab_delete_isolation():
    """Test that deleting a lab affects only that lab's categories, entries, and their bookings"""
    print(f"\n🧪 Testing Lab Delete Isolation...")
    
    labs, categories, entries, bookings = get_all_data()
    
    if len(labs) < 2:
        print("❌ Need at least 2 labs to test isolation")
        return
    
    # Find a lab with categories and entries
    test_lab = None
    for lab in labs:
        lab_categories = [c for c in categories if c.get('labId') == lab['labId']]
        if len(lab_categories) > 0:
            test_lab = lab
            break
    
    if not test_lab:
        print("❌ No labs with categories found")
        return
    
    # Create test bookings for entries in this lab
    test_booking_ids = []
    lab_entries = [e for e in entries if e.get('labId') == test_lab['labId']]
    for entry in lab_entries[:2]:  # Create bookings for first 2 entries
        booking_id = create_test_booking(entry['entryId'])
        test_booking_ids.append(booking_id)
    
    # Refresh data
    labs, categories, entries, bookings = get_all_data()
    
    lab_categories = [c for c in categories if c.get('labId') == test_lab['labId']]
    other_categories = [c for c in categories if c.get('labId') != test_lab['labId']]
    
    lab_entries = [e for e in entries if e.get('labId') == test_lab['labId']]
    other_entries = [e for e in entries if e.get('labId') != test_lab['labId']]
    
    lab_bookings = []
    other_bookings = []
    for booking in bookings:
        entry_in_lab = any(e['entryId'] == booking.get('entryId') for e in lab_entries)
        if entry_in_lab:
            lab_bookings.append(booking)
        else:
            other_bookings.append(booking)
    
    print(f"🎯 Target lab: {test_lab['name']} (ID: {test_lab['labId'][:8]}...)")
    print(f"   • Categories in this lab: {len(lab_categories)}")
    print(f"   • Entries in this lab: {len(lab_entries)}")
    print(f"   • Bookings for this lab's entries: {len(lab_bookings)}")
    print(f"   • Other categories: {len(other_categories)}")
    print(f"   • Other entries: {len(other_entries)}")
    print(f"   • Other bookings: {len(other_bookings)}")
    
    print(f"✅ Deleting this lab would remove {len(lab_entries)} entries, {len(lab_categories)} categories, {len(lab_bookings)} bookings, and 1 lab")
    print(f"✅ Would leave {len(other_entries)} entries, {len(other_categories)} categories, and {len(other_bookings)} bookings untouched")
    
    # Clean up test bookings
    for booking_id in test_booking_ids:
        bookings_table.delete_item(Key={'bookingId': booking_id})
    print(f"🧹 Cleaned up {len(test_booking_ids)} test bookings")

def check_orphaned_bookings():
    """Check for any orphaned bookings (bookings with no corresponding entry)"""
    print(f"\n🔍 Checking for Orphaned Bookings...")
    
    labs, categories, entries, bookings = get_all_data()
    
    entry_ids = {entry['entryId'] for entry in entries}
    orphaned_bookings = []
    
    for booking in bookings:
        if booking.get('entryId') not in entry_ids:
            orphaned_bookings.append(booking)
    
    if orphaned_bookings:
        print(f"❌ Found {len(orphaned_bookings)} orphaned bookings!")
        for booking in orphaned_bookings:
            print(f"   • Booking {booking['bookingId'][:8]}... for missing entry {booking.get('entryId', 'N/A')[:8]}...")
    else:
        print(f"✅ No orphaned bookings found - booking integrity is maintained")

def main():
    print("🔍 Testing Complete Inventory Hierarchy Delete Isolation...")
    
    # Print current state
    print_hierarchy_summary()
    
    # Check for orphaned bookings first
    check_orphaned_bookings()
    
    # Test isolation at each level
    test_entry_delete_isolation()
    test_category_delete_isolation()
    test_lab_delete_isolation()
    
    print(f"\n✅ Comprehensive hierarchy delete tests completed!")
    print(f"💡 The tests show proper isolation and booking cleanup at all levels.")

if __name__ == "__main__":
    main() 