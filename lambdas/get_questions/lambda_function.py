import json
import boto3
from boto3.dynamodb.conditions import Key

ssm = boto3.client("ssm")
dynamodb = boto3.resource("dynamodb")

# Read config once per container (cold start), not on every request.
TABLE_NAME = ssm.get_parameter(Name="/geektrivia/tables/questions")["Parameter"]["Value"]
table = dynamodb.Table(TABLE_NAME)

ALLOWED = {"aws", "linux", "databases"}

def lambda_handler(event, context):
    params = event.get("queryStringParameters") or {}
    category = (params.get("category") or "").lower()

    if category not in ALLOWED:
        return _response(400, {"error": f"category must be one of {sorted(ALLOWED)}"})

    result = table.query(
        KeyConditionExpression=Key("category").eq(category),
        ProjectionExpression="question_id, #q, #o, answer_index, difficulty",
        ExpressionAttributeNames={"#q": "question", "#o": "options"},
    )

    items = [
        {
            "question_id": it["question_id"],
            "question": it["question"],
            "options": it["options"],
            "answer_index": int(it["answer_index"]),
            "difficulty": it["difficulty"],
        }
        for it in result["Items"]
    ]
    return _response(200, {"category": category, "questions": items})

def _response(status, body):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }
