
# OBSERVABILITY
# Log retention · custom EMF metrics · CloudWatch dashboard ·
# milestone SNS topic · API Gateway 5xx alarm.
# EMF metrics need no extra IAM — they ride inside the logs.


locals {
  lambda_function_name=aws_lambda_function.lambda_visitor_count.function_name
  api_id = aws_apigatewayv2_api.visitor_api.id
  table_name = aws_dynamodb_table.my_table.name
}

# Log group with 30-day rentention (keep log costs bounded)
resource "aws_cloudwatch_log_group" "lambda_logs" {
    name = "/aws/lambda/${local.lambda_function_name}"
    retention_in_days = 30
    tags = {
      Project = "StaticWebsiteHosting"
    }
  
}

# IAM: Allow the lambda to publish milestone notifications
resource "aws_iam_role_policy" "lambda_milestone_publish" {
    name = "lambda-milestone-sns-publish"
    role = aws_iam_role.lambda_exec.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect =  "Allow"
                Action = ["sns:Publish"]
                Resource = aws_sns_topic.milestones.arn
            }
        ]
    })
  
}

# Milestone topic (100th,200th,... visitor)
resource "aws_sns_topic" "milestones" {
    name = "cloud-resume-milestones"
  
}
resource "aws_sns_topic_subscription" "milestone_email" {
    topic_arn = aws_sns_topic.milestones.arn
    protocol = "email"
    endpoint = "alfiyatamboli8@gmail.com"
  
}

# API Gateway 5xx alarm
resource "aws_cloudwatch_metric_alarm" "api_5xx" {
    alarm_name = "visitor-counter-api-5xx"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods = 1
    metric_name = "5XXError"
    namespace = "AWS/ApiGateway"
    period = 300
    statistic = "Sum"
    threshold = 0
    treat_missing_data = "notBreaching"
    alarm_description = "Alerts if API Gateway returns a 5xx for the visitor count API"
    dimensions = {ApiId = local.api_id}
    alarm_actions = [aws_sns_topic.alerts.arn]
  
}

# The Dashboard
resource "aws_cloudwatch_dashboard" "cloud_resume" {
    dashboard_name = "cloud-resume-dashboard"
    dashboard_body = jsonencode({
        widgets = [
            {
                type="metric"
                x=0
                y=0
                width = 8
                height=6
                properties={
                    title = "Lambda-Traffic"
                    region = "us-east-2"
                    view = "timeSeries"
                    stat = "Sum"
                    period= 300
                    metrics =[ 
                        ["AWS/Lambda", "Invocations", "FunctionName", local.lambda_function_name ],
                        ["AWS/Lambda", "Errors", "FunctionName", local.lambda_function_name],
                        ["AWS/Lambda","Throttles","FunctionName",local.lambda_function_name],
                    ]
                }
            },
            {
                type = "metric"
                x=8
                y=0
                width=8
                height=6
                properties={
                    title="Lambda-Duration"
                    region ="us-east-2"
                    view="timeSeries"
                    period= 300
                    metrics=[
                        ["AWS/Lambda", "Duration", "FunctionName",local.lambda_function_name,{stat="Average"}],
                        ["AWS/Lambda", "Duration", "FunctionName",local.lambda_function_name,{stat="p95"}],
                        ["AWS/Lambda", "Duration", "FunctionName",local.lambda_function_name,{stat="Maximum"}],
                    ]
                }
            },
            {
                type   = "metric"
                x      = 16
                y      = 0
                width  = 8
                height = 6
                properties = {
                    title  = "API Gateway — Requests & Errors"
                    region = "us-east-2"
                    view   = "timeSeries"
                    stat   = "Sum"
                    period = 300
                    metrics = [
                      ["AWS/ApiGateway", "Count", "ApiId", local.api_id],
                      ["AWS/ApiGateway", "4XXError", "ApiId", local.api_id],
                      ["AWS/ApiGateway", "5XXError", "ApiId", local.api_id],
                      ["AWS/ApiGateway", "Latency", "ApiId", local.api_id, { stat = "p95", yAxis = "right" }],
                    ]
                }       
            },
            {
                type   = "metric"
                x      = 0
                y      = 6
                width  = 8
                height = 6
                properties = {
                    title  = "DynamoDB — visitor table"
                    region = "us-east-2"
                    view   = "timeSeries"
                    stat   = "Sum"
                    period = 300
                    metrics = [
                      ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", local.table_name],
                      ["AWS/DynamoDB", "ConsumedWriteCapacityUnits", "TableName", local.table_name],
                      ["AWS/DynamoDB", "ThrottledRequests", "TableName", local.table_name],
                      ["AWS/DynamoDB", "SuccessfulRequestLatency", "TableName", local.table_name, { stat = "Average", yAxis = "right" }],
                    ]
                }
            },
            {
                type   = "metric"
                x      = 8
                y      = 6
                width  = 8
                height = 6
                properties = {
                    title  = "Custom Metrics (EMF) — CloudResume"
                    region = "us-east-2"
                    view   = "timeSeries"
                    period = 300
                    metrics = [
                      ["CloudResume", "VisitorCount", { stat = "Maximum", label = "Latest visitor count" }],
                      ["CloudResume", "VisitorMilestone", { stat = "Maximum", label = "Milestones hit" }],
                      ["CloudResume", "HandlerError", { stat = "Sum", label = "Handler errors" }],
                    ]
                }
            },
            {
                type   = "metric"
                x      = 16
                y      = 6
                width  = 8
                height = 6
                properties = {
                    title  = "Alarm Status"
                    region = "us-east-2"
                    alarms = [
                      aws_cloudwatch_metric_alarm.lambda_errors.arn,
                      aws_cloudwatch_metric_alarm.dynamodb_throttles.arn,
                      aws_cloudwatch_metric_alarm.api_5xx.arn,
                    ]
                }
            },
            {
                type   = "log"
                x      = 0
                y      = 12
                width  = 12
                height = 7
                properties = {
                    title  = "Recent Requests — structured JSON logs"
                    region = "us-east-2"
                    view   = "table"
                    query  = <<-EOT
                      fields @timestamp, level, message, new_count, duration_ms, source_ip, cold_start
                      | filter ispresent(new_count)
                      | sort @timestamp desc
                      | limit 30
                    EOT
                }
            },
            {
                type   = "log"
                x      = 12
                y      = 12
                width  = 6
                height = 7
                properties = {
                    title  = "Recent Errors"
                    region = "us-east-2"
                    view   = "table"
                    query  = <<-EOT
                      fields @timestamp, message, error_type, error
                      | filter level = "ERROR"
                      | sort @timestamp desc
                      | limit 20
                    EOT
                }
            },
            {
                type   = "log"
                x      = 18
                y      = 12
                width  = 6
                height = 7
                properties = {
                    title  = "Visitor Milestones"
                    region = "us-east-2"
                    view   = "table"
                    query  = <<-EOT
                      fields @timestamp, milestone
                      | filter ispresent(milestone)
                      | sort @timestamp desc
                      | limit 20
                    EOT
                }
            },
        ]
    })
  
}