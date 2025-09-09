output "realtime_chat_distribution_arn" {
  description = "The ARN of the CloudFront distribution for the realtime chat application."
  value       = aws_cloudfront_distribution.realtime_chat_distribution.arn
  
}