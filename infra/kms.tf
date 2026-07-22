resource "aws_kms_key" "gt" {
  description             = "Geek Trivia CMK for SecureString parameters"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "gt" {
  name          = "alias/geektrivia-key"
  target_key_id = aws_kms_key.gt.key_id
}

resource "aws_ssm_parameter" "external_api_key" {
  name   = "/geektrivia/external-api-key"
  type   = "SecureString"
  key_id = aws_kms_key.gt.key_id
  value  = var.external_api_key
}