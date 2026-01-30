# Integration tests for logging infrastructure
#
# These tests use placeholder ARNs by default. To test with your actual
# AWS identity (enabling real assume-role testing), run:
#
#   CALLER_ARN=$(aws sts get-caller-identity --query Arn --output text)
#   ./bin/terraform test -test-directory=tests/integration \
#     -var="test_trusted_arn=$CALLER_ARN"

variables {
  # Uses actual test account - override with -var for different identity
  test_trusted_arn = "arn:aws:iam::903616605317:user/test/terraform-test-runner"
  test_bucket_name = "tf-test-di"
  test_environment = "intdi"
}

run "deploy_infrastructure" {
  command = apply

  variables {
    logging_bucket_name     = var.test_bucket_name
    environment             = var.test_environment
    log_writer_trusted_arns = [var.test_trusted_arn]
    log_reader_trusted_arns = [var.test_trusted_arn]
  }

  assert {
    condition     = aws_s3_bucket.logging.id == "${var.test_bucket_name}-${var.test_environment}"
    error_message = "Bucket should be created with correct name"
  }

  assert {
    condition     = aws_iam_role.log_writer.name == "log-writer-${var.test_environment}"
    error_message = "Log writer role should be created"
  }

  assert {
    condition     = aws_iam_role.log_reader.name == "log-reader-${var.test_environment}"
    error_message = "Log reader role should be created"
  }
}

run "verify_trust_policy_contains_principal" {
  command = apply

  variables {
    logging_bucket_name     = var.test_bucket_name
    environment             = var.test_environment
    log_writer_trusted_arns = [var.test_trusted_arn]
    log_reader_trusted_arns = [var.test_trusted_arn]
  }

  assert {
    condition     = can(regex(var.test_trusted_arn, aws_iam_role.log_writer.assume_role_policy))
    error_message = "Log writer trust policy should include the trusted ARN"
  }

  assert {
    condition     = can(regex(var.test_trusted_arn, aws_iam_role.log_reader.assume_role_policy))
    error_message = "Log reader trust policy should include the trusted ARN"
  }
}

run "verify_security_hardening" {
  command = apply

  variables {
    logging_bucket_name     = var.test_bucket_name
    environment             = var.test_environment
    log_writer_trusted_arns = [var.test_trusted_arn]
    log_reader_trusted_arns = [var.test_trusted_arn]
  }

  # Versioning
  assert {
    condition     = aws_s3_bucket_versioning.logging.versioning_configuration[0].status == "Enabled"
    error_message = "Versioning should be enabled"
  }

  # Encryption
  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.logging.rule[*].apply_server_side_encryption_by_default[0].sse_algorithm) == "AES256"
    error_message = "Encryption should use AES256"
  }

  # Public access block
  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.logging.block_public_acls,
      aws_s3_bucket_public_access_block.logging.block_public_policy,
      aws_s3_bucket_public_access_block.logging.ignore_public_acls,
      aws_s3_bucket_public_access_block.logging.restrict_public_buckets
    ])
    error_message = "All public access should be blocked"
  }

  # SSL enforcement in bucket policy
  assert {
    condition     = can(regex("aws:SecureTransport", aws_s3_bucket_policy.logging.policy))
    error_message = "Bucket policy should enforce SSL"
  }
}

run "verify_least_privilege" {
  command = apply

  variables {
    logging_bucket_name     = var.test_bucket_name
    environment             = var.test_environment
    log_writer_trusted_arns = [var.test_trusted_arn]
    log_reader_trusted_arns = [var.test_trusted_arn]
  }

  # Writer can only write
  assert {
    condition     = can(regex("s3:PutObject", aws_iam_policy.log_writer.policy))
    error_message = "Log writer should have PutObject permission"
  }

  assert {
    condition     = !can(regex("s3:GetObject", aws_iam_policy.log_writer.policy))
    error_message = "Log writer should NOT have GetObject permission (least privilege)"
  }

  # Reader has read, write, list
  assert {
    condition = alltrue([
      can(regex("s3:GetObject", aws_iam_policy.log_reader.policy)),
      can(regex("s3:PutObject", aws_iam_policy.log_reader.policy)),
      can(regex("s3:ListBucket", aws_iam_policy.log_reader.policy))
    ])
    error_message = "Log reader should have GetObject, PutObject, and ListBucket permissions"
  }
}

run "verify_outputs" {
  command = apply

  variables {
    logging_bucket_name     = var.test_bucket_name
    environment             = var.test_environment
    log_writer_trusted_arns = [var.test_trusted_arn]
    log_reader_trusted_arns = [var.test_trusted_arn]
  }

  assert {
    condition     = output.logging_bucket_name == "${var.test_bucket_name}-${var.test_environment}"
    error_message = "Bucket name output should match"
  }

  assert {
    condition     = can(regex("^arn:aws:s3:::", output.logging_bucket_arn))
    error_message = "Bucket ARN output should be valid S3 ARN"
  }

  assert {
    condition     = can(regex("^arn:aws:iam::\\d+:role/log-writer-", output.log_writer_role_arn))
    error_message = "Log writer role ARN output should be valid IAM ARN"
  }

  assert {
    condition     = can(regex("^arn:aws:iam::\\d+:role/log-reader-", output.log_reader_role_arn))
    error_message = "Log reader role ARN output should be valid IAM ARN"
  }
}
