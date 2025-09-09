data "aws_caller_identity" "current" {}

# Generate a random identifier to ensure uniqueness.
resource "random_id" "bucket_suffix" {
  byte_length = 4
  
}

resource "aws_s3_bucket" "realtime_chat_bucket" {
  bucket = "${var.realtime_chat_bucket_name}-${data.aws_caller_identity.current.account_id}-${random_id.bucket_suffix.hex}"
    tags = {
    Name        = var.realtime_chat_bucket_name
    Environment = "Dev"
  }
  
}