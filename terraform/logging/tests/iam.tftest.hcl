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

run "log_writer_role_name" {
  command = apply

  assert {
    condition     = aws_iam_role.log_writer.name == "log-writer-test"
    error_message = "Log writer role name should be log-writer-test"
  }
}

run "log_reader_role_name" {
  command = apply

  assert {
    condition     = aws_iam_role.log_reader.name == "log-reader-test"
    error_message = "Log reader role name should be log-reader-test"
  }
}

run "log_writer_role_tags" {
  command = apply

  assert {
    condition     = aws_iam_role.log_writer.tags["Environment"] == "test"
    error_message = "Log writer role should have Environment tag"
  }

  assert {
    condition     = aws_iam_role.log_writer.tags["Name"] == "log-writer-test"
    error_message = "Log writer role should have Name tag"
  }
}

run "log_reader_role_tags" {
  command = apply

  assert {
    condition     = aws_iam_role.log_reader.tags["Environment"] == "test"
    error_message = "Log reader role should have Environment tag"
  }

  assert {
    condition     = aws_iam_role.log_reader.tags["Name"] == "log-reader-test"
    error_message = "Log reader role should have Name tag"
  }
}

run "log_writer_policy_name" {
  command = apply

  assert {
    condition     = aws_iam_policy.log_writer.name == "log-writer-policy-test"
    error_message = "Log writer policy name should be log-writer-policy-test"
  }
}

run "log_reader_policy_name" {
  command = apply

  assert {
    condition     = aws_iam_policy.log_reader.name == "log-reader-policy-test"
    error_message = "Log reader policy name should be log-reader-policy-test"
  }
}

run "role_names_with_prod_environment" {
  command = apply

  variables {
    environment = "prod"
  }

  assert {
    condition     = aws_iam_role.log_writer.name == "log-writer-prod"
    error_message = "Log writer role should use prod environment suffix"
  }

  assert {
    condition     = aws_iam_role.log_reader.name == "log-reader-prod"
    error_message = "Log reader role should use prod environment suffix"
  }

  assert {
    condition     = aws_iam_policy.log_writer.name == "log-writer-policy-prod"
    error_message = "Log writer policy should use prod environment suffix"
  }

  assert {
    condition     = aws_iam_policy.log_reader.name == "log-reader-policy-prod"
    error_message = "Log reader policy should use prod environment suffix"
  }
}

run "policy_attachments_exist" {
  command = apply

  assert {
    condition     = aws_iam_role_policy_attachment.log_writer.role == "log-writer-test"
    error_message = "Log writer policy attachment should reference log-writer role"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.log_reader.role == "log-reader-test"
    error_message = "Log reader policy attachment should reference log-reader role"
  }
}
