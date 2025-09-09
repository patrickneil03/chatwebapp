resource "aws_s3_bucket_public_access_block" "static_website" {
  bucket = aws_s3_bucket.realtime_chat_bucket.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_website_configuration" "static_website_config" {
  bucket = aws_s3_bucket.realtime_chat_bucket.id
  
  index_document {
    suffix = "index.html"
  }
  
}

# Add ownership controls to allow public access
resource "aws_s3_bucket_ownership_controls" "static_website_ownership" {
  bucket = aws_s3_bucket.realtime_chat_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Set bucket ACL to public-read
resource "aws_s3_bucket_acl" "static_website_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.static_website_ownership,
    aws_s3_bucket_public_access_block.static_website,
  ]

  bucket = aws_s3_bucket.realtime_chat_bucket.id
  acl    = "private"
}