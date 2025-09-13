import os
import json
import boto3
from boto3.dynamodb.conditions import Attr

# DynamoDB table holding all active WebSocket connections
dynamodb = boto3.resource("dynamodb")
table    = dynamodb.Table(os.environ["DYNAMODB_TABLE_NAME"])

def lambda_handler(event, context):
    # 1) Extract connectionId, domainName, and stage from the request context
    conn_id = event["requestContext"]["connectionId"]
    domain  = event["requestContext"]["domainName"]
    stage   = event["requestContext"]["stage"]

    # 2) Build the Management API client for posting back to clients
    apigw = boto3.client(
        "apigatewaymanagementapi",
        endpoint_url=f"https://{domain}/{stage}"
    )

    # 3) Fetch this connection’s metadata (roomId, userId, displayName)
    resp = table.get_item(Key={"connectionId": conn_id})
    item = resp.get("Item")

    if item:
        room_id      = item["roomId"]
        user_id      = item.get("userId")
        display_name = item.get("displayName")

        # 4) Broadcast "userLeft" to everyone else in the same room
        scan = table.scan(FilterExpression=Attr("roomId").eq(room_id))
        for rec in scan.get("Items", []):
            target = rec["connectionId"]
            if target == conn_id:
                continue

            payload = {
                "action":   "userLeft",
                "fromName": display_name,
                "userId":   user_id
            }

            try:
                apigw.post_to_connection(
                    ConnectionId=target,
                    Data=json.dumps(payload).encode("utf-8")
                )
            except apigw.exceptions.GoneException:
                # Stale connection; ignore
                pass

    # 5) Remove this connection’s record so it no longer receives broadcasts
    table.delete_item(Key={"connectionId": conn_id})

    return {"statusCode": 200}
