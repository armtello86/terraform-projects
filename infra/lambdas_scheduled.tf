module "weekly_digest" {
  source        = "./modules/lambda_fn"
  function_name = "gt-weekly-digest"
  source_dir    = "${path.root}/../lambdas/weekly_digest"
  runtime       = var.lambda_runtime
  timeout       = 10

  environment = {
    DIGEST_TOPIC_ARN = aws_sns_topic.digest.arn
  }

  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem"]
        Resource = aws_dynamodb_table.scores.arn
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = aws_sns_topic.digest.arn
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = aws_ssm_parameter.external_api_key.arn
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = aws_kms_key.gt.arn
      }
    ]
  })
}

module "rotate_qotd" {
  source        = "./modules/lambda_fn"
  function_name = "gt-rotate-qotd"
  source_dir    = "${path.root}/../lambdas/rotate_qotd"
  runtime       = var.lambda_runtime

  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:Scan"]
        Resource = aws_dynamodb_table.questions.arn
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:PutParameter"]
        Resource = aws_ssm_parameter.qotd.arn
      }
    ]
  })
}

resource "aws_cloudwatch_event_rule" "daily_qotd" {
  name                = "gt-daily-qotd"
  schedule_expression = "cron(0 12 * * ? *)"
}

resource "aws_cloudwatch_event_target" "daily_qotd" {
  rule = aws_cloudwatch_event_rule.daily_qotd.name
  arn  = module.rotate_qotd.arn
}

resource "aws_lambda_permission" "events_invoke_rotate" {
  statement_id  = "AllowEventBridgeDaily"
  action        = "lambda:InvokeFunction"
  function_name = module.rotate_qotd.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_qotd.arn
}

resource "aws_cloudwatch_event_rule" "weekly_digest" {
  name                = "gt-weekly-digest"
  schedule_expression = "cron(0 15 ? * MON *)"
}

resource "aws_cloudwatch_event_target" "weekly_digest" {
  rule = aws_cloudwatch_event_rule.weekly_digest.name
  arn  = module.weekly_digest.arn
}

resource "aws_lambda_permission" "events_invoke_digest" {
  statement_id  = "AllowEventBridgeWeekly"
  action        = "lambda:InvokeFunction"
  function_name = module.weekly_digest.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weekly_digest.arn
}