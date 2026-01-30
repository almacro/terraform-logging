# environment
variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

# bucket_name
variable "logging_bucket_name" {
  description = "Name of the logging bucket"
  type = string
  default = "apps-logs"
}

variable "aws_region" {
  description = "AWS region for resources"
  type    = string
  default = "us-west-1"

  validation {
    condition     = contains(["us-west-1", "us-west-2", "us-east-1", "us-east-2"], var.aws_region)
    error_message = "Region must be one of: us-west-1, us-west-2, us-east-1, us-east-2."
  }
}

variable "log_writer_trusted_arns" {
  description = "List of ARNs allowed to assume the log writer role"
  type        = list(string)
}

variable "log_reader_trusted_arns" {
  description = "List of ARNs allowed to assume the log reader/updater role"
  type        = list(string)
}
