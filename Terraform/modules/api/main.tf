# -----------------------------
# 1. Create WebSocket API
# -----------------------------
resource "aws_apigatewayv2_api" "chat_ws_api" {
  name          = "chat-websocket-api"
  protocol_type = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
  description = "API for chat application using WebSocket"
}

# -----------------------------
# 2. Create Routes (connect, disconnect, default)
# -----------------------------
resource "aws_apigatewayv2_route" "connect_route" {
  api_id    = aws_apigatewayv2_api.chat_ws_api.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.connect_integration.id}"
}

resource "aws_apigatewayv2_route" "disconnect_route" {
  api_id    = aws_apigatewayv2_api.chat_ws_api.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.disconnect_integration.id}"
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.chat_ws_api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.sendmessage_integration.id}"
}

# -----------------------------
# 3. Create Deployment
# -----------------------------
resource "aws_apigatewayv2_deployment" "chat_ws_deployment" {
  api_id = aws_apigatewayv2_api.chat_ws_api.id
  description = "WebSocket deployment"

  depends_on = [
    aws_apigatewayv2_route.connect_route,
    aws_apigatewayv2_route.disconnect_route,
    aws_apigatewayv2_route.default_route
  ]
}

# -----------------------------
# 4. Create Stage (production)
# -----------------------------
resource "aws_apigatewayv2_stage" "chat_ws_stage" {
  api_id      = aws_apigatewayv2_api.chat_ws_api.id
  name        = "prod"
  deployment_id = aws_apigatewayv2_deployment.chat_ws_deployment.id
}



resource "aws_apigatewayv2_integration" "connect_integration" {
  api_id                 = aws_apigatewayv2_api.chat_ws_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.connect_handler_invoke_arn
  integration_method     = "POST"

}

resource "aws_apigatewayv2_integration" "disconnect_integration" {
  api_id                 = aws_apigatewayv2_api.chat_ws_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.disconnect_handler_invoke_arn
  integration_method     = "POST"
  
}

resource "aws_apigatewayv2_integration" "sendmessage_integration" {
  api_id                 = aws_apigatewayv2_api.chat_ws_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.sendmessage_handler_invoke_arn
  integration_method     = "POST"
  
}
