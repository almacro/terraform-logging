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
  log_writer_trusted_arns = ["arn:aws:iam::123456789012:root"]
  log_reader_trusted_arns = ["arn:aws:iam::123456789012:root"]
}

run "bucket_name_format" {
  command = apply

  assert {
    condition     = aws_s3_bucket.logging.bucket == "test-logs-test"
    error_message = "S3 bucket name should be test-logs-test"
  }
}

run "bucket_name_with_different_environment" {
  command = apply

  variables {
    logging_bucket_name = "apps-logs"
    environment         = "prod"
  }

  assert {
    condition     = aws_s3_bucket.logging.bucket == "apps-logs-prod"
    error_message = "S3 bucket name should be apps-logs-prod"
  }
}

run "bucket_tags" {
  command = apply

  assert {
    condition     = aws_s3_bucket.logging.tags["Environment"] == "test"
    error_message = "Bucket should have Environment tag set to test"
  }

  assert {
    condition     = aws_s3_bucket.logging.tags["Name"] == "test-logs-test"
    error_message = "Bucket should have Name tag matching bucket name"
  }
}

run "versioning_enabled" {
  command = apply

  assert {
    condition     = aws_s3_bucket_versioning.logging.versioning_configuration[0].status == "Enabled"
    error_message = "Bucket versioning should be enabled"
  }
}

run "encryption_uses_aes256" {
  command = apply

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.logging.rule[*].apply_server_side_encryption_by_default[0].sse_algorithm) == "AES256"
    error_message = "Bucket encryption should use AES256"
  }
}

run "public_access_blocked" {
  command = apply

  assert {
    condition     = aws_s3_bucket_public_access_block.logging.block_public_acls == true
    error_message = "block_public_acls should be true"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.logging.block_public_policy == true
    error_message = "block_public_policy should be true"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.logging.ignore_public_acls == true
    error_message = "ignore_public_acls should be true"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.logging.restrict_public_buckets == true
    error_message = "restrict_public_buckets should be true"
  }
}

run "invalid_region_rejected" {
  command = plan

  variables {
    aws_region = "ap-southeast-1"
  }

  expect_failures = [var.aws_region]
}

run "valid_region_accepted" {
  command = plan

  variables {
    aws_region = "us-east-1"
  }
}
