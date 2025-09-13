terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
  
}

provider "aws" {
  region = var.region
}

module "s3" {
  source = "./modules/s3"
  realtime_chat_distribution_arn = module.cloudfront.realtime_chat_distribution_arn
  
}

module "cloudfront" {
  source = "./modules/cloudfront"
  realtime_chat__bucket_regional_domain_name = module.s3.realtime_chat__bucket_regional_domain_name
  chat_acm_arn = var.chat_acm_arn
  chat_domain_name = var.chat_domain_name
}

module "api" {
  source = "./modules/api"
  connect_handler_invoke_arn = module.lambda.connect_handler_invoke_arn
  disconnect_handler_invoke_arn = module.lambda.disconnect_handler_invoke_arn
  sendmessage_handler_invoke_arn = module.lambda.sendmessage_handler_invoke_arn
  ReturnMessageHandler_name = module.lambda.ReturnMessageHandler_name
  ReturnMessageHandler_invoke_arn = module.lambda.ReturnMessageHandler_invoke_arn
}

module "lambda" {
  source = "./modules/lambda"
  lambda_con_dis_role_arn = module.iam.lambda_con_dis_role_arn
  lambda_sendmessage_role_arn = module.iam.lambda_sendmessage_role_arn
  aws_dynamodb_table_name = module.dynamodb.aws_dynamodb_table_name
  websocket_api_execution_arn = module.api.websocket_api_execution_arn
  dynamodb_messages_table_name = module.dynamodb.dynamodb_messages_table_name
  return_message_role_arn = module.iam.return_message_role_arn
  chat_rest_api_execution_arn = module.api.chat_rest_api_execution_arn
  WEBSOCKET_API_URL = var.WEBSOCKET_API_URL
  REST_API_BASE_URL = var.REST_API_BASE_URL
}

module "iam" {
  source = "./modules/iam"
  connections_table_arn = module.dynamodb.connections_table_arn
  messages_table_arn = module.dynamodb.messages_table_arn
  
}

module "dynamodb" {
  source = "./modules/dynamodb"
  
}
