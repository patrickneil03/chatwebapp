resource "aws_s3_bucket_policy" "static_website_policy" {
  bucket = aws_s3_bucket.realtime_chat_bucket.id
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowCloudFrontViaOAC",
        Effect    = "Allow",
        Principal = {
          Service = "cloudfront.amazonaws.com"
        },
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.realtime_chat_bucket.arn}/*",
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = var.realtime_chat_distribution_arn
          }
        }
      }
    ]
  })
}