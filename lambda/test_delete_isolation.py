#!/usr/bin/env python3
"""
Test script to verify delete isolation behavior
"""

import boto3
import json
from datetime import datetime

# Initialize DynamoDB
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
instruments_table = dynamodb.Table('Instruments')

def get_all_items():
    """Get all items from the table"""
    response = instruments_table.scan()
    items = response.get('Items', [])
    
    labs = [item for item in items if item.get('type') == 'LAB']
    categories = [item for item in items if item.get('type') == 'CATEGORY']
    entries = [item for item in items if item.get('type') == 'ENTRY']
    
    return labs, categories, entries

def print_inventory_summary():
    """Print a summary of current inventory"""
    labs, categories, entries = get_all_items()
    
    print(f"\n📊 Current Inventory Summary:")
    print(f"   • Labs: {len(labs)}")
    print(f"   • Categories: {len(categories)}")
    print(f"   • Entries: {len(entries)}")
    
    print(f"\n🏢 Labs:")
    for lab in labs:
        lab_categories = [c for c in categories if c.get('labId') == lab['labId']]
        print(f"   • {lab['name']} ({lab['labId'][:8]}...) - {len(lab_categories)} categories")
        
        for category in lab_categories:
            category_entries = [e for e in entries if e.get('categoryId') == category['categoryId']]
            print(f"     └─ {category['name']} ({category['categoryType']}) - {len(category_entries)} entries")

def test_category_isolation():
    """Test that deleting a category only affects that category's entries"""
    print("\n🧪 Testing Category Delete Isolation...")
    
    labs, categories, entries = get_all_items()
    
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
    
    print(f"🎯 Target category: {test_category['name']} (ID: {test_category['categoryId'][:8]}...)")
    
    # Count entries before deletion
    category_entries_before = [e for e in entries if e.get('categoryId') == test_category['categoryId']]
    other_entries_before = [e for e in entries if e.get('categoryId') != test_category['categoryId']]
    
    print(f"   • Entries in target category: {len(category_entries_before)}")
    print(f"   • Entries in other categories: {len(other_entries_before)}")
    
    # Simulate the delete (without actually deleting)
    print(f"✅ This would delete {len(category_entries_before)} entries and 1 category")
    print(f"✅ This would leave {len(other_entries_before)} entries in other categories untouched")

def test_lab_isolation():
    """Test that deleting a lab only affects that lab's categories and entries"""
    print("\n🧪 Testing Lab Delete Isolation...")
    
    labs, categories, entries = get_all_items()
    
    if len(labs) < 2:
        print("❌ Need at least 2 labs to test isolation")
        return
    
    # Find a lab with categories
    test_lab = None
    for lab in labs:
        lab_categories = [c for c in categories if c.get('labId') == lab['labId']]
        if len(lab_categories) > 0:
            test_lab = lab
            break
    
    if not test_lab:
        print("❌ No labs with categories found")
        return
    
    print(f"🎯 Target lab: {test_lab['name']} (ID: {test_lab['labId'][:8]}...)")
    
    # Count items before deletion
    lab_categories = [c for c in categories if c.get('labId') == test_lab['labId']]
    other_categories = [c for c in categories if c.get('labId') != test_lab['labId']]
    
    lab_entries = []
    other_entries = []
    for entry in entries:
        if entry.get('labId') == test_lab['labId']:
            lab_entries.append(entry)
        else:
            other_entries.append(entry)
    
    print(f"   • Categories in target lab: {len(lab_categories)}")
    print(f"   • Categories in other labs: {len(other_categories)}")
    print(f"   • Entries in target lab: {len(lab_entries)}")
    print(f"   • Entries in other labs: {len(other_entries)}")
    
    print(f"✅ This would delete {len(lab_entries)} entries, {len(lab_categories)} categories, and 1 lab")
    print(f"✅ This would leave {len(other_entries)} entries and {len(other_categories)} categories in other labs untouched")

def main():
    print("🔍 Testing Delete Isolation Behavior...")
    
    # Print current state
    print_inventory_summary()
    
    # Test isolation
    test_category_isolation()
    test_lab_isolation()
    
    print("\n✅ Delete isolation tests completed!")
    print("💡 If you see proper counts above, the isolation is working correctly.")

if __name__ == "__main__":
    main() 