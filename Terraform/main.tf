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