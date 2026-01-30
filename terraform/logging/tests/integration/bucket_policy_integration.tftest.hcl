# Bucket policy integration tests
#
# Run with: ./bin/terraform test -test-directory=tests/integration

variables {
  test_trusted_arn = "arn:aws:iam::903616605317:user/test/terraform-test-runner"
  test_bucket_name = "tf-test-bp"
  test_environment = "intbp"
}

run "create_bucket_policy" {
  command = apply

  variables {
    logging_bucket_name     = var.test_bucket_name
    environment             = var.test_environment
    log_writer_trusted_arns = [var.test_trusted_arn]
    log_reader_trusted_arns = [var.test_trusted_arn]
  }

  assert {
    condition     = aws_s3_bucket_policy.logging.bucket == aws_s3_bucket.logging.id
    error_message = "Bucket policy should be attached to correct bucket"
  }
}

run "verify_ssl_enforcement" {
  command = apply

  variables {
    logging_bucket_name     = var.test_bucket_name
    environment             = var.test_environment
    log_writer_trusted_arns = [var.test_trusted_arn]
    log_reader_trusted_arns = [var.test_trusted_arn]
  }

  assert {
    condition     = can(regex("DenyNonSSLRequests", aws_s3_bucket_policy.logging.policy))
    error_message = "Bucket policy should have SSL enforcement statement"
  }

  assert {
    condition     = can(regex("aws:SecureTransport", aws_s3_bucket_policy.logging.policy))
    error_message = "Bucket policy should check SecureTransport condition"
  }

  assert {
    condition     = can(regex("\"Effect\"\\s*:\\s*\"Deny\"", aws_s3_bucket_policy.logging.policy))
    error_message = "Bucket policy should have Deny effect for non-SSL requests"
  }
}

run "verify_writer_access" {
  command = apply

  variables {
    logging_bucket_name     = var.test_bucket_name
    environment             = var.test_environment
    log_writer_trusted_arns = [var.test_trusted_arn]
    log_reader_trusted_arns = [var.test_trusted_arn]
  }

  assert {
    condition     = can(regex("AllowLogWriterPutObject", aws_s3_bucket_policy.logging.policy))
    error_message = "Bucket policy should grant log writer PutObject access"
  }

  assert {
    condition     = can(regex(aws_iam_role.log_writer.arn, aws_s3_bucket_policy.logging.policy))
    error_message = "Bucket policy should reference log writer role ARN"
  }
}

run "verify_reader_access" {
  command = apply

  variables {
    logging_bucket_name     = var.test_bucket_name
    environment             = var.test_environment
    log_writer_trusted_arns = [var.test_trusted_arn]
    log_reader_trusted_arns = [var.test_trusted_arn]
  }

  assert {
    condition     = can(regex("AllowLogReaderAccess", aws_s3_bucket_policy.logging.policy))
    error_message = "Bucket policy should grant log reader access"
  }

  assert {
    condition     = can(regex("AllowLogReaderListBucket", aws_s3_bucket_policy.logging.policy))
    error_message = "Bucket policy should grant log reader ListBucket access"
  }

  assert {
    condition     = can(regex(aws_iam_role.log_reader.arn, aws_s3_bucket_policy.logging.policy))
    error_message = "Bucket policy should reference log reader role ARN"
  }
}

run "verify_policy_actions" {
  command = apply

  variables {
    logging_bucket_name     = var.test_bucket_name
    environment             = var.test_environment
    log_writer_trusted_arns = [var.test_trusted_arn]
    log_reader_trusted_arns = [var.test_trusted_arn]
  }

  assert {
    condition     = can(regex("s3:PutObject", aws_s3_bucket_policy.logging.policy))
    error_message = "Bucket policy should allow s3:PutObject"
  }

  assert {
    condition     = can(regex("s3:GetObject", aws_s3_bucket_policy.logging.policy))
    error_message = "Bucket policy should allow s3:GetObject"
  }

  assert {
    condition     = can(regex("s3:ListBucket", aws_s3_bucket_policy.logging.policy))
    error_message = "Bucket policy should allow s3:ListBucket"
  }

  assert {
    condition     = can(regex("s3:\\*", aws_s3_bucket_policy.logging.policy))
    error_message = "SSL enforcement should apply to all S3 actions"
  }
}
