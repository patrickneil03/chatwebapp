resource "aws_lambda_function" "ConnectHandler" {
  filename         = "${path.module}/lambda-function/connect-to-chat.zip"
  function_name    = "ConnectHandler"
  role             = var.lambda_con_dis_role_arn
  handler          = "connect-to-chat.lambda_handler"  
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("${path.module}/lambda-function/connect-to-chat.zip")
  description = "(PROJECT 2) Handles new WebSocket connections and stores connection IDs in DynamoDB"

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = var.aws_dynamodb_table_name
      DYNAMODB_MESSAGES_TABLE_NAME = var.dynamodb_messages_table_name
      REST_API_BASE_URL = var.REST_API_BASE_URL
      WEBSOCKET_API_URL = var.WEBSOCKET_API_URL
      
    }
  }
}

resource "aws_lambda_function" "DisconnectHandler" {
  filename         = "${path.module}/lambda-function/disconnect-to-chat.zip"
  function_name    = "DisconnectHandler"
  role             = var.lambda_con_dis_role_arn
  handler          = "disconnect-to-chat.lambda_handler"  
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("${path.module}/lambda-function/disconnect-to-chat.zip")
  description = "(PROJECT 2) Handles WebSocket disconnections and removes connection IDs from DynamoDB"

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = var.aws_dynamodb_table_name
    }
  }
}

resource "aws_lambda_function" "SendMessageHandler" {
  filename         = "${path.module}/lambda-function/send-message.zip"
  function_name    = "SendMessageHandler"
  role             = var.lambda_sendmessage_role_arn
  handler          = "send-message.lambda_handler"  
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("${path.module}/lambda-function/send-message.zip")
  description = "(PROJECT 2) Handles incoming messages and broadcasts them to all connected clients"

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = var.aws_dynamodb_table_name
      DYNAMODB_MESSAGES_TABLE_NAME = var.dynamodb_messages_table_name
      WEBSOCKET_API_URL = var.WEBSOCKET_API_URL
      
    }
  }
}

resource "aws_lambda_function" "ReturnMessageHandler" {
  filename         = "${path.module}/lambda-function/return-messages.zip"
  function_name    = "ReturnMessageHandler"
  role             = var.return_message_role_arn
  handler          = "return-messages.lambda_handler"  
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("${path.module}/lambda-function/return-messages.zip")
  description = "(PROJECT 2) Handles incoming messages and broadcasts them to all connected clients"

  environment {
    variables = {
      
      DYNAMODB_MESSAGES_TABLE_NAME = var.dynamodb_messages_table_name
      REST_API_BASE_URL = var.REST_API_BASE_URL
      
    }
  }
}

resource "aws_lambda_permission" "apigw_connect" {
  statement_id  = "AllowExecutionFromAPIGatewayConnect"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ConnectHandler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.websocket_api_execution_arn}/*/$connect"
}

resource "aws_lambda_permission" "apigw_disconnect" {
  statement_id  = "AllowExecutionFromAPIGatewayDisconnect"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.DisconnectHandler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.websocket_api_execution_arn}/*/$disconnect"
}

resource "aws_lambda_permission" "apigw_sendmessage" {
  statement_id  = "AllowExecutionFromAPIGatewaySendMessage"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.SendMessageHandler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.websocket_api_execution_arn}/*/$default"
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ReturnMessageHandler.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${var.chat_rest_api_execution_arn}/*/*/*"
}