output "questions_table_name" {
  description = "DynamoDB questions table"
  value       = aws_dynamodb_table.questions.name
}

output "scores_queue_url" {
  value = aws_sqs_queue.scores.url
}