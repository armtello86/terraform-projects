module "submit_score" {
  source        = "./modules/lambda_fn"
  function_name = "gt-submit-score"
  source_dir    = "${path.root}/../lambdas/submit_score"
  runtime       = var.lambda_runtime

  environment = {
    QUEUE_URL = aws_sqs_queue.scores.url
  }

  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sqs:SendMessage"]
      Resource = aws_sqs_queue.scores.arn
    }]
  })
}

module "process_score" {
  source        = "./modules/lambda_fn"
  function_name = "gt-process-score"
  source_dir    = "${path.root}/../lambdas/process_score"
  runtime       = var.lambda_runtime
  timeout       = 10

  # The managed policy the console attached when you clicked "Add trigger":
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
  ]

  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:PutItem"]
      Resource = aws_dynamodb_table.scores.arn
    }]
  })
}

# The trigger itself: "SQS, invoke this lambda with batches of up to 10".
resource "aws_lambda_event_source_mapping" "sqs_to_process" {
  event_source_arn = aws_sqs_queue.scores.arn
  function_name    = module.process_score.function_name
  batch_size       = 10
}

module "update_leaderboard" {
  source        = "./modules/lambda_fn"
  function_name = "gt-update-leaderboard"
  source_dir    = "${path.root}/../lambdas/update_leaderboard"
  runtime       = var.lambda_runtime

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaDynamoDBExecutionRole"
  ]

  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:GetItem", "dynamodb:PutItem"]
      Resource = aws_dynamodb_table.scores.arn
    }]
  })
}

resource "aws_lambda_event_source_mapping" "stream_to_leaderboard" {
  event_source_arn  = aws_dynamodb_table.scores.stream_arn
  function_name     = module.update_leaderboard.function_name
  batch_size        = 10
  starting_position = "LATEST"   # streams need this; SQS mappings don't
}

module "cognito_welcome" {
  source        = "./modules/lambda_fn"
  function_name = "gt-cognito-welcome"
  source_dir    = "${path.root}/../lambdas/cognito_welcome"
  runtime       = var.lambda_runtime

  environment = {
    WELCOME_TOPIC_ARN = aws_sns_topic.welcome.arn
  }

  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sns:Publish"]
      Resource = aws_sns_topic.welcome.arn
    }]
  })
}