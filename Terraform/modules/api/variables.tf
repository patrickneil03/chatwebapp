variable "connect_handler_invoke_arn" {
  description = "Invoke ARN of the Lambda Connect handler"
  type        = string
  
}

variable "disconnect_handler_invoke_arn" {
  description = "Invoke ARN of the Lambda Disconnect handler"
  type        = string
  
}

variable "sendmessage_handler_invoke_arn" {
  description = "Invoke ARN of the Lambda SendMessage handler"
  type        = string
  
}

variable "ReturnMessageHandler_name" {
  description = "Name of the Lambda ReturnMessage handler"
  type        = string
  
}

variable "region" {
  description = "AWS region"
  type        = string
  default = "ap-southeast-1"
  
}

variable "ReturnMessageHandler_invoke_arn" {
  description = "Invoke ARN of the Lambda ReturnMessage handler"
  type        = string
  
}