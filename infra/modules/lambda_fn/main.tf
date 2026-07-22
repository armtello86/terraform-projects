# 1) Zip the source folder. Terraform re-zips (and re-deploys) only when the code changes,
#    thanks to source_code_hash below.
data "archive_file" "zip" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.root}/build/${var.function_name}.zip"
}

# 2) The role this function will assume at runtime.
resource "aws_iam_role" "this" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# 3) Logs permission: every lambda gets it (same as the console's "basic permissions").
resource "aws_iam_role_policy_attachment" "basic_logs" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 4) Optional extra managed policies (SQS poller, DynamoDB streams reader...).
resource "aws_iam_role_policy_attachment" "extra" {
  for_each   = toset(var.managed_policy_arns)
  role       = aws_iam_role.this.name
  policy_arn = each.value
}

# 5) Optional inline least-privilege policy (the JSONs from the console guide).
resource "aws_iam_role_policy" "inline" {
  count  = var.policy_json == null ? 0 : 1
  name   = "${var.function_name}-policy"
  role   = aws_iam_role.this.id
  policy = var.policy_json
}

# 6) The function itself.
resource "aws_lambda_function" "this" {
  function_name    = var.function_name
  role             = aws_iam_role.this.arn
  runtime          = var.runtime
  handler          = "lambda_function.lambda_handler"
  architectures    = ["arm64"]
  timeout          = var.timeout
  memory_size      = var.memory_size
  filename         = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256

  dynamic "environment" {
    for_each = length(var.environment) > 0 ? [1] : []
    content {
      variables = var.environment
    }
  }
}