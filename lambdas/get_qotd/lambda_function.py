import json
import boto3

ssm = boto3.client("ssm")

def lambda_handler(event, context):
    raw = ssm.get_parameter(Name="/geektrivia/qotd")["Parameter"]["Value"]
    body = raw if raw and raw != "{}" else json.dumps({})
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": body,
    }
