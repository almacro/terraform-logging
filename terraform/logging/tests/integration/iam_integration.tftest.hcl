# IAM roles and policies integration tests
#
# Run with: ./bin/terraform test -test-directory=tests/integration

variables {
  test_trusted_arn = "arn:aws:iam::903616605317:user/test/terraform-test-runner"
  test_bucket_name = "tf-test-iam"
  test_environment = "intiam"
}

run "create_iam_resources" {
  command = apply

  variables {
    logging_bucket_name     = var.test_bucket_name
    environment             = var.test_environment
    log_writer_trusted_arns = [var.test_trusted_arn]
    log_reader_trusted_arns = [var.test_trusted_arn]
  }

  assert {
    condition     = aws_iam_role.log_writer.name == "log-writer-${var.test_environment}"
    error_message = "Log writer role name should match expected pattern"
  }

  assert {
    condition     = can(regex("^arn:aws:iam::", aws_iam_role.log_writer.arn))
    error_message = "Log writer role should have valid IAM ARN"
  }

  assert {
    condition     = aws_iam_role.log_reader.name == "log-reader-${var.test_environment}"
    error_message = "Log reader role name should match expected pattern"
  }

  assert {
    condition     = can(regex("^arn:aws:iam::", aws_iam_role.log_reader.arn))
    error_message = "Log reader role should have valid IAM ARN"
  }
}

run "verify_writer_policy" {
  command = apply

  variables {
    logging_bucket_name     = var.test_bucket_name
    environment             = var.test_environment
    log_writer_trusted_arns = [var.test_trusted_arn]
    log_reader_trusted_arns = [var.test_trusted_arn]
  }

  assert {
    condition     = aws_iam_policy.log_writer.name == "log-writer-policy-${var.test_environment}"
    error_message = "Log writer policy name should match expected pattern"
  }

  assert {
    condition     = can(regex("s3:PutObject", aws_iam_policy.log_writer.policy))
    error_message = "Log writer policy should allow s3:PutObject"
  }

  assert {
    condition     = !can(regex("s3:GetObject", aws_iam_policy.log_writer.policy))
    error_message = "Log writer policy should NOT allow s3:GetObject (least privilege)"
  }
}

run "verify_reader_policy" {
  command = apply

  variables {
    logging_bucket_name     = var.test_bucket_name
    environment             = var.test_environment
    log_writer_trusted_arns = [var.test_trusted_arn]
    log_reader_trusted_arns = [var.test_trusted_arn]
  }

  assert {
    condition     = aws_iam_policy.log_reader.name == "log-reader-policy-${var.test_environment}"
    error_message = "Log reader policy name should match expected pattern"
  }

  assert {
    condition     = can(regex("s3:GetObject", aws_iam_policy.log_reader.policy))
    error_message = "Log reader policy should allow s3:GetObject"
  }

  assert {
    condition     = can(regex("s3:PutObject", aws_iam_policy.log_reader.policy))
    error_message = "Log reader policy should allow s3:PutObject"
  }

  assert {
    condition     = can(regex("s3:ListBucket", aws_iam_policy.log_reader.policy))
    error_message = "Log reader policy should allow s3:ListBucket"
  }
}

run "verify_policy_attachments" {
  command = apply

  variables {
    logging_bucket_name     = var.test_bucket_name
    environment             = var.test_environment
    log_writer_trusted_arns = [var.test_trusted_arn]
    log_reader_trusted_arns = [var.test_trusted_arn]
  }

  assert {
    condition     = aws_iam_role_policy_attachment.log_writer.role == "log-writer-${var.test_environment}"
    error_message = "Log writer policy should be attached to log-writer role"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.log_reader.role == "log-reader-${var.test_environment}"
    error_message = "Log reader policy should be attached to log-reader role"
  }
}

run "verify_assume_role_policy" {
  command = apply

  variables {
    logging_bucket_name     = var.test_bucket_name
    environment             = var.test_environment
    log_writer_trusted_arns = [var.test_trusted_arn]
    log_reader_trusted_arns = [var.test_trusted_arn]
  }

  assert {
    condition     = can(regex("sts:AssumeRole", aws_iam_role.log_writer.assume_role_policy))
    error_message = "Log writer assume role policy should allow sts:AssumeRole"
  }

  assert {
    condition     = can(regex("sts:AssumeRole", aws_iam_role.log_reader.assume_role_policy))
    error_message = "Log reader assume role policy should allow sts:AssumeRole"
  }

  assert {
    condition     = can(regex(var.test_trusted_arn, aws_iam_role.log_writer.assume_role_policy))
    error_message = "Log writer trust policy should include trusted ARN"
  }

  assert {
    condition     = can(regex(var.test_trusted_arn, aws_iam_role.log_reader.assume_role_policy))
    error_message = "Log reader trust policy should include trusted ARN"
  }
}
