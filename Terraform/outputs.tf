output "visitor_count" {
    value = aws_dynamodb_table.my_table.name
  
}
output "dynamodb_table_arn" {
    value = aws_dynamodb_table.my_table.arn
  
}

output "resume_site" {
  value = aws_s3_bucket.resume_site.bucket
}