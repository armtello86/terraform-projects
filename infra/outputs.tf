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