resource "aws_cognito_user_pool" "users" {
  name = "geek-trivia-users"

  # Sign in with email; Cognito verifies it automatically.
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  # The visible name shown on the leaderboard (same as the console wizard).
  schema {
    name                = "name"
    attribute_data_type = "String"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 100
    }
  }

  # Wire the post-confirmation trigger right here — in the console this was a separate screen.
  lambda_config {
    post_confirmation = module.cognito_welcome.arn
  }
}

resource "aws_cognito_user_pool_client" "web" {
  name         = "geek-trivia-web"
  user_pool_id = aws_cognito_user_pool.users.id

  # SPA rules: no secret (it would be visible in browser JS), SRP auth flow.
  generate_secret = false
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]
}

resource "aws_lambda_permission" "cognito_invoke_welcome" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.cognito_welcome.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.users.arn
}