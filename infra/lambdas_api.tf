module "seed_questions" {
  source        = "./modules/lambda_fn"
  function_name = "gt-seed-questions"
  source_dir    = "${path.root}/../lambdas/seed_questions"
  runtime       = var.lambda_runtime

  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:BatchWriteItem"]
      Resource = aws_dynamodb_table.questions.arn
    }]
  })
}

module "get_questions" {
  source        = "./modules/lambda_fn"
  function_name = "gt-get-questions"
  source_dir    = "${path.root}/../lambdas/get_questions"
  runtime       = var.lambda_runtime

  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:Query"]
        Resource = aws_dynamodb_table.questions.arn
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = "arn:aws:ssm:${var.aws_region}:*:parameter/geektrivia/*"
      }
    ]
  })
}

module "get_qotd" {
  source        = "./modules/lambda_fn"
  function_name = "gt-get-qotd"
  source_dir    = "${path.root}/../lambdas/get_qotd"
  runtime       = var.lambda_runtime

  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameter"]
      Resource = aws_ssm_parameter.qotd.arn
    }]
  })
}

module "get_leaderboard" {
  source        = "./modules/lambda_fn"
  function_name = "gt-get-leaderboard"
  source_dir    = "${path.root}/../lambdas/get_leaderboard"
  runtime       = var.lambda_runtime

  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:GetItem"]
      Resource = aws_dynamodb_table.scores.arn
    }]
  })
}