import json
import boto3

# 1. Connect to the DynamoDB table
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('visitor_count')

def lambda_handler(event, context):
    
    # 2. Update the count in the database (Add 1 to 'views')
    response = table.update_item(
        Key={
            'id': 'count' # The Partition Key 
        },
        UpdateExpression='ADD #c :inc',   #We use '#c' to avoid conflict with reserved word 'count'
        ExpressionAttributeNames={
            '#c': 'count' #this tells db that '#c' means count
        },
        ExpressionAttributeValues={
            ':inc': 1
        },
        ReturnValues='UPDATED_NEW'
    )
    
    # 3. Extract the updated count from the database response
    # Convert it to an integer so it formats nicely in the JSON
    new_count = int(response['Attributes']['count'])
    
    # 4. Return the data to API Gateway (and eventually your JavaScript)
    return {
        'statusCode': 200,
 
        'body': json.dumps({'visitor_count': new_count})
    }