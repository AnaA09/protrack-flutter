import boto3
import json
from botocore.exceptions import ClientError

def get_cognito_tokens(username, password, user_pool_id, client_id):
    try:
        # Initialize Cognito client
        client = boto3.client('cognito-idp')
        
        # Authenticate user
        response = client.initiate_auth(
            AuthFlow='USER_PASSWORD_AUTH',
            AuthParameters={
                'USERNAME': username,
                'PASSWORD': password
            },
            ClientId=client_id
        )
        
        # Check if we need to handle a challenge
        if 'ChallengeName' in response:
            print(f"Challenge required: {response['ChallengeName']}")
            if response['ChallengeName'] == 'NEW_PASSWORD_REQUIRED':
                new_password = input("Enter new password: ")
                
                # Get required attributes from the challenge
                required_attributes = json.loads(response['ChallengeParameters'].get('requiredAttributes', '[]'))
                user_attributes = {}
                
                # Always include name attribute
                name = input("Enter your full name: ")
                user_attributes['name'] = name
                
                # Prompt for other required attributes
                for attr in required_attributes:
                    if attr != 'name':  # Skip name as we already have it
                        value = input(f"Enter {attr}: ")
                        user_attributes[attr] = value
                
                # Format userAttributes as required by Cognito
                formatted_attributes = {}
                for key, value in user_attributes.items():
                    formatted_attributes[f'userAttributes.{key}'] = value
                
                response = client.respond_to_auth_challenge(
                    ClientId=client_id,
                    ChallengeName='NEW_PASSWORD_REQUIRED',
                    ChallengeResponses={
                        'USERNAME': username,
                        'NEW_PASSWORD': new_password,
                        **formatted_attributes
                    },
                    Session=response['Session']
                )
        
        # Extract tokens
        if 'AuthenticationResult' in response:
            tokens = {
                'access_token': response['AuthenticationResult']['AccessToken'],
                'id_token': response['AuthenticationResult']['IdToken'],
                'refresh_token': response['AuthenticationResult']['RefreshToken']
            }
            return tokens
        else:
            print("Authentication failed. Response:", json.dumps(response, indent=2))
            return None
        
    except ClientError as e:
        print(f"Error: {e}")
        return None

def main():
    # Configuration
    USER_POOL_ID = "us-east-1_oEvEdG7hY"  # Your User Pool ID
    CLIENT_ID = "112eapunjrouch2koprr5kf5hd"  # Your Client ID
    
    # Get credentials from user
    username = input("Enter username: ")
    password = input("Enter password: ")
    
    # Get tokens
    tokens = get_cognito_tokens(username, password, USER_POOL_ID, CLIENT_ID)
    
    if tokens:
        print("\nTokens received successfully:")
        print(f"Access Token: {tokens['access_token']}")
        print(f"ID Token: {tokens['id_token']}")
        print(f"Refresh Token: {tokens['refresh_token']}")
        
        # Save tokens to file for testing
        with open('cognito_tokens.json', 'w') as f:
            json.dump(tokens, f, indent=2)
        print("\nTokens saved to cognito_tokens.json")
        print("use jq to export the tokens to the environment variables")
        print("export ACCESS_TOKEN=$(jq -r '.access_token' cognito_tokens.json)")
        #print("export AWS_ID_TOKEN=$(jq -r '.id_token' cognito_tokens.json)")
        #print("export AWS_REFRESH_TOKEN=$(jq -r '.refresh_token' cognito_tokens.json)")

if __name__ == "__main__":
    main() 