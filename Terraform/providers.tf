terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = ">= 6.21.0,< 7.0.0"
    }
    archive ={
      source = "hashicorp/archive"
      version = "~>2.0"
    }
  }
}

provider "aws" {
    region = "us-east-2"
    profile = "terraform-project"
  
}
data "aws_caller_identity" "current" {}

