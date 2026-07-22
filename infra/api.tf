resource "aws_apigatewayv2_api" "gt" {
  name          = "geek-trivia-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = [
      "http://localhost:5500",
      "https://${aws_cloudfront_distribution.web.domain_name}",
    ]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["authorization", "content-type"]
    max_age       = 300
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.gt.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 10
    throttling_rate_limit  = 5
  }
}

resource "aws_apigatewayv2_authorizer" "jwt" {
  api_id           = aws_apigatewayv2_api.gt.id
  name             = "cognito-jwt"
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.web.id]
    issuer   = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.users.id}"
  }
}

locals {
  api_routes = {
    "GET /questions" = {
      invoke_arn    = module.get_questions.invoke_arn
      function_name = module.get_questions.function_name
      auth          = true
    }
    "GET /qotd" = {
      invoke_arn    = module.get_qotd.invoke_arn
      function_name = module.get_qotd.function_name
      auth          = false
    }
    "GET /leaderboard" = {
      invoke_arn    = module.get_leaderboard.invoke_arn
      function_name = module.get_leaderboard.function_name
      auth          = false
    }
    "POST /scores" = {
      invoke_arn    = module.submit_score.invoke_arn
      function_name = module.submit_score.function_name
      auth          = true
    }
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  for_each = local.api_routes

  api_id                 = aws_apigatewayv2_api.gt.id
  integration_type       = "AWS_PROXY"
  integration_uri        = each.value.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "this" {
  for_each = local.api_routes

  api_id    = aws_apigatewayv2_api.gt.id
  route_key = each.key
  target    = "integrations/${aws_apigatewayv2_integration.lambda[each.key].id}"

  authorization_type = each.value.auth ? "JWT" : "NONE"
  authorizer_id      = each.value.auth ? aws_apigatewayv2_authorizer.jwt.id : null
}

resource "aws_lambda_permission" "api_invoke" {
  for_each = local.api_routes

  statement_id  = "AllowAPIGw-${replace(replace(each.key, " ", "-"), "/", "")}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.gt.execution_arn}/*/*"
}