resource "aws_ssm_parameter" "questions_table" {
  name  = "/geektrivia/tables/questions"
  type  = "String"
  value = aws_dynamodb_table.questions.name
}

resource "aws_ssm_parameter" "scores_table" {
  name  = "/geektrivia/tables/scores"
  type  = "String"
  value = aws_dynamodb_table.scores.name
}

resource "aws_ssm_parameter" "qotd" {
  name  = "/geektrivia/qotd"
  type  = "String"
  value = "{}"

  lifecycle {
    ignore_changes = [value] # the rotate-qotd lambda rewrites this daily. 
  }
}