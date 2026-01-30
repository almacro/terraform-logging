# --- Log Writer Role (Fluentbit) ---

data "aws_iam_policy_document" "log_writer_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.log_writer_trusted_arns
    }
  }
}

resource "aws_iam_role" "log_writer" {
  name               = "log-writer-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.log_writer_assume_role.json

  tags = {
    Name        = "log-writer-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_iam_policy" "log_writer" {
  name        = "log-writer-policy-${var.environment}"
  description = "Allows writing log objects to the logging bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowPutObject"
        Effect   = "Allow"
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logging.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "log_writer" {
  role       = aws_iam_role.log_writer.name
  policy_arn = aws_iam_policy.log_writer.arn
}

# --- Log Reader/Updater Role (ELK) ---

data "aws_iam_policy_document" "log_reader_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.log_reader_trusted_arns
    }
  }
}

resource "aws_iam_role" "log_reader" {
  name               = "log-reader-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.log_reader_assume_role.json

  tags = {
    Name        = "log-reader-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_iam_policy" "log_reader" {
  name        = "log-reader-policy-${var.environment}"
  description = "Allows reading, updating, and listing log objects in the logging bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowGetAndPutObject"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.logging.arn}/*"
      },
      {
        Sid      = "AllowListBucket"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.logging.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "log_reader" {
  role       = aws_iam_role.log_reader.name
  policy_arn = aws_iam_policy.log_reader.arn
}
