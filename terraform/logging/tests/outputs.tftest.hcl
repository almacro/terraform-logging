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

run "outputs_are_set" {
  command = apply

  assert {
    condition     = output.logging_bucket_arn != null && output.logging_bucket_arn != ""
    error_message = "logging_bucket_arn output should be set"
  }

  assert {
    condition     = output.logging_bucket_name != null && output.logging_bucket_name != ""
    error_message = "logging_bucket_name output should be set"
  }

  assert {
    condition     = output.log_writer_role_arn != null && output.log_writer_role_arn != ""
    error_message = "log_writer_role_arn output should be set"
  }

  assert {
    condition     = output.log_reader_role_arn != null && output.log_reader_role_arn != ""
    error_message = "log_reader_role_arn output should be set"
  }
}

run "bucket_name_output_matches_bucket" {
  command = apply

  assert {
    condition     = output.logging_bucket_name == aws_s3_bucket.logging.id
    error_message = "logging_bucket_name output should match bucket id"
  }
}

run "bucket_arn_output_matches_bucket" {
  command = apply

  assert {
    condition     = output.logging_bucket_arn == aws_s3_bucket.logging.arn
    error_message = "logging_bucket_arn output should match bucket ARN"
  }
}

run "writer_role_arn_output_matches_role" {
  command = apply

  assert {
    condition     = output.log_writer_role_arn == aws_iam_role.log_writer.arn
    error_message = "log_writer_role_arn output should match role ARN"
  }
}

run "reader_role_arn_output_matches_role" {
  command = apply

  assert {
    condition     = output.log_reader_role_arn == aws_iam_role.log_reader.arn
    error_message = "log_reader_role_arn output should match role ARN"
  }
}
