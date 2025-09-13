variable "lambda_con_dis_role_arn" {
  description = "ARN of the Lambda Connect/Disconnect role"
  type        = string
  
}

variable "lambda_sendmessage_role_arn" {
  description = "ARN of the Lambda SendMessage role"
  type        = string
  
}

variable "aws_dynamodb_table_name" {
  description = "name of the DynamoDB table for connections"
}

variable "websocket_api_execution_arn" {
  description = "ARN of the WebSocket API execution"
  type        = string
  
}

variable "dynamodb_messages_table_name" {
  description = "Name of the DynamoDB table for messages"
}

variable "return_message_role_arn" {
  description = "ARN of the Lambda ReturnMessage role"
  type        = string
  
}

variable "chat_rest_api_execution_arn" {
  description = "ARN of the REST API execution"
  type        = string
  
}

variable "region" {
  description = "AWS region"
  type        = string
  default = "ap-southeast-1"
  
}

variable "WEBSOCKET_API_URL" {
  description = "The WebSocket API URL for the chat application."
  type        = string
  
}

variable "REST_API_BASE_URL" {
  description = "The REST API Base URL for the chat application."
  type        = string
  
}
