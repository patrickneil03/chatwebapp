import boto3
import os

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["DYNAMODB_TABLE_NAME"])

def lambda_handler(event, context):
    connection_id = event["requestContext"]["connectionId"]
    # roomId passed as query param from frontend
    room_id = event.get("queryStringParameters", {}).get("roomId", "default")

    table.put_item(Item={
        "connectionId": connection_id,
        "roomId": room_id
    })

    return {"statusCode": 200, "body": "Connected."}
