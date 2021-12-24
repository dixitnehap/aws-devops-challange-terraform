# Input variable definitions

variable "aws_region" {
  description = "AWS region for all resources."

  type    = string
  default = "eu-central-1"
}

variable "s3_bucket_name" {
  description = "AWS terraform s3 bucket name"

  type    = string
  default = "aws-devops-terraform-managed-default-terraformsourcebucket"
}

