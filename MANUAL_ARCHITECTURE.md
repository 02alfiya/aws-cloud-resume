# Cloud Resume Challenge - Manual Architecture

Before transitioning to Infrastructure as Code (Terraform), I provisioned this entire serverless architecture manually via the AWS Management Console to deeply understand the underlying networking, IAM permissions, and service integrations.

## 🏗️ Architecture Flow
**Frontendpath(Load website)**
```User types alfiyajaved.in
→ Route 53 resolves domain → returns CloudFront address → Browser connects to CloudFront → CloudFront checks cache: hit? serve it. miss? fetch from S3 → HTML/CSS/JS delivered to browser
```
**Backend path(Visitor count)**
```JavaScript in the browser calls API Gateway endpoint
→ API Gateway receives the HTTP request → API Gateway invokes your Lambda function → Lambda runs Python code, calls DynamoDB via boto3 → DynamoDB increments counter, returns new value → Lambda returns value → API Gateway → JavaScript → displayed on page
```

1. **Frontend:** Hosted on an Amazon S3 Bucket configured for static website hosting.
2. **DNS & CDN:** Routed via Route 53 and cached globally using Amazon CloudFront.
3. **API Routing:** Amazon API Gateway triggers the backend via a GET method.
4. **Compute:** AWS Lambda executes the Python logic to update visitor counts.
5. **Database:** Amazon DynamoDB stores the persistent visitor count.

## 🔐 IAM Policies

To allow my Lambda function to securely read and update my DynamoDB table, I created a custom IAM Execution Role. Here is the exact JSON policy I configured:

```json
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
        'headers': {
            'Access-Control-Allow-Origin': '*' # Crucial! This allows web browser to accept the data
        },
        'body': json.dumps({'visitor_count': new_count})
    }
    ```