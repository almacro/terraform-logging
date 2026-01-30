mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/test-user"
      user_id    = "AIDAEXAMPLE"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = <<-JSON
        {
          "Version": "2012-10-17",
          "Statement": [{
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Principal": { "AWS": "arn:aws:iam::123456789012:root" }
          }]
        }
      JSON
    }
  }

  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::123456789012:policy/mock-policy"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mock-role"
    }
  }

  mock_resource "aws_s3_bucket" {
    defaults = {
      arn = "arn:aws:s3:::mock-bucket"
    }
  }
}

variables {
  logging_bucket_name     = "test-logs"
  environment             = "test"
  log_writer_trusted_arns = ["arn:aws:iam::123456789012:role/fluentbit"]
  log_reader_trusted_arns = ["arn:aws:iam::123456789012:role/elk"]
}

run "bucket_policy_attached" {
  command = apply

  assert {
    condition     = aws_s3_bucket_policy.logging.bucket == aws_s3_bucket.logging.id
    error_message = "Bucket policy should be attached to the logging bucket"
  }
}

run "bucket_policy_contains_ssl_enforcement" {
  command = apply

  assert {
    condition     = can(regex("DenyNonSSLRequests", aws_s3_bucket_policy.logging.policy))
    error_message = "Bucket policy should contain SSL enforcement statement"
  }

  assert {
    condition     = can(regex("aws:SecureTransport", aws_s3_bucket_policy.logging.policy))
    error_message = "Bucket policy should check SecureTransport condition"
  }
}

run "bucket_policy_contains_writer_access" {
  command = apply

  assert {
    condition     = can(regex("AllowLogWriterPutObject", aws_s3_bucket_policy.logging.policy))
    error_message = "Bucket policy should contain log writer access statement"
  }

  assert {
    condition     = can(regex("s3:PutObject", aws_s3_bucket_policy.logging.policy))
    error_message = "Bucket policy should allow PutObject action"
  }
}

run "bucket_policy_contains_reader_access" {
  command = apply

  assert {
    condition     = can(regex("AllowLogReaderAccess", aws_s3_bucket_policy.logging.policy))
    error_message = "Bucket policy should contain log reader access statement"
  }

  assert {
    condition     = can(regex("AllowLogReaderListBucket", aws_s3_bucket_policy.logging.policy))
    error_message = "Bucket policy should contain log reader list bucket statement"
  }

  assert {
    condition     = can(regex("s3:GetObject", aws_s3_bucket_policy.logging.policy))
    error_message = "Bucket policy should allow GetObject action"
  }

  assert {
    condition     = can(regex("s3:ListBucket", aws_s3_bucket_policy.logging.policy))
    error_message = "Bucket policy should allow ListBucket action"
  }
}
