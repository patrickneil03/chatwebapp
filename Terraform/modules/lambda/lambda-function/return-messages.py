import os
import json
import boto3
from boto3.dynamodb.conditions import Key

dynamodb       = boto3.resource("dynamodb")
messages_table = dynamodb.Table(os.environ["DYNAMODB_MESSAGES_TABLE_NAME"])

def lambda_handler(event, context):
    try:
        # 1) Extract roomId
        room_id = event["pathParameters"]["roomId"]
        
        # 2) Query DynamoDB
        resp = messages_table.query(
            KeyConditionExpression=Key("roomId").eq(room_id),
            ScanIndexForward=False,
            Limit=100
        )
        
        # 3) Build the list
        items = []                       # ← must be here
        for rec in resp.get("Items", []):
            items.append({
                "userId":    rec.get("userId"),
                "fromName":  rec.get("displayName"),
                "message":   rec.get("message"),
                "timestamp": rec.get("timestamp")
            })
        
        # 4) Reverse so oldest first
        items.reverse()
        
        # 5) Return success
        return {
            "statusCode": 200,
            "body":       json.dumps(items),
            "headers": {
                "Content-Type":                 "application/json",
                "Access-Control-Allow-Origin":  "*",
                "Access-Control-Allow-Methods": "GET,OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type,Authorization"
            }
        }
        
    except Exception as e:
        # Log the actual exception for CloudWatch
        print(f"Error in return-messages: {e}")
        return {
            "statusCode": 500,
            "body":       json.dumps({"error": str(e)}),
            "headers": {
                "Content-Type":                 "application/json",
                "Access-Control-Allow-Origin":  "*",
                "Access-Control-Allow-Methods": "GET,OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type,Authorization"
            }
        }