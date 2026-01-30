# Outputs integration tests
#
# Run with: ./bin/terraform test -test-directory=tests/integration

variables {
  test_trusted_arn = "arn:aws:iam::903616605317:user/test/terraform-test-runner"
  test_bucket_name = "tf-test-out"
  test_environment = "intout"
}

run "verify_bucket_outputs" {
  command = apply

  variables {
    logging_bucket_name     = var.test_bucket_name
    environment             = var.test_environment
    log_writer_trusted_arns = [var.test_trusted_arn]
    log_reader_trusted_arns = [var.test_trusted_arn]
  }

  assert {
    condition     = can(regex("^arn:aws:s3:::${var.test_bucket_name}-${var.test_environment}$", output.logging_bucket_arn))
    error_message = "logging_bucket_arn should be valid S3 ARN"
  }

  assert {
    condition     = output.logging_bucket_name == "${var.test_bucket_name}-${var.test_environment}"
    error_message = "logging_bucket_name should match expected value"
  }

  assert {
    condition     = output.logging_bucket_arn == aws_s3_bucket.logging.arn
    error_message = "logging_bucket_arn output should match bucket resource ARN"
  }

  assert {
    condition     = output.logging_bucket_name == aws_s3_bucket.logging.id
    error_message = "logging_bucket_name output should match bucket resource ID"
  }
}

run "verify_role_outputs" {
  command = apply

  variables {
    logging_bucket_name     = var.test_bucket_name
    environment             = var.test_environment
    log_writer_trusted_arns = [var.test_trusted_arn]
    log_reader_trusted_arns = [var.test_trusted_arn]
  }

  assert {
    condition     = can(regex("^arn:aws:iam::\\d+:role/log-writer-${var.test_environment}$", output.log_writer_role_arn))
    error_message = "log_writer_role_arn should be valid IAM role ARN"
  }

  assert {
    condition     = can(regex("^arn:aws:iam::\\d+:role/log-reader-${var.test_environment}$", output.log_reader_role_arn))
    error_message = "log_reader_role_arn should be valid IAM role ARN"
  }

  assert {
    condition     = output.log_writer_role_arn == aws_iam_role.log_writer.arn
    error_message = "log_writer_role_arn output should match role resource ARN"
  }

  assert {
    condition     = output.log_reader_role_arn == aws_iam_role.log_reader.arn
    error_message = "log_reader_role_arn output should match role resource ARN"
  }
}

run "outputs_not_empty" {
  command = apply

  variables {
    logging_bucket_name     = var.test_bucket_name
    environment             = var.test_environment
    log_writer_trusted_arns = [var.test_trusted_arn]
    log_reader_trusted_arns = [var.test_trusted_arn]
  }

  assert {
    condition     = length(output.logging_bucket_arn) > 0
    error_message = "logging_bucket_arn should not be empty"
  }

  assert {
    condition     = length(output.logging_bucket_name) > 0
    error_message = "logging_bucket_name should not be empty"
  }

  assert {
    condition     = length(output.log_writer_role_arn) > 0
    error_message = "log_writer_role_arn should not be empty"
  }

  assert {
    condition     = length(output.log_reader_role_arn) > 0
    error_message = "log_reader_role_arn should not be empty"
  }
}
