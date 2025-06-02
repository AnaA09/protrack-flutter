import boto3
import os
from datetime import datetime, timedelta
import uuid

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')

# Get table references
instruments_table = dynamodb.Table(os.environ['INSTRUMENTS_TABLE'])
projects_table = dynamodb.Table(os.environ['PROJECTS_TABLE'])
tasks_table = dynamodb.Table(os.environ['TASKS_TABLE'])
activities_table = dynamodb.Table(os.environ['ACTIVITIES_TABLE'])

def create_sample_instruments():
    instruments = [
        {
            'instrumentId': str(uuid.uuid4()),
            'name': 'Microscope X1000',
            'description': 'High-precision optical microscope',
            'manufacturer': 'OptiTech',
            'model': 'X1000',
            'serialNumber': 'MT-2023-001',
            'location': 'Lab A',
            'status': 'AVAILABLE',
            'createdAt': datetime.utcnow().isoformat(),
            'updatedAt': datetime.utcnow().isoformat()
        },
        {
            'instrumentId': str(uuid.uuid4()),
            'name': 'Spectrometer Pro',
            'description': 'Advanced spectral analysis device',
            'manufacturer': 'SpecTech',
            'model': 'SP-2000',
            'serialNumber': 'SP-2023-002',
            'location': 'Lab B',
            'status': 'AVAILABLE',
            'createdAt': datetime.utcnow().isoformat(),
            'updatedAt': datetime.utcnow().isoformat()
        },
        {
            'instrumentId': str(uuid.uuid4()),
            'name': 'Centrifuge Max',
            'description': 'High-speed centrifuge for sample preparation',
            'manufacturer': 'SpinTech',
            'model': 'CM-5000',
            'serialNumber': 'CF-2023-003',
            'location': 'Lab C',
            'status': 'AVAILABLE',
            'createdAt': datetime.utcnow().isoformat(),
            'updatedAt': datetime.utcnow().isoformat()
        }
    ]
    
    for instrument in instruments:
        instruments_table.put_item(Item=instrument)
        print(f"Created instrument: {instrument['name']}")
    
    return instruments

def create_sample_projects(instruments):
    projects = [
        {
            'projectId': str(uuid.uuid4()),
            'name': 'Cell Analysis Study',
            'description': 'Comprehensive study of cell structures using advanced microscopy',
            'status': 'OPEN',
            'createdBy': 'user123',
            'requiredInstruments': [instruments[0]['instrumentId'], instruments[1]['instrumentId']],
            'startDate': (datetime.utcnow() - timedelta(days=5)).isoformat(),
            'endDate': (datetime.utcnow() + timedelta(days=25)).isoformat(),
            'createdAt': datetime.utcnow().isoformat(),
            'updatedAt': datetime.utcnow().isoformat()
        },
        {
            'projectId': str(uuid.uuid4()),
            'name': 'Protein Separation Research',
            'description': 'Research on protein separation techniques using centrifugation',
            'status': 'OPEN',
            'createdBy': 'user123',
            'requiredInstruments': [instruments[2]['instrumentId']],
            'startDate': (datetime.utcnow() - timedelta(days=2)).isoformat(),
            'endDate': (datetime.utcnow() + timedelta(days=28)).isoformat(),
            'createdAt': datetime.utcnow().isoformat(),
            'updatedAt': datetime.utcnow().isoformat()
        }
    ]
    
    for project in projects:
        projects_table.put_item(Item=project)
        print(f"Created project: {project['name']}")
    
    return projects

