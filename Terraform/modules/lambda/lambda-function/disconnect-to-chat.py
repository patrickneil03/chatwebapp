import os
import json
import boto3
from boto3.dynamodb.conditions import Attr

# Lambda environment variable:
#   DYNAMODB_TABLE_NAME → your DynamoDB table holding connection records
dynamodb = boto3.resource("dynamodb")
table    = dynamodb.Table(os.environ["DYNAMODB_TABLE_NAME"])

def lambda_handler(event, context):
    # 1) Extract connectionId, domainName, and stage from the request context
    conn_id = event["requestContext"]["connectionId"]
    domain  = event["requestContext"]["domainName"]  # e.g. abc123.execute-api.us-east-1.amazonaws.com
    stage   = event["requestContext"]["stage"]       # e.g. prod

    # 2) Build the Management API client dynamically
    apigw = boto3.client(
        "apigatewaymanagementapi",
        endpoint_url=f"https://{domain}/{stage}"
    )

    # 3) Retrieve this connection's record to learn roomId and userName
    resp = table.get_item(Key={"connectionId": conn_id})
    item = resp.get("Item")

    if item:
        room = item["roomId"]
        user = item["userName"]

        # 4) Broadcast "userLeft" to all other connections in the same room
        scan = table.scan(FilterExpression=Attr("roomId").eq(room))
        for rec in scan.get("Items", []):
            target = rec["connectionId"]
            if target == conn_id:
                continue
            try:
                apigw.post_to_connection(
                    ConnectionId=target,
                    Data=json.dumps({
                        "action":   "userLeft",
                        "fromName": user
                    }).encode("utf-8")
                )
            except apigw.exceptions.GoneException:
                # Connection is stale; it will be cleaned up on its own
                pass

    # 5) Finally remove this connection from DynamoDB
    table.delete_item(Key={"connectionId": conn_id})

    return {"statusCode": 200}
