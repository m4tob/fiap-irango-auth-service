resource "aws_apigatewayv2_api" "default" {
  name          = "${data.terraform_remote_state.infra.outputs.resource_prefix}-api-gateway"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    allow_headers = ["Content-Type", "Authorization", "X-Amz-Date", "X-Api-Key", "X-Amz-Security-Token"]
  }

  tags = {
    Name = "${data.terraform_remote_state.infra.outputs.resource_prefix}-api-gateway"
  }
}

resource "aws_apigatewayv2_stage" "default" {
  name = "${data.terraform_remote_state.infra.outputs.resource_prefix}-api-gateway-stage"

  auto_deploy = true
  api_id      = aws_apigatewayv2_api.default.id

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_log_group.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }

  tags = {
    Name = "${data.terraform_remote_state.infra.outputs.resource_prefix}-api-gateway-stage"
  }
}

resource "aws_apigatewayv2_integration" "default" {
  api_id = aws_apigatewayv2_api.default.id

  integration_uri    = aws_lambda_function.login.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "default" {
  api_id = aws_apigatewayv2_api.default.id

  route_key = "GET /login"
  target    = "integrations/${aws_apigatewayv2_integration.default.id}"
}

resource "aws_cloudwatch_log_group" "api_gateway_log_group" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.default.name}"

  retention_in_days = 1
}

resource "aws_lambda_permission" "default" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.login.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.default.execution_arn}/*/*"
}

output "aws_api_gateway_url" {
  value = aws_apigatewayv2_stage.default.invoke_url
}
