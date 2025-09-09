variable "realtime_chat__bucket_regional_domain_name" {
  description = "The regional domain name of the S3 bucket for the realtime chat application."
  type        = string
  
  
}

variable "environment" {
  description = "The environment for which the resources are being created (e.g., Dev, Prod)."
  type        = string
  default     = "Dev"
  
}

variable "domain_name" {
  description = "The domain name to be used as an alias for the CloudFront distribution."
  type        = string
  default     = "chat.baylenwebsite.xyz"
  
}

variable "chat_acm_arn" {
  description = "The arn of chat.baylenwebsite.xyz ACM certificate for CloudFront"
  type = string
}

variable "chat_domain_name" {
  description = "domain name for my chat application"
  type = string
}