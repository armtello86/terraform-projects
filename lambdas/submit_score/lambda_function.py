import json
import os
import time
import boto3

sqs = boto3.client("sqs")
QUEUE_URL = os.environ["QUEUE_URL"]
ALLOWED = {"aws", "linux", "databases"}

def lambda_handler(event, context):
    # Identity comes from the validated JWT, never from the body.
    claims = event["requestContext"]["authorizer"]["jwt"]["claims"]
    user_id = claims["sub"]
    username = claims.get("name") or claims.get("email", "anonymous")

    try:
        body = json.loads(event.get("body") or "{}")
        score = int(body["score"])
        total = int(body["total"])
        category = str(body["category"]).lower()
    except (KeyError, ValueError, TypeError):
        return _response(400, {"error": "body needs: score, total, category"})

    if category not in ALLOWED or not (0 <= score <= total <= 20):
        return _response(400, {"error": "invalid score or category"})

    message = {
        "user_id": user_id,
        "username": username,
        "score": score,
        "total": total,
        "category": category,
        "ts": int(time.time()),
    }
    sqs.send_message(QueueUrl=QUEUE_URL, MessageBody=json.dumps(message))

    # 202 Accepted: "received, will process async" — the honest status code.
    return _response(202, {"status": "queued"})

def _response(status, body):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }
