output "visitor_count" {
    value = aws_dynamodb_table.my_table.name
  
}
output "dynamodb_table_arn" {
    value = aws_dynamodb_table.my_table.arn
  
}

output "resume_site" {
  value = aws_s3_bucket.resume_site.bucket
}
output "cloudwatch_dashboard_url" {
  value = "https://us-east-2.console.aws.amazon.com/cloudwatch/home?region=us-east-2#dashboards:name=${aws_cloudwatch_dashboard.cloud_resume.dashboard_name}"
}