output "questions_table_name" {
  description = "DynamoDB questions table"
  value       = aws_dynamodb_table.questions.name
}

output "scores_queue_url" {
  value = aws_sqs_queue.scores.url
}

output "user_pool_id" {
  value = aws_cognito_user_pool.users.id
}

output "app_client_id" {
  value = aws_cognito_user_pool_client.web.id
}

output "api_url" {
  value = aws_apigatewayv2_api.gt.api_endpoint
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.web.domain_name
}

output "frontend_config" {
  description = "Values for the CONFIG block in frontend/app.js"
  value = {
    API_URL      = aws_apigatewayv2_api.gt.api_endpoint
    USER_POOL_ID = aws_cognito_user_pool.users.id
    CLIENT_ID    = aws_cognito_user_pool_client.web.id
  }
}

output "web_bucket_name" {
  value = aws_s3_bucket.web.bucket
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.web.id
}