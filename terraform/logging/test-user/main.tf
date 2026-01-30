# Dedicated Terraform Test User
#
# This module creates an IAM user specifically for running Terraform tests.
# Deploy this once, then use the created user's credentials for test runs.
#
# Usage:
#   cd test-user
#   terraform init
#   terraform apply
#
# Then configure AWS CLI profile with the access keys from outputs.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

variable "user_name" {
  description = "Name for the test user"
  type        = string
  default     = "terraform-test-runner"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "test"
}

# Get current account ID
data "aws_caller_identity" "current" {}

# Create the test user
resource "aws_iam_user" "test_runner" {
  name = var.user_name
  path = "/test/"

  tags = {
    Name        = var.user_name
    Environment = var.environment
    Purpose     = "Terraform integration test runner"
  }
}

# Policy granting permissions needed to run the logging module tests
resource "aws_iam_user_policy" "test_runner" {
  name = "${var.user_name}-policy"
  user = aws_iam_user.test_runner.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3BucketManagement"
        Effect = "Allow"
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:ListBucket",
          "s3:Get*",
          "s3:Put*",
          "s3:DeleteBucketPolicy"
        ]
        Resource = "arn:aws:s3:::tf-test-*"
      },
      {
        Sid    = "IAMRoleManagement"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:UpdateRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/log-writer-*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/log-reader-*"
        ]
      },
      {
        Sid    = "IAMPolicyManagement"
        Effect = "Allow"
        Action = [
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicyVersions",
          "iam:TagPolicy",
          "iam:UntagPolicy"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/log-writer-*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/log-reader-*"
        ]
      },
      {
        Sid    = "IAMPolicyAttachment"
        Effect = "Allow"
        Action = [
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/log-writer-*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/log-reader-*"
        ]
        Condition = {
          ArnLike = {
            "iam:PolicyARN" = [
              "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/log-writer-*",
              "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/log-reader-*"
            ]
          }
        }
      },
      {
        Sid      = "GetCallerIdentity"
        Effect   = "Allow"
        Action   = "sts:GetCallerIdentity"
        Resource = "*"
      }
    ]
  })
}

# Create access keys for the test user
resource "aws_iam_access_key" "test_runner" {
  user = aws_iam_user.test_runner.name
}

# Outputs
output "test_user_arn" {
  description = "ARN of the test user (use as trusted principal)"
  value       = aws_iam_user.test_runner.arn
}

output "test_user_name" {
  description = "Name of the test user"
  value       = aws_iam_user.test_runner.name
}

output "access_key_id" {
  description = "Access key ID for the test user"
  value       = aws_iam_access_key.test_runner.id
}

output "secret_access_key" {
  description = "Secret access key for the test user"
  value       = aws_iam_access_key.test_runner.secret
  sensitive   = true
}

output "aws_profile_config" {
  description = "Add this to ~/.aws/credentials"
  sensitive   = true
  value       = <<-EOT
    [terraform-test]
    aws_access_key_id = ${aws_iam_access_key.test_runner.id}
    aws_secret_access_key = ${aws_iam_access_key.test_runner.secret}
  EOT
}
