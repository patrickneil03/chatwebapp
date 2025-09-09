variable "region" {
  description = "The AWS region where the resources will be created."
  type        = string
  default     = "ap-southeast-1"
  
}

variable "realtime_chat_bucket_name" {
  description = "The name of the S3 bucket for the realtime chat application."
  type        = string
  default = "realtime-chat-bucket"
  
}

variable "realtime_chat_distribution_arn" {
  description = "The ARN of the CloudFront distribution for the realtime chat application."
  type        = string
  
}