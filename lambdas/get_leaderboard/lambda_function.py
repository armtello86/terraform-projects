import json
import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("GeekTrivia-Scores")

def lambda_handler(event, context):
    item = table.get_item(Key={"pk": "LEADERBOARD", "sk": "GLOBAL"}).get("Item")
    top = item.get("top", []) if item else []

    # DynamoDB returns numbers as Decimal -> make them JSON-safe ints.
    clean = [
        {"username": e["username"], "score": int(e["score"]),
         "category": e["category"], "date": e["date"]}
        for e in top
    ]
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"top": clean}),
    }
