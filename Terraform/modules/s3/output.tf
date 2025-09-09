output "realtime_chat__bucket_regional_domain_name" {
  description = "The regional domain name of the S3 bucket for the realtime chat application."
  value       = aws_s3_bucket.realtime_chat_bucket.bucket_regional_domain_name
  
}