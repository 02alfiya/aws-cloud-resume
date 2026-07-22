output "visitor_count" {
    value = aws_dynamodb_table.my_table.name
  
}
output "dynamodb_table_arn" {
    value = aws_dynamodb_table.my_table.arn
  
}