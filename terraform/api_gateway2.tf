
resource "aws_lb" "main" {
    name               = "main"
    internal           = false
    load_balancer_type = "network"
    subnets = [
      data.terraform_remote_state.infra.outputs.subnet_private_a_id,
      data.terraform_remote_state.infra.outputs.subnet_private_b_id
    ]
}
resource "aws_lb_target_group" "main" {
  name     = "aws-lb-target-group-main"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = data.terraform_remote_state.infra.outputs.aws_vpc_id
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# resource "aws_api_gateway_vpc_link" "main" {
#  name = "foobar_gateway_vpclink"
#  description = "Foobar Gateway VPC Link. Managed by Terraform."
#  target_arns = [aws_lb.main.arn]
# }


# resource "aws_api_gateway_rest_api" "main" {
#  name = "foobar_gateway"
#  description = "Foobar Gateway used for EKS. Managed by Terraform."
#  endpoint_configuration {
#    types = ["REGIONAL"]
#  }
# }


# resource "aws_api_gateway_resource" "proxy" {
#   rest_api_id = aws_api_gateway_rest_api.main.id
#   parent_id   = aws_api_gateway_rest_api.main.root_resource_id
#   path_part   = "{proxy+}"
# }

# resource "aws_api_gateway_method" "proxy" {
#   rest_api_id   = aws_api_gateway_rest_api.main.id
#   resource_id   = aws_api_gateway_resource.proxy.id
#   http_method   = "ANY"
#   authorization = "NONE"

#   request_parameters = {
#     "method.request.path.proxy"           = true
#     "method.request.header.Authorization" = true
#   }
# }

# resource "aws_api_gateway_integration" "proxy" {
#   rest_api_id = aws_api_gateway_rest_api.main.id
#   resource_id = aws_api_gateway_resource.proxy.id
#   http_method = "ANY"

#   integration_http_method = "ANY"
#   type                    = "HTTP_PROXY"
#   uri                     = "http://${aws_lb.main.dns_name}/{proxy}"
#   passthrough_behavior    = "WHEN_NO_MATCH"
#   content_handling        = "CONVERT_TO_TEXT"

#   request_parameters = {
#     "integration.request.path.proxy"           = "method.request.path.proxy"
#     "integration.request.header.Accept"        = "'application/json'"
#     "integration.request.header.Authorization" = "method.request.header.Authorization"
#   }

#   connection_type = "VPC_LINK"
#   connection_id   = aws_api_gateway_vpc_link.main.id
# }



# -------

# resource "aws_apigatewayv2_vpc_link" "api" {
#   name               = "api"
#   security_group_ids = [data.aws_security_group.eks.id]
#   subnet_ids         =  [
#       data.terraform_remote_state.infra.outputs.subnet_private_a_id,
#       data.terraform_remote_state.infra.outputs.subnet_private_b_id
#     ]
# }

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

resource "aws_apigatewayv2_integration" "api" {
  api_id           = aws_apigatewayv2_api.default.id
  integration_type = "HTTP_PROXY"
  integration_uri  = aws_lb_listener.main.arn # Replace with your actual EKS endpoint
#   integration_uri  = "http://${data.terraform_remote_state.infra.outputs.aws_eks_cluster_endpoint}"  # Replace with your actual EKS endpoint
  integration_method = "ANY"
    
}



resource "aws_apigatewayv2_route" "default" {
  api_id = aws_apigatewayv2_api.default.id

  route_key = "GET /login"
  target    = "integrations/${aws_apigatewayv2_integration.default.id}"
}

resource "aws_apigatewayv2_route" "api" {
  api_id    = aws_apigatewayv2_api.default.id
  route_key = "ANY /v1/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.api.id}"
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

output "login_api_gateway_url" {
  value = aws_apigatewayv2_stage.default.invoke_url
}
# output "v1_api_gateway_url" {
#   value = aws_apigatewayv2_api.api.api_endpoint
# }
