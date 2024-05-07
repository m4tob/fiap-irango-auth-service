# Crie um API Gateway
resource "aws_api_gateway_rest_api" "default" {
  name        = "${data.terraform_remote_state.infra.outputs.resource_prefix}-api-gateway"
  description = "Fiap API Gateway"

  endpoint_configuration {
    types = ["REGIONAL"]
    # vpc_endpoint_ids = [aws_vpc.default.id]
  }

  tags = {
    Name = "${data.terraform_remote_state.infra.outputs.resource_prefix}-api-gateway"
  }
}

# Crie um recurso na API Gateway
resource "aws_api_gateway_resource" "default" {
  rest_api_id = aws_api_gateway_rest_api.default.id
  parent_id   = aws_api_gateway_rest_api.default.root_resource_id
  path_part   = "login"
}

# Defina um método na API Gateway (por exemplo, GET)
resource "aws_api_gateway_method" "default" {
  rest_api_id   = aws_api_gateway_rest_api.default.id
  resource_id   = aws_api_gateway_resource.default.id
  http_method   = "ANY"
  authorization = "NONE"
}
