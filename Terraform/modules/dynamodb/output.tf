output "connections_table_arn" {
  value = aws_dynamodb_table.connections.arn
  
}

output "aws_dynamodb_table_name" {
  value = aws_dynamodb_table.connections.name
  
}

output "dynamodb_messages_table_name" {
  value = aws_dynamodb_table.messages.name
  
}