import boto3
import json

dynamodb = boto3.resource('dynamodb')
projects_table = dynamodb.Table('Projects')

def test_project_retrieval():
    project_id = "fa93a931-42b4-4cbc-982a-425e04766577"
    
    try:
        response = projects_table.get_item(Key={'projectId': project_id})
        project = response.get('Item', {})
        
        if project:
            print(f"✅ Project found: {json.dumps(project, indent=2, default=str)}")
        else:
            print(f"❌ Project {project_id} not found")
            
        # List all projects to see what's available
        print("\nAll projects in the table:")
        response = projects_table.scan()
        for item in response.get('Items', []):
            print(f"- {item.get('projectId')}: {item.get('name', 'No name')}")
            
    except Exception as e:
        print(f"Error retrieving project: {e}")

if __name__ == '__main__':
    test_project_retrieval() 