def create_sample_tasks(projects):
    tasks = []
    
    # Tasks for Cell Analysis Study
    tasks.extend([
        {
            'taskId': str(uuid.uuid4()),
            'projectId': projects[0]['projectId'],
            'name': 'Microscopy Setup',
            'description': 'Set up and calibrate the microscope for cell analysis',
            'status': 'OPEN',
            'requiredInstruments': [projects[0]['requiredInstruments'][0]],
            'startDate': (datetime.utcnow() - timedelta(days=4)).isoformat(),
            'dueDate': (datetime.utcnow() + timedelta(days=1)).isoformat(),
            'priority': 1,
            'createdAt': datetime.utcnow().isoformat(),
            'updatedAt': datetime.utcnow().isoformat()
        },
        {
            'taskId': str(uuid.uuid4()),
            'projectId': projects[0]['projectId'],
            'name': 'Spectral Analysis',
            'description': 'Perform spectral analysis of cell samples',
            'status': 'OPEN',
            'requiredInstruments': [projects[0]['requiredInstruments'][1]],
            'startDate': (datetime.utcnow() + timedelta(days=2)).isoformat(),
            'dueDate': (datetime.utcnow() + timedelta(days=5)).isoformat(),
            'priority': 2,
            'createdAt': datetime.utcnow().isoformat(),
            'updatedAt': datetime.utcnow().isoformat()
        }
    ])
    
    # Tasks for Protein Separation Research
    tasks.extend([
        {
            'taskId': str(uuid.uuid4()),
            'projectId': projects[1]['projectId'],
            'name': 'Centrifuge Calibration',
            'description': 'Calibrate the centrifuge for protein separation',
            'status': 'OPEN',
            'requiredInstruments': [projects[1]['requiredInstruments'][0]],
            'startDate': (datetime.utcnow() - timedelta(days=1)).isoformat(),
            'dueDate': (datetime.utcnow() + timedelta(days=2)).isoformat(),
            'priority': 1,
            'createdAt': datetime.utcnow().isoformat(),
            'updatedAt': datetime.utcnow().isoformat()
        }
    ])
    
    for task in tasks:
        tasks_table.put_item(Item=task)
        print(f"Created task: {task['name']}")
    
    return tasks

def create_sample_activities(tasks):
    activities = []
    
    # Activities for Microscopy Setup task
    activities.extend([
        {
            'activityId': str(uuid.uuid4()),
            'taskId': tasks[0]['taskId'],
            'projectId': tasks[0]['projectId'],
            'name': 'Initial Calibration',
            'description': 'Perform initial calibration of the microscope',
            'status': 'IN_PROGRESS',
            'usedInstruments': [tasks[0]['requiredInstruments'][0]],
            'startTime': (datetime.utcnow() - timedelta(hours=2)).isoformat(),
            'performedBy': 'user123',
            'createdAt': datetime.utcnow().isoformat(),
            'updatedAt': datetime.utcnow().isoformat()
        }
    ])
    
    # Activities for Centrifuge Calibration task
    activities.extend([
        {
            'activityId': str(uuid.uuid4()),
            'taskId': tasks[2]['taskId'],
            'projectId': tasks[2]['projectId'],
            'name': 'Speed Calibration',
            'description': 'Calibrate centrifuge speed settings',
            'status': 'COMPLETED',
            'usedInstruments': [tasks[2]['requiredInstruments'][0]],
            'startTime': (datetime.utcnow() - timedelta(hours=4)).isoformat(),
            'endTime': (datetime.utcnow() - timedelta(hours=2)).isoformat(),
            'performedBy': 'user123',
            'results': {'maxSpeed': '15000', 'calibrationStatus': 'success'},
            'createdAt': datetime.utcnow().isoformat(),
            'updatedAt': datetime.utcnow().isoformat()
        }
    ])
    
    for activity in activities:
        activities_table.put_item(Item=activity)
        print(f"Created activity: {activity['name']}")

def main():
    print("Starting data seeding...")
    
    # Create sample data in order
    instruments = create_sample_instruments()
    projects = create_sample_projects(instruments)
    tasks = create_sample_tasks(projects)
    create_sample_activities(tasks)
    
    print("Data seeding completed!")

if __name__ == "__main__":
    main() 