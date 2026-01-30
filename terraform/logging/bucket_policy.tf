resource "aws_s3_bucket_policy" "logging" {
  bucket = aws_s3_bucket.logging.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyNonSSLRequests"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.logging.arn,
          "${aws_s3_bucket.logging.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid    = "AllowLogWriterPutObject"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.log_writer.arn
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logging.arn}/*"
      },
      {
        Sid    = "AllowLogReaderAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.log_reader.arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.logging.arn}/*"
      },
      {
        Sid    = "AllowLogReaderListBucket"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.log_reader.arn
        }
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.logging.arn
      }
    ]
  })
}
