variable "cloudfront_distribution_id" {
    description = "Cloudfront distribution ID used in the s3 bucket policy condtion"
    type = string
    default = "E2F6MEC5BIFAER"
  
}

variable "milestone_step" {
    description = "Announce every Nth visitor as a milestone(0 disables)"
    type = number
    default = 100
  
}
