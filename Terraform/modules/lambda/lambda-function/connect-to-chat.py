import os, json, boto3, urllib3
from botocore.exceptions import ClientError

dynamodb    = boto3.resource("dynamodb")
conns_table = dynamodb.Table(os.environ["DYNAMODB_TABLE_NAME"])
http        = urllib3.PoolManager()

def lambda_handler(event, context):
    rc            = event["requestContext"]
    conn_id       = rc["connectionId"]
    params        = event.get("queryStringParameters") or {}
    room_id       = params.get("roomId", "")
    user_id       = params.get("userId", "")
    display_name  = params.get("fromName", "")

    # 1) Save connection
    item = {"connectionId": conn_id, "roomId": room_id}
    if user_id:     item["userId"]      = user_id
    if display_name: item["displayName"] = display_name
    conns_table.put_item(Item=item)

    # 2) Fetch history
    history = []
    rest_base = os.environ.get("REST_API_BASE_URL")
    if rest_base and room_id:
        url = f"{rest_base}/messages/{room_id}"
        try:
            resp = http.request("GET", url)
            if resp.status == 200:
                history = json.loads(resp.data)
        except Exception:
            pass

    # 3) Push via WebSocket
    mgmt = os.environ.get("WEBSOCKET_API_URL") \
           or f"https://{rc['domainName']}/{rc['stage']}"
    apigw = boto3.client("apigatewaymanagementapi", endpoint_url=mgmt)

    try:
        apigw.post_to_connection(
          ConnectionId=conn_id,
          Data=json.dumps({
            "action":   "messageHistory",
            "messages": history
          }).encode()
        )
    except ClientError:
        pass

    return {"statusCode": 200}
