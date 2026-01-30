# S3 bucket integration tests
#
# Run with: ./bin/terraform test -test-directory=tests/integration

variables {
  test_trusted_arn = "arn:aws:iam::903616605317:user/test/terraform-test-runner"
  test_bucket_name = "tf-test-s3"
  test_environment = "ints3"
}

run "create_bucket" {
  command = apply

  variables {
    logging_bucket_name     = var.test_bucket_name
    environment             = var.test_environment
    log_writer_trusted_arns = [var.test_trusted_arn]
    log_reader_trusted_arns = [var.test_trusted_arn]
  }

  assert {
    condition     = aws_s3_bucket.logging.bucket == "${var.test_bucket_name}-${var.test_environment}"
    error_message = "Bucket name should match expected value"
  }

  assert {
    condition     = aws_s3_bucket.logging.arn != ""
    error_message = "Bucket ARN should be set"
  }
}

run "verify_versioning" {
  command = apply

  variables {
    logging_bucket_name     = var.test_bucket_name
    environment             = var.test_environment
    log_writer_trusted_arns = [var.test_trusted_arn]
    log_reader_trusted_arns = [var.test_trusted_arn]
  }

  assert {
    condition     = aws_s3_bucket_versioning.logging.versioning_configuration[0].status == "Enabled"
    error_message = "Bucket versioning should be enabled"
  }
}

run "verify_encryption" {
  command = apply

  variables {
    logging_bucket_name     = var.test_bucket_name
    environment             = var.test_environment
    log_writer_trusted_arns = [var.test_trusted_arn]
    log_reader_trusted_arns = [var.test_trusted_arn]
  }

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.logging.rule[*].apply_server_side_encryption_by_default[0].sse_algorithm) == "AES256"
    error_message = "Bucket encryption should use AES256"
  }
}

run "verify_public_access_block" {
  command = apply

  variables {
    logging_bucket_name     = var.test_bucket_name
    environment             = var.test_environment
    log_writer_trusted_arns = [var.test_trusted_arn]
    log_reader_trusted_arns = [var.test_trusted_arn]
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.logging.block_public_acls == true
    error_message = "block_public_acls should be enabled"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.logging.block_public_policy == true
    error_message = "block_public_policy should be enabled"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.logging.ignore_public_acls == true
    error_message = "ignore_public_acls should be enabled"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.logging.restrict_public_buckets == true
    error_message = "restrict_public_buckets should be enabled"
  }
}

run "verify_tags" {
  command = apply

  variables {
    logging_bucket_name     = var.test_bucket_name
    environment             = var.test_environment
    log_writer_trusted_arns = [var.test_trusted_arn]
    log_reader_trusted_arns = [var.test_trusted_arn]
  }

  assert {
    condition     = aws_s3_bucket.logging.tags["Environment"] == var.test_environment
    error_message = "Bucket should have correct Environment tag"
  }

  assert {
    condition     = aws_s3_bucket.logging.tags["Name"] == "${var.test_bucket_name}-${var.test_environment}"
    error_message = "Bucket should have correct Name tag"
  }
}
