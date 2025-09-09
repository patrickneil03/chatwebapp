import boto3
import os
import json
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource("dynamodb")
messages_table = dynamodb.Table(os.environ["DYNAMODB_MESSAGES_TABLE_NAME"])

def lambda_handler(event, context):
    try:
        # Get roomId from path parameters
        room_id = event["pathParameters"]["roomId"]
        
        # Query messages for the room
        resp = messages_table.query(
            KeyConditionExpression=Key("roomId").eq(room_id),
            ScanIndexForward=False,  # Get latest messages first
            Limit=100  # Limit to 100 most recent messages
        )
        
        items = []
        for i in resp.get("Items", []):
            items.append({
                "from": i.get("from"),
                "fromName": i.get("fromName"),
                "message": i.get("message"),
                "timestamp": i.get("timestamp")
            })
        
        # Reverse to show oldest first
        items.reverse()
        
        return {
            "statusCode": 200,
            "body": json.dumps(items),
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type, Authorization"
            }
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)}),
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type, Authorization"
            }
        }