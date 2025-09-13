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

# This policy now grants:
# • PutItem/DeleteItem/Scan on the connections table
# • Query on the messages table (including any indexes)
resource "aws_iam_policy" "lambda_dynamodb_connect" {
  name        = "lambda-dynamodb-access"
  description = "Allow Lambda to access DynamoDB connections and messages tables"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ConnectionsTableAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan"
        ]
        Resource = [
          var.connections_table_arn,
          "${var.connections_table_arn}/*"
        ]
      },
      {
        Sid    = "MessagesTableReadHistory"
        Effect = "Allow"
        Action = [
          "dynamodb:Query"
        ]
        Resource = [
          var.messages_table_arn,
          "${var.messages_table_arn}/index/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_attach" {
  role       = aws_iam_role.lambda_con_dis_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb_connect.arn
}
