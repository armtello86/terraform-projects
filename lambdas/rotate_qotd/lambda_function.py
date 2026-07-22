import json
import random
import boto3

dynamodb = boto3.resource("dynamodb")
ssm = boto3.client("ssm")
table = dynamodb.Table("GeekTrivia-Questions")

def lambda_handler(event, context):
    # Tiny table (18 items): Scan is the right tool here.
    result = table.scan(
        ProjectionExpression="category, question_id, #q, #o",
        ExpressionAttributeNames={"#q": "question", "#o": "options"},
    )
    pick = random.choice(result["Items"])

    # Publish WITHOUT the answer — the banner is a teaser, not a leak.
    qotd = {
        "category": pick["category"],
        "question_id": pick["question_id"],
        "question": pick["question"],
        "options": list(pick["options"]),
    }
    ssm.put_parameter(
        Name="/geektrivia/qotd",
        Value=json.dumps(qotd),
        Type="String",
        Overwrite=True,
    )
    return {"qotd": qotd["question_id"], "category": qotd["category"]}
