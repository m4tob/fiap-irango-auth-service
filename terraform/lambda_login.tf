resource "aws_security_group" "lambda" {
  name        = "${data.terraform_remote_state.infra.outputs.resource_prefix}-security-group-lambda"
  description = "inbound: all + outbound: all"
  vpc_id      = data.terraform_remote_state.infra.outputs.aws_vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${data.terraform_remote_state.infra.outputs.resource_prefix}-security-group-lambda"
  }
}

data "aws_iam_policy_document" "assume_role_lambda" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${data.terraform_remote_state.infra.outputs.resource_prefix}-lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name = "${data.terraform_remote_state.infra.outputs.resource_prefix}-lambda-login"

  retention_in_days = 1
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_iam_role_policy_attachment" "AWSLambdaVPCAccessExecutionRole" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "archive_file" "lambda_login_artefact" {
  type        = "zip"
  source_dir  = "${path.module}/../src/lambdas/login"
  output_path = "files/login_lambda_function_payload.zip"
}

resource "aws_lambda_function" "login" {
  function_name = "${data.terraform_remote_state.infra.outputs.resource_prefix}-lambda-login"
  filename      = "files/login_lambda_function_payload.zip"
  role          = aws_iam_role.lambda.arn
  # role             = "arn:aws:iam::364764462991:role/LabRole"
  handler          = "index.handler"
  timeout          = 5
  memory_size      = 128
  source_code_hash = data.archive_file.lambda_login_artefact.output_base64sha256
  depends_on = [
    aws_cloudwatch_log_group.lambda_log_group #,
    # aws_cognito_user_pool.default,
    # aws_cognito_user_pool_client.default
  ]

  runtime = var.lambda_login_runtime

  vpc_config {
    subnet_ids = [
      data.terraform_remote_state.infra.outputs.subnet_private_a_id,
      data.terraform_remote_state.infra.outputs.subnet_private_b_id
    ]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_HOSTNAME = "${split(":", data.terraform_remote_state.database.outputs.aws_db_instance_endpoint)[0]}",
      DB_PORT     = split(":", data.terraform_remote_state.database.outputs.aws_db_instance_endpoint)[1],
      DB_DATABASE = "${data.terraform_remote_state.database.outputs.db_name}",
      DB_USERNAME = "${var.db_user}",
      DB_PASSWORD = "${var.db_password}" #,
      # USER_POOL_ID = "${aws_cognito_user_pool.default.id}",
      # CLIENT_ID = "${aws_cognito_user_pool_client.id}",
    }
  }

  tags = {
    Name = "${data.terraform_remote_state.infra.outputs.resource_prefix}-lambda"
  }
}

# Integre a função Lambda ao método da API Gateway
resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.default.id
  resource_id = aws_api_gateway_resource.default.id
  http_method = aws_api_gateway_method.default.http_method

  integration_http_method = "GET"
  type                    = "AWS"
  uri                     = aws_lambda_function.login.invoke_arn
}

resource "aws_api_gateway_method_response" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.default.id
  resource_id = aws_api_gateway_resource.default.id
  http_method = aws_api_gateway_method.default.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.default.id
  resource_id = aws_api_gateway_resource.default.id
  http_method = aws_api_gateway_method.default.http_method
  status_code = aws_api_gateway_method_response.proxy.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_integration.lambda
  ]
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda,
  ]

  rest_api_id = aws_api_gateway_rest_api.default.id
  stage_name  = "dev"
}

# resource "aws_iam_role_policy_attachment" "lambda_basic" {
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# //role = aws_iam_role.lambda_role.name
#   role = "arn:aws:iam::364764462991:role/LabRole"
# }

# Conecte o método à função Lambda
resource "aws_lambda_permission" "fiap-gateway_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.login.function_name
  principal     = "apigateway.amazonaws.com"

  # Substitua "fiap_gateway_id" pelo ID da sua API Gateway
  source_arn = "${aws_api_gateway_rest_api.default.execution_arn}/*/*/login"
}
