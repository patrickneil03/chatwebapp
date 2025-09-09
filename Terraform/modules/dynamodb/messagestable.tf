resource "aws_dynamodb_table" "messages" {
  name         = "messages"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "roomId"
  range_key    = "timestamp"

  attribute {
    name = "roomId"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  tags = {
    Environment = "dev"
    Project     = "websocket-chat"
  }
}