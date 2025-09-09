output "connect_handler_invoke_arn" {
  value = aws_lambda_function.ConnectHandler.invoke_arn
  
}

output "disconnect_handler_invoke_arn" {
  value = aws_lambda_function.DisconnectHandler.invoke_arn
  
}

output "sendmessage_handler_invoke_arn" {
  value = aws_lambda_function.SendMessageHandler.invoke_arn
  
}

output "ReturnMessageHandler_name" {
  value = aws_lambda_function.ReturnMessageHandler.function_name
  
}

output "ReturnMessageHandler_invoke_arn" {
  value = aws_lambda_function.ReturnMessageHandler.invoke_arn
  
}