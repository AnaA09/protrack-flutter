#!/usr/bin/env python3
"""
Seed script to populate the inventory system with sample data
"""

import boto3
import json
import uuid
from datetime import datetime

# Initialize DynamoDB
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
instruments_table = dynamodb.Table('Instruments')

def create_lab(name, description, location):
    """Create a lab entry"""
    timestamp = datetime.utcnow().isoformat()
    lab_id = str(uuid.uuid4())
    
    item = {
        'instrumentId': lab_id,
        'type': 'LAB',
        'labId': lab_id,
        'name': name,
        'description': description,
        'location': location,
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'status': 'ACTIVE'
    }
    
    instruments_table.put_item(Item=item)
    print(f"Created lab: {name}")
    return lab_id

def create_category(lab_id, name, category_type, description):
    """Create a category entry"""
    timestamp = datetime.utcnow().isoformat()
    category_id = str(uuid.uuid4())
    
    item = {
        'instrumentId': category_id,
        'type': 'CATEGORY',
        'labId': lab_id,
        'categoryId': category_id,
        'name': name,
        'categoryType': category_type,
        'description': description,
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'status': 'ACTIVE'
    }
    
    instruments_table.put_item(Item=item)
    print(f"Created category: {name} in lab {lab_id}")
    return category_id

def create_entry(category_id, lab_id, name, model, manufacturer, quantity, location, status='AVAILABLE'):
    """Create an entry"""
    timestamp = datetime.utcnow().isoformat()
    entry_id = str(uuid.uuid4())
    
    item = {
        'instrumentId': entry_id,
        'type': 'ENTRY',
        'categoryId': category_id,
        'labId': lab_id,
        'entryId': entry_id,
        'name': name,
        'model': model,
        'manufacturer': manufacturer,
        'description': f'{manufacturer} {model}',
        'quantity': quantity,
        'availableQuantity': quantity if status == 'AVAILABLE' else 0,
        'location': location,
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'status': status
    }
    
    instruments_table.put_item(Item=item)
    print(f"Created entry: {name}")
    return entry_id

def main():
    print("🌱 Seeding inventory data...")
    
    # Create labs
    print("\n📍 Creating labs...")
    lab1_id = create_lab(
        "Advanced Chemistry Laboratory",
        "State-of-the-art chemistry lab with modern analytical instruments",
        "Building A, Floor 3, Room 301"
    )
    
    lab2_id = create_lab(
        "Molecular Biology Laboratory", 
        "Specialized lab for molecular biology research and analysis",
        "Building B, Floor 2, Room 205"
    )
    
    lab3_id = create_lab(
        "Materials Physics Laboratory",
        "Advanced materials characterization and testing facility", 
        "Building C, Floor 1, Room 115"
    )
    
    # Create categories
    print("\n📋 Creating categories...")
    
    # Lab 1 categories
    chem_instruments_id = create_category(
        lab1_id, "Chemical Analysis Instruments", "INSTRUMENTS",
        "Instruments for chemical analysis and characterization"
    )
    
    chemicals_id = create_category(
        lab1_id, "Laboratory Chemicals", "CHEMICALS", 
        "Chemical reagents and solvents for experiments"
    )
    
    # Lab 2 categories  
    bio_instruments_id = create_category(
        lab2_id, "Molecular Biology Equipment", "INSTRUMENTS",
        "Equipment for molecular biology procedures"
    )
    
    bio_chemicals_id = create_category(
        lab2_id, "Biological Reagents", "CHEMICALS",
        "Enzymes, buffers, and biological chemicals"
    )
    
    cultures_id = create_category(
        lab2_id, "Cell Cultures", "CULTURES",
        "Bacterial and mammalian cell cultures"
    )
    
    # Lab 3 categories
    physics_instruments_id = create_category(
        lab3_id, "Materials Testing Equipment", "INSTRUMENTS", 
        "Equipment for materials characterization and testing"
    )
    
    # Create entries
    print("\n🔬 Creating entries...")
    
    # Lab 1 entries (Chemistry)
    create_entry(chem_instruments_id, lab1_id, "HPLC System", "Agilent 1260", "Agilent", 1, "Bench A1", "AVAILABLE")
    create_entry(chem_instruments_id, lab1_id, "FT-IR Spectrometer", "Spectrum 100", "PerkinElmer", 1, "Bench A2", "IN_USE")
    create_entry(chem_instruments_id, lab1_id, "UV-Vis Spectrophotometer", "Lambda 950", "PerkinElmer", 2, "Bench A3", "AVAILABLE")
    
    create_entry(chemicals_id, lab1_id, "Acetonitrile HPLC Grade", "ACN-001", "Fisher Scientific", 5, "Chemical Storage A", "AVAILABLE")
    create_entry(chemicals_id, lab1_id, "Methanol ACS Grade", "MeOH-001", "Sigma-Aldrich", 3, "Chemical Storage A", "AVAILABLE")
    
    # Lab 2 entries (Biology)
    create_entry(bio_instruments_id, lab2_id, "PCR Thermal Cycler", "T100", "Bio-Rad", 2, "Bench B1", "AVAILABLE")
    create_entry(bio_instruments_id, lab2_id, "Fluorescence Microscope", "Eclipse Ti2", "Nikon", 1, "Microscopy Room", "MAINTENANCE")
    create_entry(bio_instruments_id, lab2_id, "Centrifuge", "5424R", "Eppendorf", 3, "Bench B2", "AVAILABLE")
    
    create_entry(bio_chemicals_id, lab2_id, "Taq DNA Polymerase", "TAQ-001", "New England Biolabs", 10, "Freezer B1", "AVAILABLE")
    create_entry(bio_chemicals_id, lab2_id, "PBS Buffer 10x", "PBS-001", "Thermo Fisher", 8, "Refrigerator B1", "AVAILABLE")
    
    create_entry(cultures_id, lab2_id, "E. coli DH5α", "EC-DH5", "Lab Stock", 5, "Freezer B2", "AVAILABLE")
    
    # Lab 3 entries (Physics)
    create_entry(physics_instruments_id, lab3_id, "X-Ray Diffractometer", "MiniFlex 600", "Rigaku", 1, "Analysis Room C1", "AVAILABLE")
    
    print("\n✅ Successfully seeded inventory data!")
    print("📊 Created:")
    print("   • 3 Labs")
    print("   • 6 Categories") 
    print("   • 12 Entries")

if __name__ == "__main__":
    main() 