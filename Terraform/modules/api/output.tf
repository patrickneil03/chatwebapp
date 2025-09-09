output "websocket_api_execution_arn" {
  value = aws_apigatewayv2_api.chat_ws_api.execution_arn
  
}

output "websocket_stage" {
  value = aws_apigatewayv2_stage.chat_ws_stage.name
}

output "websocket_api_id" {
  value = aws_apigatewayv2_api.chat_ws_api.id
}

output "chat_rest_api_execution_arn" {
  value = aws_api_gateway_rest_api.chat_rest_api.execution_arn
  
}

output "chat_ws_stage" {
  value = aws_apigatewayv2_stage.chat_ws_stage.name
  
}