output "logging_bucket_arn" {
  description = "ARN of the logging S3 bucket"
  value       = aws_s3_bucket.logging.arn
}

output "logging_bucket_name" {
  description = "Name of the logging S3 bucket"
  value       = aws_s3_bucket.logging.id
}

output "log_writer_role_arn" {
  description = "ARN of the log writer IAM role"
  value       = aws_iam_role.log_writer.arn
}

output "log_reader_role_arn" {
  description = "ARN of the log reader/updater IAM role"
  value       = aws_iam_role.log_reader.arn
}
