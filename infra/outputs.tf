output "questions_table_name" {
  description = "DynamoDB questions table"
  value       = aws_dynamodb_table.questions.name
}