variable "region" {
  description = "The AWS region where the resources will be created."
  type        = string
  default     = "ap-southeast-1"
  
}

variable "chat_acm_arn" {
  description = "The ARN of the ACM certificate of chat.baylenwebsite.xyz for CloudFront."
  type        = string
  sensitive = true
  
}

variable "chat_domain_name" {
  description = "The domain name for the chat application."
  type        = string
  sensitive = true
  
}