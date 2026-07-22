# ---------- SQS ----------
resource "aws_sqs_queue" "scores_dlq" {
  name = "gt-scores-dlq"
}

resource "aws_sqs_queue" "scores" {
  name                       = "gt-scores-queue"
  visibility_timeout_seconds = 60

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.scores_dlq.arn
    maxReceiveCount     = 3
  })
}

# ---------- SNS ----------
resource "aws_sns_topic" "welcome" {
  name = "gt-welcome-topic"
}

resource "aws_sns_topic" "digest" {
  name = "gt-digest-topic"
}

resource "aws_sns_topic" "ops" {
  name = "gt-ops-alerts"
}

# One email subscription per topic, same address, without repeating ourselves:
resource "aws_sns_topic_subscription" "email" {
  for_each = {
    welcome = aws_sns_topic.welcome.arn
    digest  = aws_sns_topic.digest.arn
    ops     = aws_sns_topic.ops.arn
  }

  topic_arn = each.value
  protocol  = "email"
  endpoint  = var.alert_email
}