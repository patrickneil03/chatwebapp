resource "aws_api_gateway_resource" "messages_resource" {
  rest_api_id = aws_api_gateway_rest_api.chat_rest_api.id
  parent_id   = aws_api_gateway_rest_api.chat_rest_api.root_resource_id
  path_part   = "messages"
}

resource "aws_api_gateway_resource" "room_resource" {
  rest_api_id = aws_api_gateway_rest_api.chat_rest_api.id
  parent_id   = aws_api_gateway_resource.messages_resource.id
  path_part   = "{roomId}"
}


# API Gateway Method
resource "aws_api_gateway_method" "get_messages" {
  rest_api_id   = aws_api_gateway_rest_api.chat_rest_api.id
  resource_id   = aws_api_gateway_resource.room_resource.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.roomId" = true
  }
}

resource "aws_api_gateway_integration" "chat_rest_api_lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.chat_rest_api.id
  resource_id = aws_api_gateway_resource.room_resource.id
  http_method = aws_api_gateway_method.get_messages.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.ReturnMessageHandler_invoke_arn

  request_parameters = {
    "integration.request.path.roomId" = "method.request.path.roomId"
  }
}

resource "aws_api_gateway_method_response" "get_messages_response_200" {
  rest_api_id = aws_api_gateway_rest_api.chat_rest_api.id
  resource_id = aws_api_gateway_resource.room_resource.id
  http_method = aws_api_gateway_method.get_messages.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

resource "aws_api_gateway_integration_response" "get_messages_integration_response_200" {
  rest_api_id = aws_api_gateway_rest_api.chat_rest_api.id
  resource_id = aws_api_gateway_resource.room_resource.id
  http_method = aws_api_gateway_method.get_messages.http_method
  status_code = aws_api_gateway_method_response.get_messages_response_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Headers" = "'Authorization,Content-Type'"
  }
}


# OPTIONS method for CORS
resource "aws_api_gateway_method" "options_method" {
  rest_api_id   = aws_api_gateway_rest_api.chat_rest_api.id
  resource_id   = aws_api_gateway_resource.room_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = aws_api_gateway_rest_api.chat_rest_api.id
  resource_id = aws_api_gateway_resource.room_resource.id
  http_method = aws_api_gateway_method.options_method.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_response" {
  rest_api_id = aws_api_gateway_rest_api.chat_rest_api.id
  resource_id = aws_api_gateway_resource.room_resource.id
  http_method = aws_api_gateway_method.options_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.chat_rest_api.id
  resource_id = aws_api_gateway_resource.room_resource.id
  http_method = aws_api_gateway_method.options_method.http_method
  status_code = aws_api_gateway_method_response.options_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}
