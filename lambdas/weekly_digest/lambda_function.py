import os
import boto3

dynamodb = boto3.resource("dynamodb")
sns = boto3.client("sns")
ssm = boto3.client("ssm")

table = dynamodb.Table("GeekTrivia-Scores")
TOPIC_ARN = os.environ["DIGEST_TOPIC_ARN"]

def lambda_handler(event, context):
    # Read the encrypted secret: requires ssm:GetParameter AND kms:Decrypt.
    api_key = ssm.get_parameter(
        Name="/geektrivia/external-api-key", WithDecryption=True
    )["Parameter"]["Value"]
    # Demo pattern: we just prove we can read it (masked in logs).
    print(f"External API key loaded: {api_key[:4]}*** (len={len(api_key)})")

    item = table.get_item(Key={"pk": "LEADERBOARD", "sk": "GLOBAL"}).get("Item")
    top = (item or {}).get("top", [])[:3]

    if not top:
        lines = ["No scores yet this week. Be the first!"]
    else:
        medals = ["🥇", "🥈", "🥉"]
        lines = [
            f"{medals[i]} {e['username']} — {int(e['score'])} pts ({e['category']})"
            for i, e in enumerate(top)
        ]

    sns.publish(
        TopicArn=TOPIC_ARN,
        Subject="Geek Trivia — Weekly Top 3",
        Message="This week's podium:\n\n" + "\n".join(lines) + "\n\nPlay now and dethrone them!",
    )
    return {"sent": True, "entries": len(top)}
