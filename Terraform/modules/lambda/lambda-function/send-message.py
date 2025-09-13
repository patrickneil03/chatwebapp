import os
import json
import boto3
from datetime import datetime
from boto3.dynamodb.conditions import Attr

# DynamoDB tables
dynamodb            = boto3.resource("dynamodb")
messages_table      = dynamodb.Table(os.environ["DYNAMODB_MESSAGES_TABLE_NAME"])
connections_table   = dynamodb.Table(os.environ["DYNAMODB_TABLE_NAME"])

# WebSocket API Gateway endpoint
WEBSOCKET_API_URL = os.environ["WEBSOCKET_API_URL"]
apigw             = boto3.client(
    "apigatewaymanagementapi",
    endpoint_url=WEBSOCKET_API_URL
)

def lambda_handler(event, context):
    try:
        conn_id      = event["requestContext"]["connectionId"]
        body         = json.loads(event.get("body", "{}"))
        action       = body.get("action")
        room_id      = body.get("roomId")
        display_name = body.get("fromName", "")
        user_id      = body.get("userId", conn_id)
        message_txt  = body.get("message", "")

        # 1) Validation
        if not action or not room_id:
            return {"statusCode": 400, "body": "Missing action or roomId."}

        # 2) Read-receipt: messageSeen
        if action == "messageSeen":
            message_id          = body.get("messageId")
            original_user_id    = body.get("originalSenderUserId")
            if not message_id or not original_user_id:
                return {
                    "statusCode": 400,
                    "body":       "Missing messageId or originalSenderUserId."
                }

            payload = {
                "action":    "messageSeen",
                "userId":    user_id,
                "fromName":  display_name,
                "messageId": message_id
            }

            # Only send to the original sender’s connection(s)
            resp = connections_table.scan(
                FilterExpression=Attr("roomId").eq(room_id) &
                                  Attr("userId").eq(original_user_id)
            )
            for rec in resp.get("Items", []):
                target = rec["connectionId"]
                try:
                    apigw.post_to_connection(
                        ConnectionId=target,
                        Data=json.dumps(payload).encode("utf-8")
                    )
                except apigw.exceptions.GoneException:
                    connections_table.delete_item(Key={"connectionId": target})

            return {"statusCode": 200, "body": "Seen notification sent."}

        # 3) Build & persist payload for chat/presence
        if action == "sendMessage":
            if not message_txt:
                return {"statusCode": 400, "body": "Missing message text."}
            ts = datetime.utcnow().isoformat()

            # persist chat message
            messages_table.put_item(Item={
                "roomId":      room_id,
                "timestamp":   ts,
                "userId":      user_id,
                "displayName": display_name,
                "message":     message_txt
            })

            payload = {
                "action":    "newMessage",
                "fromName":  display_name,
                "userId":    user_id,
                "message":   message_txt,
                "timestamp": ts
            }

        elif action in ("userJoined", "userLeft", "typing", "stopTyping"):
            payload = {
                "action":   action,
                "fromName": display_name,
                "userId":   user_id
            }

        else:
            return {
                "statusCode": 400,
                "body":       f"Unsupported action: {action}"
            }

        # 4) Broadcast to all connections in the room
        resp = connections_table.scan(
            FilterExpression=Attr("roomId").eq(room_id)
        )
        for rec in resp.get("Items", []):
            target = rec["connectionId"]

            # suppress typing/stopTyping echo back to self
            if action in ("typing", "stopTyping") and target == conn_id:
                continue

            try:
                apigw.post_to_connection(
                    ConnectionId=target,
                    Data=json.dumps(payload).encode("utf-8")
                )
            except apigw.exceptions.GoneException:
                connections_table.delete_item(Key={"connectionId": target})
            except Exception as e:
                print(f"Error posting to {target}: {e}")

        return {"statusCode": 200, "body": "Action processed."}

    except Exception as e:
        print("Fatal error:", e)
        return {"statusCode": 500, "body": "Internal server error."}
