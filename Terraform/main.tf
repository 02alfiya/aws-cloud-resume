resource "aws_dynamodb_table" "my_table"{
    name = "visitor_count"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "id"
    attribute {
      name = "id"
      type = "S"
    }

    tags = {
      Project = "StaticWebsiteHosting"
    }
}

resource "aws_s3_bucket" "resume_site" {
  bucket = "alfiyajaved.in"

  tags = {
    Project = "StaticWebsiteHosting"
  }
  
}

resource "aws_s3_bucket_public_access_block" "resume_site" {
  bucket = aws_s3_bucket.resume_site.id

  block_public_acls =false
  block_public_policy = false
  ignore_public_acls = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "resume_site" {
  bucket = aws_s3_bucket.resume_site.id

  policy = jsonencode({
    Version = "2008-10-17"
    Id = "PolicyForCloudFrontPrivateContent"
    Statement = [
      {
        Sid = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.resume_site.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${var.cloudfront_distribution_id}"          
          }

        }
      }
    ]
  })
}


resource "aws_iam_role" "lambda_exec" {
  name = "visitor_count_function-role-dbxa8sz4"
  path = "/service-role/"


  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::046276255165:policy/service-role/AWSLambdaBasicExecutionRole-572c4e08-f140-423a-8cc4-ca2a6a3ca886"
  
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_full" {
  role = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  
}

data "archive_file" "lambda_zip" {
  type = "zip"
  source_file = "${path.module}/../Backend/lambda_function.py"
  output_path = "${path.module}/../Backend/lambda_function.zip"
  
}

resource "aws_lambda_function" "lambda_visitor_count" {
  function_name = "visitor_count_function"
  role = aws_iam_role.lambda_exec.arn
  handler = "lambda_function.lambda_handler"
  runtime = "python3.14"
  filename = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_sha256
 
}

resource "aws_apigatewayv2_api" "visitor_api" {
  name = "ResumeCounterAPI"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["https://alfiyajaved.in"]
    allow_methods = ["GET"]
    allow_credentials = false
  }
  
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id = aws_apigatewayv2_api.visitor_api.id
  integration_type = "AWS_PROXY"
  integration_uri = aws_lambda_function.lambda_visitor_count.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
  
}

resource "aws_apigatewayv2_route" "visitor_route" {
  api_id = aws_apigatewayv2_api.visitor_api.id
  route_key = "GET /count"
  target = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"

  
}

resource "aws_apigatewayv2_stage" "default" {
  api_id = aws_apigatewayv2_api.visitor_api.id
  name = "$default"
  auto_deploy = true
  
}

resource "aws_lambda_permission" "api_gw_invoke" {
  statement_id = "920bc905-0418-5827-8219-767b32a2ecc3"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_visitor_count.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.visitor_api.execution_arn}/*/*/count"
  
}
