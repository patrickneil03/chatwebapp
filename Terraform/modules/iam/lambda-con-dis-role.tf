resource "aws_iam_role" "lambda_con_dis_role" {
  name = "LambdaConnectDisconnectRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_con_dis_logs" {
  role       = aws_iam_role.lambda_con_dis_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "lambda_dynamodb_connect" {
  name        = "lambda-dynamodb-connect"
  description = "Allow Lambda to access DynamoDB connections table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan"
        ]
        Resource = [
          var.connections_table_arn,
          "${var.connections_table_arn}/*"
        ]
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "lambda_dynamodb_attach" {
  role       = aws_iam_role.lambda_con_dis_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb_connect.arn
}




