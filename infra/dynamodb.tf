resource "aws_dynamodb_table" "questions" {
  name         = "GeekTrivia-Questions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "category"
  range_key    = "question_id"

  attribute {
    name = "category"
    type = "S"
  }
  attribute {
    name = "question_id"
    type = "S"
  }

}

resource "aws_dynamodb_table" "scores" {
  name         = "GeekTrivia-Scores"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"

  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"

  attribute {
    name = "pk"
    type = "S"
  }
  attribute {
    name = "sk"
    type = "S"
  }
}