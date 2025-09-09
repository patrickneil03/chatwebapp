resource "aws_dynamodb_table" "connections" {
  name         = "connections"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "connectionId"

  attribute {
    name = "connectionId"
    type = "S"
  }

  attribute {
    name = "roomId"
    type = "S"
  }

  global_secondary_index {
    name               = "RoomIndex"
    hash_key           = "roomId"
    projection_type    = "ALL"
  }

  tags = {
    Environment = "dev"
    Project     = "websocket-chat"
  }
}
