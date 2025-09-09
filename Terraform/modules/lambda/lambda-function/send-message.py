import os
import json
import boto3
from datetime import datetime
from boto3.dynamodb.conditions import Attr

# DynamoDB tables
dynamodb          = boto3.resource("dynamodb")
messages_table    = dynamodb.Table(os.environ["DYNAMODB_MESSAGES_TABLE_NAME"])
connections_table = dynamodb.Table(os.environ["DYNAMODB_TABLE_NAME"])

# WebSocket API Gateway endpoint
WEBSOCKET_API_URL = os.environ["WEBSOCKET_API_URL"]
apigw             = boto3.client(
    "apigatewaymanagementapi",
    endpoint_url=WEBSOCKET_API_URL
)

def lambda_handler(event, context):
    try:
        conn_id     = event["requestContext"]["connectionId"]
        body        = json.loads(event.get("body","{}"))
        action      = body.get("action")
        room_id     = body.get("roomId")
        from_name   = body.get("fromName", conn_id)
        message_txt = body.get("message","")

        # 1) Validate
        if not action or not room_id:
            return {"statusCode":400,"body":"Missing action or roomId."}

        # 2) Build payload & persist if chat
        if action == "sendMessage":
            if not message_txt:
                return {"statusCode":400,"body":"Missing message text."}
            ts = datetime.utcnow().isoformat()
            messages_table.put_item(Item={
                "roomId":    room_id,
                "timestamp": ts,
                "from":      conn_id,
                "fromName":  from_name,
                "message":   message_txt
            })
            payload = {
                "action":    "newMessage",
                "fromName":  from_name,
                "message":   message_txt,
                "timestamp": ts
            }

        elif action in ("userJoined", "userLeft", "typing", "stopTyping"):
            payload = {
                "action":   action,
                "fromName": from_name
            }

        else:
            return {"statusCode":400,"body":f"Unsupported action: {action}"}

        # 3) Find all connections in this room via SCAN
        resp = connections_table.scan(
            FilterExpression=Attr("roomId").eq(room_id)
        )

        # 4) Broadcast to each
        for item in resp.get("Items", []):
            target = item["connectionId"]

            # Only suppress typing/stopTyping echo to self
            if action in ("typing","stopTyping") and target == conn_id:
                continue

            try:
                apigw.post_to_connection(
                    ConnectionId=target,
                    Data=json.dumps(payload).encode("utf-8")
                )
            except apigw.exceptions.GoneException:
                # clean up stale
                connections_table.delete_item(Key={"connectionId": target})
            except Exception as e:
                print(f"Error to {target}: {e}")

        return {"statusCode":200,"body":"Action processed."}

    except Exception as e:
        print("Fatal:", e)
        return {"statusCode":500,"body":"Internal server error"}
