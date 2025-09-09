data "aws_caller_identity" "current" {}


resource "aws_api_gateway_rest_api" "chat_rest_api" {
  name        = "chat_rest_api"
  description = "API that enables to load the previous messages from DynamoDB"
}


resource "aws_api_gateway_stage" "prod" {
  rest_api_id    = aws_api_gateway_rest_api.chat_rest_api.id
  deployment_id  = aws_api_gateway_deployment.chat_rest_api_deployment.id
  stage_name     = "prod"
}

resource "aws_api_gateway_deployment" "chat_rest_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.chat_rest_api.id

  triggers = {
    redeployment = timestamp()
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.chat_rest_api_lambda_integration,
    aws_api_gateway_integration.options_integration,
  ]
}


#############################################
# 6. API Throtlling
#############################################
resource "aws_api_gateway_method_settings" "api_throttling" {
  rest_api_id = aws_api_gateway_rest_api.chat_rest_api.id
  stage_name  = aws_api_gateway_stage.prod.stage_name
  method_path = "*/*"

  settings {
    throttling_burst_limit = 5
    throttling_rate_limit  = 10
    metrics_enabled        = true
    logging_level          = "OFF"
    data_trace_enabled     = false
  }
  
}


#allow apigw to invoke lambda functions
resource "aws_lambda_permission" "allow_apigw_invoke_returnmessagehandler" {
  statement_id  = "AllowAPIGatewayInvokeReturnMessageHandler"
  action        = "lambda:InvokeFunction"
  function_name = var.ReturnMessageHandler_name
  principal     = "apigateway.amazonaws.com"
  # The source ARN includes the API deployment stage and supports all methods
  source_arn = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.chat_rest_api.id}/*/*"
}