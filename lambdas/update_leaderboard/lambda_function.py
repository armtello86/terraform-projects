import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("GeekTrivia-Scores")
TOP_N = 10

def lambda_handler(event, context):
    new_entries = []
    for record in event["Records"]:
        if record["eventName"] != "INSERT":
            continue
        keys = record["dynamodb"]["Keys"]
        # GUARD: ignore our own aggregate item or we loop forever.
        if keys["pk"]["S"] == "LEADERBOARD":
            continue
        img = record["dynamodb"]["NewImage"]
        new_entries.append({
            "username": img["username"]["S"],
            "score": int(img["score"]["N"]),
            "category": img["category"]["S"],
            "date": img["created_at"]["S"][:10],
        })

    if not new_entries:
        return {"updated": False}

    current = table.get_item(
        Key={"pk": "LEADERBOARD", "sk": "GLOBAL"}
    ).get("Item", {}).get("top", [])

    # Keep the best score per user AND per category, so every category
    # a player has completed gets its own row on the board.
    best = {}
    for e in list(current) + new_entries:
        key = (e["username"], e["category"])
        if key not in best or int(e["score"]) > int(best[key]["score"]):
            best[key] = e

    top = sorted(
        best.values(),
        key=lambda x: (int(x["score"]), x["date"]),
        reverse=True,
    )[:TOP_N]
    table.put_item(Item={"pk": "LEADERBOARD", "sk": "GLOBAL", "top": top})
    return {"updated": True, "entries": len(top)}