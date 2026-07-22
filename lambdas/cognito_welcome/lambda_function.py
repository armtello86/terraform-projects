import os
import boto3

sns = boto3.client("sns")
TOPIC_ARN = os.environ["WELCOME_TOPIC_ARN"]

def lambda_handler(event, context):
    # Cognito post-confirmation trigger.
    attrs = event["request"]["userAttributes"]
    name = attrs.get("name", "geek")
    email = attrs.get("email", "unknown")

    sns.publish(
        TopicArn=TOPIC_ARN,
        Subject="Welcome to Geek Trivia!",
        Message=(
            f"Hi {name}!\n\n"
            f"Your account ({email}) is confirmed.\n"
            "Log in and climb the leaderboard. Good luck!\n"
        ),
    )

    # CRITICAL: Cognito triggers must return the event unchanged.
    return event
