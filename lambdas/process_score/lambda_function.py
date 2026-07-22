import json
from datetime import datetime, timezone
import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("GeekTrivia-Scores")

def lambda_handler(event, context):
    # SQS delivers batches of up to 10 messages in event["Records"].
    for record in event["Records"]:
        msg = json.loads(record["body"])
        ts_iso = datetime.fromtimestamp(msg["ts"], tz=timezone.utc).isoformat()

        table.put_item(Item={
            "pk": f"USER#{msg['user_id']}",
            "sk": f"SCORE#{ts_iso}#{record['messageId'][:8]}",
            "username": msg["username"],
            "score": msg["score"],
            "total": msg["total"],
            "category": msg["category"],
            "created_at": ts_iso,
        })
    # If any put_item raises, the whole batch returns to the queue (retry).
    return {"processed": len(event["Records"])}
