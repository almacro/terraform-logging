# End-to-end integration tests
# Creates full infrastructure and verifies all components work together
#
# Run with: ./bin/terraform test -test-directory=tests/integration

variables {
  test_trusted_arn = "arn:aws:iam::903616605317:user/test/terraform-test-runner"
  test_bucket_name = "tf-test-e2e"
  test_environment = "inte2e"
}

run "deploy_complete_infrastructure" {
  command = apply

  variables {
    logging_bucket_name     = var.test_bucket_name
    environment             = var.test_environment
    log_writer_trusted_arns = [var.test_trusted_arn]
    log_reader_trusted_arns = [var.test_trusted_arn]
  }

  # S3 bucket created
  assert {
    condition     = aws_s3_bucket.logging.id == "${var.test_bucket_name}-${var.test_environment}"
    error_message = "S3 bucket should be created with correct name"
  }

  # Both IAM roles created
  assert {
    condition     = aws_iam_role.log_writer.id != "" && aws_iam_role.log_reader.id != ""
    error_message = "Both IAM roles should be created"
  }

  # Both IAM policies created
  assert {
    condition     = aws_iam_policy.log_writer.id != "" && aws_iam_policy.log_reader.id != ""
    error_message = "Both IAM policies should be created"
  }

  # Bucket policy created
  assert {
    condition     = aws_s3_bucket_policy.logging.id != ""
    error_message = "Bucket policy should be created"
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

  # Versioning enabled
  assert {
    condition     = aws_s3_bucket_versioning.logging.versioning_configuration[0].status == "Enabled"
    error_message = "Bucket versioning must be enabled for compliance"
  }

  # Encryption enabled
  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.logging.rule[*].apply_server_side_encryption_by_default[0].sse_algorithm) == "AES256"
    error_message = "Bucket encryption must use AES256"
  }

  # All public access blocked
  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.logging.block_public_acls,
      aws_s3_bucket_public_access_block.logging.block_public_policy,
      aws_s3_bucket_public_access_block.logging.ignore_public_acls,
      aws_s3_bucket_public_access_block.logging.restrict_public_buckets
    ])
    error_message = "All public access must be blocked"
  }

  # SSL enforcement in bucket policy
  assert {
    condition     = can(regex("aws:SecureTransport.*false", aws_s3_bucket_policy.logging.policy))
    error_message = "Bucket policy must enforce SSL/TLS"
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
    condition     = can(regex("s3:PutObject", aws_iam_policy.log_writer.policy)) && !can(regex("s3:GetObject", aws_iam_policy.log_writer.policy))
    error_message = "Log writer should only have PutObject permission (least privilege)"
  }

  # Reader has read, write, and list
  assert {
    condition = alltrue([
      can(regex("s3:GetObject", aws_iam_policy.log_reader.policy)),
      can(regex("s3:PutObject", aws_iam_policy.log_reader.policy)),
      can(regex("s3:ListBucket", aws_iam_policy.log_reader.policy))
    ])
    error_message = "Log reader should have GetObject, PutObject, and ListBucket permissions"
  }
}

run "verify_resource_relationships" {
  command = apply

  variables {
    logging_bucket_name     = var.test_bucket_name
    environment             = var.test_environment
    log_writer_trusted_arns = [var.test_trusted_arn]
    log_reader_trusted_arns = [var.test_trusted_arn]
  }

  # Bucket versioning references correct bucket
  assert {
    condition     = aws_s3_bucket_versioning.logging.bucket == aws_s3_bucket.logging.id
    error_message = "Versioning should reference logging bucket"
  }

  # Encryption references correct bucket
  assert {
    condition     = aws_s3_bucket_server_side_encryption_configuration.logging.bucket == aws_s3_bucket.logging.id
    error_message = "Encryption config should reference logging bucket"
  }

  # Public access block references correct bucket
  assert {
    condition     = aws_s3_bucket_public_access_block.logging.bucket == aws_s3_bucket.logging.id
    error_message = "Public access block should reference logging bucket"
  }

  # Bucket policy references correct bucket
  assert {
    condition     = aws_s3_bucket_policy.logging.bucket == aws_s3_bucket.logging.id
    error_message = "Bucket policy should reference logging bucket"
  }

  # Policy attachments reference correct roles
  assert {
    condition     = aws_iam_role_policy_attachment.log_writer.role == aws_iam_role.log_writer.name
    error_message = "Writer policy attachment should reference writer role"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.log_reader.role == aws_iam_role.log_reader.name
    error_message = "Reader policy attachment should reference reader role"
  }
}

run "verify_naming_conventions" {
  command = apply

  variables {
    logging_bucket_name     = var.test_bucket_name
    environment             = var.test_environment
    log_writer_trusted_arns = [var.test_trusted_arn]
    log_reader_trusted_arns = [var.test_trusted_arn]
  }

  # All resources follow naming convention with environment suffix
  assert {
    condition     = can(regex("-${var.test_environment}$", aws_s3_bucket.logging.bucket))
    error_message = "Bucket name should end with environment suffix"
  }

  assert {
    condition     = can(regex("-${var.test_environment}$", aws_iam_role.log_writer.name))
    error_message = "Log writer role should end with environment suffix"
  }

  assert {
    condition     = can(regex("-${var.test_environment}$", aws_iam_role.log_reader.name))
    error_message = "Log reader role should end with environment suffix"
  }

  assert {
    condition     = can(regex("-${var.test_environment}$", aws_iam_policy.log_writer.name))
    error_message = "Log writer policy should end with environment suffix"
  }

  assert {
    condition     = can(regex("-${var.test_environment}$", aws_iam_policy.log_reader.name))
    error_message = "Log reader policy should end with environment suffix"
  }
}
