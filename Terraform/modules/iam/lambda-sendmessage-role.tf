data "aws_caller_identity" "current" {}


resource "aws_iam_role" "lambda_sendmessage_role" {
  name = "LambdaSendMessageRole"

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

resource "aws_iam_role_policy_attachment" "lambda__sendmessage_logs" {
  role       = aws_iam_role.lambda_sendmessage_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_iam_policy" "lambda_apigateway_sendmessage" {
  name        = "lambda-apigateway-sendmessage"
  description = "Allow Lambda to manage WebSocket connections via API Gateway and save messages in DynamoDB"

  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "execute-api:ManageConnections",
      "Resource": "arn:aws:execute-api:ap-southeast-1:516969219217:qhrwltdx8c/*/POST/@connections/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:DeleteItem",
        "dynamodb:Scan",
        "dynamodb:Query",
        "dynamodb:UpdateItem"
      ],
      "Resource": [
        "arn:aws:dynamodb:ap-southeast-1:516969219217:table/connections",
        "arn:aws:dynamodb:ap-southeast-1:516969219217:table/connections/*",
        "arn:aws:dynamodb:ap-southeast-1:516969219217:table/messages",
        "arn:aws:dynamodb:ap-southeast-1:516969219217:table/messages/*"
      ]
    }
  ]
}
)
}


resource "aws_iam_role_policy_attachment" "lambda_apigateway_attach" {
  role       = aws_iam_role.lambda_sendmessage_role.name
  policy_arn = aws_iam_policy.lambda_apigateway_sendmessage.arn
}
