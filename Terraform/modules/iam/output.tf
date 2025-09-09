output "lambda_con_dis_role_arn" {
  value = aws_iam_role.lambda_con_dis_role.arn
  
}

output "lambda_sendmessage_role_arn" {
  value = aws_iam_role.lambda_sendmessage_role.arn
  
}

output "return_message_role_arn" {
  value = aws_iam_role.return_message_role.arn
  
}