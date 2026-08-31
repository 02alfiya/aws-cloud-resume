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

  block_public_acls = true
  block_public_policy = true
  ignore_public_acls =  true
  restrict_public_buckets = true
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

resource "aws_iam_role_policy" "lambda_dynamodb_scoped" {
  name = "lambda-dynamodb-scoped-access"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["dynamodb:UpdateItem"]
        Resource = aws_dynamodb_table.my_table.arn
      }
    ]
  })
  
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

resource "aws_route53_zone" "main" {
  name = "alfiyajaved.in"
  
}

resource "aws_route53_record" "root_alias" {
  zone_id = aws_route53_zone.main.zone_id
  name = "alfiyajaved.in"
  type = "A"

  alias {
    name = "d1yceq88f9ew74.cloudfront.net"
    zone_id = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
  
}

resource "aws_acm_certificate" "cert" {
  provider = aws.us_east_1
  domain_name = "alfiyajaved.in"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
  
}

resource "aws_cloudfront_origin_access_control" "resume_site_oac" {
  name = "alfiyajaved.in.s3.us-east-2.amazonaws.com"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"
  
}

resource "aws_cloudfront_distribution" "resume_site_CDN" {
  enabled = true
  comment = "Used for static website hosting"
  default_root_object = "index.html"
  http_version = "http2"
  price_class = "PriceClass_All"
  aliases = ["alfiyajaved.in"]
  is_ipv6_enabled = true
  web_acl_id = "arn:aws:wafv2:us-east-1:046276255165:global/webacl/CreatedByCloudFront-0db22b05/fdddc405-4f80-4138-9df8-5976e26b302f"
  
  origin {
    domain_name = aws_s3_bucket.resume_site.bucket_regional_domain_name
    origin_id = "alfiyajaved.in.s3.us-east-2.amazonaws.com-mnlfwp5tdce"
    origin_access_control_id = aws_cloudfront_origin_access_control.resume_site_oac.id
    connection_attempts = 3
    connection_timeout = 10
  }

  default_cache_behavior {
    target_origin_id = "alfiyajaved.in.s3.us-east-2.amazonaws.com-mnlfwp5tdce"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods = ["HEAD", "GET"]
    cached_methods = ["HEAD", "GET"]
    compress = true
  
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cert.arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Name = "alfiyajaved.in"
  }
}

data "tls_certificate" "github_actions" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"

  
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = [ "sts.amazonaws.com" ]
  thumbprint_list = [ data.tls_certificate.github_actions.certificates[0].sha1_fingerprint ]
  
}

resource "aws_iam_role" "github_actions_deploy" {
  name = "github-actions-deploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:02alfiya/aws-cloud-resume:ref:refs/heads/main"
          }
        }
      }
    ]
  })
  
}

resource "aws_iam_role_policy" "github_actions_deploy_policy" {
  name = "github-actions-deploy-policy"
  role = aws_iam_role.github_actions_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:PutObject", "s3:GetObject", "s3:ListBucket","s3:DeleteObject"]
        Resource = [aws_s3_bucket.resume_site.arn,"${aws_s3_bucket.resume_site.arn}/*"]

      },
      {
        Effect = "Allow"
        Action = "cloudfront:CreateInvalidation"
        Resource = aws_cloudfront_distribution.resume_site_CDN.arn
      },
      {
        Effect = "Allow"
        Action = "lambda:UpdateFunctionCode"
        Resource = aws_lambda_function.lambda_visitor_count.arn
      }
    ]
  })
  
}